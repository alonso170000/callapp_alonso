import 'package:flutter/foundation.dart';
import 'package:callerapp_frontend/data/local/activities_cache.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/pending_operations_store.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/notification_service.dart';

class OutboxService extends ChangeNotifier {
  OutboxService({
    PendingOperationsStore? store,
    AgendaService? agenda,
    ActivitiesCache? activities,
    AuthService? auth,
  }) : _store = store ?? PendingOperationsStore(),
       _agenda = agenda ?? AgendaService(auth: auth),
       _activities = activities ?? ActivitiesCache(),
       _auth = auth ?? AuthService.instance;
  static final instance = OutboxService();
  final PendingOperationsStore _store;
  final AgendaService _agenda;
  final ActivitiesCache _activities;
  final AuthService _auth;
  bool _syncing = false;
  List<PendingOperation> _operations = const [];
  bool _initialized = false;

  bool get isSyncing => _syncing;
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
        for (final candidate in queue) {
          if (candidate.state == PendingOperationState.conflict) continue;
          final waitingForCreation =
              candidate.entityId != null &&
              candidate.entityId! < 0 &&
              candidate.kind != 'agenda.create' &&
              queue.any(
                (value) =>
                    value.kind == 'agenda.create' &&
                    value.entityId == candidate.entityId,
              );
          if (!waitingForCreation) {
            operation = candidate;
            break;
          }
        }
        if (operation == null) break;
        await _store.markSyncing(operation);
        try {
          await _execute(operation);
          if (operation.kind != 'agenda.create') await _store.remove(operation);
        } on AgendaSessionException {
          await _store.markPending(
            operation,
            'La sesión debe renovarse para sincronizar.',
          );
          break;
        } on AgendaRecoverableException catch (error) {
          await _store.markPending(operation, error.message);
          break;
        } on AgendaBusinessException catch (error) {
          await _store.markConflict(operation, error.message);
          await _restoreRemote(operation);
        }
      }
    } finally {
      _syncing = false;
      await load();
    }
  }

  Future<void> _restoreRemote(PendingOperation operation) async {
    final id = operation.entityId;
    if (id == null) return;
    try {
      if (id < 0) {
        await _activities.remove(operation.scope, id);
        return;
      }
      final remote = await _agenda.fetch();
      final matches = remote.where((activity) => activity.id == id);
      if (matches.isEmpty) {
        await _activities.remove(operation.scope, id);
      } else {
        await _activities.upsert(operation.scope, matches.first);
      }
    } on AgendaException {
      // El conflicto queda visible y el siguiente refresh reintentará restaurar.
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
    }
  }

  Future<void> retry(PendingOperation operation) async {
    if (operation.scope != _scope) return;
    await _store.retryConflict(operation);
    await flush();
  }

  Future<void> discard(PendingOperation operation) async {
    if (operation.scope != _scope) return;
    await _store.remove(operation);
    await load();
  }
}
