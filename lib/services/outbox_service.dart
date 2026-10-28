import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:callerapp_frontend/data/local/activities_cache.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/pending_operations_store.dart';
import 'package:callerapp_frontend/data/local/prospects_cache.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/notification_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';

class OutboxService extends ChangeNotifier {
  OutboxService({
    PendingOperationsStore? store,
    AgendaService? agenda,
    ActivitiesCache? activities,
    ProspectsService? prospects,
    ProspectsCache? prospectsCache,
    AuthService? auth,
  }) : _store = store ?? PendingOperationsStore(),
       _agenda = agenda ?? AgendaService(auth: auth),
       _activities = activities ?? ActivitiesCache(),
       _prospects = prospects ?? ProspectsService(auth: auth),
       _prospectsCache = prospectsCache ?? ProspectsCache(),
       _auth = auth ?? AuthService.instance;
  static final instance = OutboxService();
  final PendingOperationsStore _store;
  final AgendaService _agenda;
  final ActivitiesCache _activities;
  final ProspectsService _prospects;
  final ProspectsCache _prospectsCache;
  final AuthService _auth;
  bool _syncing = false;

  bool _isProspectOperation(PendingOperation operation) =>
      operation.kind.startsWith('prospect.') || operation.kind == 'call.audio';
  List<PendingOperation> _operations = const [];
  bool _initialized = false;
  int _revision = 0;

  /// Tras estos fallos de servidor, la operación deja de reintentarse sola y
  /// pasa a conflicto para que el usuario decida.
  static const _maxAutoAttempts = 5;

  /// Cada cuánto se reintenta sincronizar mientras la app está abierta y hay
  /// operaciones pendientes. Sin paquete de conectividad, es la forma de que la
  /// cola se vacíe sola al volver la red.
  static const autoSyncInterval = Duration(seconds: 90);

  Timer? _autoSyncTimer;

  bool get isSyncing => _syncing;

  /// Aumenta cada vez que se procesa una operación pendiente. Permite a las
  /// pantallas distinguir una sincronización real de un vaciado sin trabajo.
  int get revision => _revision;
  int get pendingCount => _operations
      .where((value) => value.state != PendingOperationState.conflict)
      .length;
  int get conflictCount => _operations
      .where((value) => value.state == PendingOperationState.conflict)
      .length;
  List<PendingOperation> get operations => List.unmodifiable(_operations);
  LocalScope? get _scope {
    final user = _auth.userId, development = _auth.developmentId;
    return user == null || development == null
        ? null
        : LocalScope(userId: user, developmentId: development);
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _auth.addListener(_sessionChanged);
    await load();
    await flush();
    _autoSyncTimer ??= Timer.periodic(
      autoSyncInterval,
      (_) => unawaited(maybeAutoSync()),
    );
  }

  /// Reintenta el vaciado si hay pendientes y no hay conflictos. Es lo que llama
  /// el temporizador para vaciar la cola sola al recuperar la conexión, sin
  /// esperar a que el usuario haga una acción.
  Future<void> maybeAutoSync() async {
    if (_syncing || _operations.isEmpty || pendingCount == 0) return;
    await flush();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    super.dispose();
  }

  void _sessionChanged() {
    load().then((_) => flush());
  }

  Future<void> load() async {
    final current = _scope;
    _operations = current == null ? const [] : await _store.read(current);
    notifyListeners();
  }

  Future<void> flush() async {
    final current = _scope;
    if (_syncing || current == null || !_store.isAvailable) return;
    _syncing = true;
    notifyListeners();
    try {
      await _store.recoverInterrupted(current);
      while (true) {
        final queue = await _store.read(current);
        PendingOperation? operation;
        var orphan = false;
        for (final candidate in queue) {
          if (candidate.state == PendingOperationState.conflict) continue;
          final references = _temporaryReferences(candidate);
          if (references.isEmpty) {
            operation = candidate;
            break;
          }
          final waitingForCreation = references.any(
            (temporaryId) => queue.any(
              (value) =>
                  (value.kind == 'agenda.create' ||
                      value.kind == 'prospect.create') &&
                  value.state != PendingOperationState.conflict &&
                  value.entityId == temporaryId,
            ),
          );
          if (waitingForCreation) continue;
          operation = candidate;
          orphan = true;
          break;
        }
        if (operation == null) break;
        if (orphan) {
          _revision++;
          await _store.markConflict(
            operation,
            'El registro local del que depende no se pudo crear.',
          );
          continue;
        }
        _revision++;
        await _store.markSyncing(operation);
        try {
          await _execute(operation);
          if (operation.kind != 'agenda.create' &&
              operation.kind != 'prospect.create') {
            await _store.remove(operation);
          }
        } on AgendaSessionException {
          await _store.markPending(
            operation,
            'La sesión debe renovarse para sincronizar.',
          );
          break;
        } on AgendaOfflineException catch (error) {
          await _store.markPendingOffline(operation, error.message);
          break;
        } on AgendaRecoverableException catch (error) {
          await _pauseRetries(operation, error.message);
          break;
        } on AgendaBusinessException catch (error) {
          await _store.markConflict(operation, error.message);
          await _restoreRemote(operation);
        } on ProspectsSessionException {
          await _store.markPending(
            operation,
            'La sesión debe renovarse para sincronizar.',
          );
          break;
        } on ProspectsOfflineException catch (error) {
          await _store.markPendingOffline(operation, error.message);
          break;
        } on ProspectsRecoverableException catch (error) {
          await _pauseRetries(operation, error.message);
          break;
        } on ProspectsBusinessException catch (error) {
          await _store.markConflict(operation, error.message);
          await _restoreRemote(operation);
        } on AgendaException catch (error) {
          await _store.markConflict(operation, error.message);
          await _restoreRemote(operation);
        } on ProspectsException catch (error) {
          await _store.markConflict(operation, error.message);
          await _restoreRemote(operation);
        } catch (_) {
          await _store.markPending(
            operation,
            'No se pudo sincronizar este cambio.',
          );
          break;
        }
      }
    } finally {
      _syncing = false;
      await load();
    }
  }

  /// Tras [operation] deja la operación pendiente o, si ya agotó el presupuesto
  /// de reintentos, la marca como conflicto para que el usuario decida. Los
  /// fallos por falta de conexión no llegan aquí porque no consumen intentos.
  Future<void> _pauseRetries(PendingOperation operation, String message) async {
    final attempt = operation.attemptCount + 1;
    if (attempt >= _maxAutoAttempts) {
      await _store.markConflict(
        operation,
        'Se pausaron los reintentos automáticos tras $_maxAutoAttempts intentos. $message',
      );
      return;
    }
    await _store.markPending(operation, message);
  }

  /// Ids temporales (negativos) a los que apunta la operación. Solo se miran
  /// claves que representan identificadores para no confundir valores de
  /// negocio con ids locales.
  Set<int> _temporaryReferences(PendingOperation operation) {
    final result = <int>{};
    bool isIdKey(String? key) =>
        key == null || key == 'id' || key.endsWith('_id');

    void collect(dynamic value, [String? key]) {
      if (value is int && value < 0 && isIdKey(key)) {
        result.add(value);
        return;
      }
      if (value is List) {
        for (final item in value) {
          collect(item, key);
        }
      } else if (value is Map) {
        for (final entry in value.entries) {
          collect(entry.value, '${entry.key}');
        }
      }
    }

    collect(operation.payload);
    if (operation.entityId case final id? when id < 0) result.add(id);
    if (operation.kind == 'agenda.create' ||
        operation.kind == 'prospect.create') {
      result.remove(operation.entityId);
    }
    return result;
  }

  Future<bool> _restoreRemote(PendingOperation operation) async {
    if (operation.kind == 'call.audio') {
      return true;
    }
    final id = operation.entityId;
    if (id == null) return false;
    try {
      if (id < 0) {
        if (operation.kind.startsWith('prospect.')) {
          await _prospectsCache.remove(operation.scope, id);
        } else {
          await _activities.remove(operation.scope, id);
        }
        return true;
      }
      if (operation.kind.startsWith('prospect.')) {
        final remote = await _prospects.fetch();
        final matches = remote.where((prospect) => prospect.id == id);
        if (matches.isEmpty) {
          await _prospectsCache.remove(operation.scope, id);
        } else {
          await _prospectsCache.upsert(operation.scope, matches.first);
        }
      } else {
        final remote = await _agenda.fetch();
        final matches = remote.where((activity) => activity.id == id);
        if (matches.isEmpty) {
          await _activities.remove(operation.scope, id);
        } else {
          await _activities.upsert(operation.scope, matches.first);
        }
      }
      return true;
    } on AgendaException {
      // El conflicto queda visible y el siguiente refresh reintentará restaurar.
      return false;
    } on ProspectsException {
      return false;
    }
  }

  Future<void> _execute(PendingOperation operation) async {
    final id = operation.entityId;
    switch (operation.kind) {
      case 'agenda.create':
        final saved = await _agenda.create(
          Map<String, dynamic>.from(operation.payload['fields'] as Map),
          operationKey: operation.operationKey,
        );
        await _store.remapActivityId(
          operation,
          temporaryId: id!,
          serverId: saved.id!,
        );
        await NotificationService.instance.syncActivities(
          await _activities.read(operation.scope),
          userId: operation.scope.userId,
          developmentId: operation.scope.developmentId,
        );
      case 'agenda.update':
        await _agenda.update(
          id!,
          Map<String, dynamic>.from(operation.payload['fields'] as Map),
          operationKey: operation.operationKey,
        );
      case 'agenda.complete':
        await _agenda.complete(id!, operationKey: operation.operationKey);
      case 'agenda.cancel':
        await _agenda.cancel(id!, operationKey: operation.operationKey);
      case 'agenda.delete':
        await _agenda.delete(id!, operationKey: operation.operationKey);
      case 'prospect.create':
        final serverId = await _prospects.create(
          Map<String, dynamic>.from(operation.payload['fields'] as Map),
          operationKey: operation.operationKey,
        );
        await _store.remapProspectId(
          operation,
          temporaryId: id!,
          serverId: serverId,
        );
      case 'prospect.update':
        await _prospects.update(
          id!,
          Map<String, dynamic>.from(operation.payload['fields'] as Map),
          operationKey: operation.operationKey,
        );
      case 'prospect.follow_up':
        await _prospects.createFollowUp(
          id!,
          Map<String, dynamic>.from(operation.payload['fields'] as Map),
          operationKey: operation.operationKey,
        );
      case 'prospect.call':
        final callId = await _prospects.createCall(
          id!,
          Map<String, dynamic>.from(operation.payload['fields'] as Map),
          operationKey: operation.operationKey,
        );
        final audioPath = operation.payload['audio_path'];
        if (audioPath is String && audioPath.isNotEmpty) {
          await _store.enqueue(
            operation.scope,
            kind: 'call.audio',
            entityId: callId,
            payload: {'audio_path': audioPath},
          );
        }
      case 'call.audio':
        final audioPath = operation.payload['audio_path'];
        if (audioPath is! String || audioPath.isEmpty) {
          throw const ProspectsBusinessException(
            'La grabación pendiente no tiene un archivo válido.',
          );
        }
        await _prospects.uploadCallAudio(id!, audioPath);
        final file = File(audioPath);
        if (await file.exists()) await file.delete();
      case 'prospect.discovery':
        await _prospects.saveDiscoverySection(
          id!,
          Map<String, dynamic>.from(operation.payload['fields'] as Map),
          operationKey: operation.operationKey,
        );
    }
  }

  Future<void> retry(PendingOperation operation) async {
    if (operation.scope != _scope) return;
    await _store.retryConflict(operation);
    await flush();
    final unresolved = _operations.where(
      (value) =>
          value.id == operation.id &&
          value.state == PendingOperationState.conflict,
    );
    if (unresolved.isNotEmpty) {
      final message =
          unresolved.first.lastError ??
          'El servidor volvió a rechazar el cambio.';
      throw _isProspectOperation(operation)
          ? ProspectsBusinessException(message)
          : AgendaBusinessException(message);
    }
  }

  Future<void> discard(PendingOperation operation) async {
    if (operation.scope != _scope) return;
    if (operation.kind == 'call.audio') {
      final audioPath = operation.payload['audio_path'];
      if (audioPath is String && audioPath.isNotEmpty) {
        final file = File(audioPath);
        if (await file.exists()) await file.delete();
      }
      await _store.remove(operation);
      await load();
      return;
    }
    final restored = await _restoreRemote(operation);
    if (!restored) {
      const message =
          'No se pudo recuperar la versión del servidor. Intenta nuevamente.';
      throw _isProspectOperation(operation)
          ? const ProspectsRecoverableException(message)
          : const AgendaRecoverableException(message);
    }
    await _store.remove(operation);
    await load();
  }
}
