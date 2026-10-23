import 'dart:async';

import 'package:callerapp_frontend/data/local/activities_cache.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/pending_operations_store.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/outbox_service.dart';

enum AgendaMutationState { saved, pending }

class AgendaMutationResult {
  const AgendaMutationResult(this.state, {this.activity});
  final AgendaMutationState state;
  final AgendaActivity? activity;
  bool get isPending => state == AgendaMutationState.pending;
}

class AgendaRepository {
  AgendaRepository({
    AgendaService? service,
    ActivitiesCache? cache,
    PendingOperationsStore? outbox,
    AuthService? auth,
  }) : _service = service ?? AgendaService(auth: auth),
       _ownsService = service == null,
       _cache = cache ?? ActivitiesCache(),
       _outbox = outbox ?? PendingOperationsStore(),
       _auth = auth ?? AuthService.instance;
  final AgendaService _service;
  final bool _ownsService;
  final ActivitiesCache _cache;
  final PendingOperationsStore _outbox;
  final AuthService _auth;

  LocalScope get scope {
    final user = _auth.userId, development = _auth.developmentId;
    if (user == null || development == null) {
      throw const AgendaSessionException(
        'La sesión no identifica al usuario o desarrollo activo.',
      );
    }
    return LocalScope(userId: user, developmentId: development);
  }

  Future<List<AgendaActivity>> readCache() => _cache.read(scope);
  Future<List<AgendaActivity>> refresh() async {
    final current = scope;
    final projected = await _project(current, await _service.fetch());
    try {
      await _cache.replace(current, projected);
    } catch (_) {}
    unawaited(OutboxService.instance.flush());
    return projected;
  }

  Future<AgendaMutationResult> create(
    Map<String, dynamic> fields, {
    required AgendaActivity optimisticActivity,
  }) async {
    final current = scope;
    final key = PendingOperationsStore.newOperationKey();
    try {
      final saved = await _service.create(fields, operationKey: key);
      await _cache.upsert(current, saved);
      return AgendaMutationResult(AgendaMutationState.saved, activity: saved);
    } on AgendaRecoverableException {
      if (!_outbox.isAvailable) rethrow;
      final local = optimisticActivity.copyWith(
        id: await _nextTemporaryId(current),
      );
      await _cache.upsert(current, local);
      await _outbox.enqueue(
        current,
        kind: 'agenda.create',
        entityId: local.id,
        operationKey: key,
        payload: {'fields': fields, 'local_activity': _activityJson(local)},
      );
      unawaited(OutboxService.instance.flush());
      return AgendaMutationResult(AgendaMutationState.pending, activity: local);
    }
  }

  Future<AgendaMutationResult> update(
    AgendaActivity activity,
    Map<String, dynamic> fields, {
    required AgendaActivity optimisticActivity,
  }) => _mutate(
    activity,
    kind: 'agenda.update',
    payload: {
      'fields': fields,
      'local_activity': _activityJson(optimisticActivity),
    },
    optimistic: optimisticActivity,
    remote: (id, key) => _service.update(id, fields, operationKey: key),
  );
  Future<AgendaMutationResult> complete(AgendaActivity activity) => _mutate(
    activity,
    kind: 'agenda.complete',
    payload: const {},
    optimistic: activity.copyWith(status: AgendaStatus.completed),
    remote: (id, key) => _service.complete(id, operationKey: key),
  );
  Future<AgendaMutationResult> cancel(AgendaActivity activity) => _mutate(
    activity,
    kind: 'agenda.cancel',
    payload: const {},
    optimistic: activity.copyWith(status: AgendaStatus.cancelled),
    remote: (id, key) => _service.cancel(id, operationKey: key),
  );

  Future<AgendaMutationResult> delete(AgendaActivity activity) async {
    final current = scope;
    var id = activity.id;
    if (id == null) {
      throw const AgendaBusinessException(
        'La actividad no tiene un identificador válido.',
      );
    }
    if (id < 0) {
      // Si la creación ya se sincronizó, la pantalla puede seguir mostrando el
      // id temporal; se resuelve para eliminar la actividad real.
      final resolved = await _outbox.resolveLocalId(current, 'activity', id);
      if (resolved != null && resolved > 0) {
        id = resolved;
      } else {
        for (final item in await _outbox.read(current)) {
          if (item.kind == 'agenda.create' && item.entityId == id) {
            await _outbox.remove(item);
          }
        }
        await _cache.remove(current, id);
        return const AgendaMutationResult(AgendaMutationState.saved);
      }
    }
    final key = PendingOperationsStore.newOperationKey();
    try {
      await _service.delete(id, operationKey: key);
      await _cache.remove(current, id);
      return const AgendaMutationResult(AgendaMutationState.saved);
    } on AgendaRecoverableException {
      if (!_outbox.isAvailable) rethrow;
      await _cache.remove(current, id);
      await _outbox.enqueue(
        current,
        kind: 'agenda.delete',
        entityId: id,
        operationKey: key,
        payload: const {},
      );
      unawaited(OutboxService.instance.flush());
      return const AgendaMutationResult(AgendaMutationState.pending);
    }
  }

  Future<AgendaMutationResult> _mutate(
    AgendaActivity activity, {
    required String kind,
    required Map<String, dynamic> payload,
    required AgendaActivity optimistic,
    required Future<void> Function(int, String) remote,
  }) async {
    final current = scope;
    var id = activity.id;
    if (id == null) {
      throw const AgendaBusinessException(
        'La actividad no tiene un identificador válido.',
      );
    }
    var projected = optimistic;
    var effectivePayload = payload;
    if (id < 0) {
      final resolved = await _outbox.resolveLocalId(current, 'activity', id);
      if (resolved != null && resolved > 0) {
        id = resolved;
        projected = optimistic.copyWith(id: resolved);
        if (effectivePayload['local_activity'] != null) {
          effectivePayload = {
            ...effectivePayload,
            'local_activity': _activityJson(projected),
          };
        }
      }
    }
    final key = PendingOperationsStore.newOperationKey();
    if (id < 0) {
      await _cache.upsert(current, projected);
      await _outbox.enqueue(
        current,
        kind: kind,
        entityId: id,
        operationKey: key,
        payload: effectivePayload,
      );
      unawaited(OutboxService.instance.flush());
      return AgendaMutationResult(
        AgendaMutationState.pending,
        activity: projected,
      );
    }
    try {
      await remote(id, key);
      await _cache.upsert(current, projected);
      return AgendaMutationResult(
        AgendaMutationState.saved,
        activity: projected,
      );
    } on AgendaRecoverableException {
      if (!_outbox.isAvailable) rethrow;
      await _cache.upsert(current, projected);
      await _outbox.enqueue(
        current,
        kind: kind,
        entityId: id,
        operationKey: key,
        payload: effectivePayload,
      );
      unawaited(OutboxService.instance.flush());
      return AgendaMutationResult(
        AgendaMutationState.pending,
        activity: projected,
      );
    }
  }

  Future<List<AgendaActivity>> _project(
    LocalScope current,
    List<AgendaActivity> remote,
  ) async {
    final values = {
      for (final value in remote)
        if (value.id != null) value.id!: value,
    };
    for (final operation in await _outbox.read(
      current,
      includeConflicts: false,
    )) {
      final id = operation.entityId;
      if (operation.kind == 'agenda.create' ||
          operation.kind == 'agenda.update') {
        final raw = operation.payload['local_activity'];
        if (id != null && raw is Map) {
          values[id] = _activityFromJson(Map<String, dynamic>.from(raw));
        }
      } else if (operation.kind == 'agenda.complete' &&
          id != null &&
          values[id] != null) {
        values[id] = values[id]!.copyWith(status: AgendaStatus.completed);
      } else if (operation.kind == 'agenda.cancel' &&
          id != null &&
          values[id] != null) {
        values[id] = values[id]!.copyWith(status: AgendaStatus.cancelled);
      } else if (operation.kind == 'agenda.delete' && id != null) {
        values.remove(id);
      }
    }
    return values.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<int> _nextTemporaryId(LocalScope current) async {
    final ids = (await _cache.read(current))
        .map((value) => value.id ?? 0)
        .where((id) => id < 0);
    return ids.isEmpty ? -1 : ids.reduce((a, b) => a < b ? a : b) - 1;
  }

  static Map<String, dynamic> _activityJson(AgendaActivity value) => {
    'id': value.id,
    'prospect_id': value.prospectId,
    'type': value.type,
    'medium': value.medium,
    'title': value.title,
    'prospect': value.prospect,
    'description': value.description,
    'date_ms': value.date.millisecondsSinceEpoch,
    'status': value.status.name,
    'tags': value.tags,
    'location': value.location,
    'reminder_minutes': value.reminderMinutes,
    'has_reminder': value.hasReminder,
  };
  static AgendaActivity _activityFromJson(Map<String, dynamic> value) =>
      AgendaActivity(
        id: value['id'] as int?,
        prospectId: value['prospect_id'] as int?,
        type: value['type'] as String?,
        medium: value['medium'] as String?,
        title: value['title'] as String,
        prospect: value['prospect'] as String,
        description: value['description'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(value['date_ms'] as int),
        status: AgendaStatus.values.byName(value['status'] as String),
        tags: List<String>.from(value['tags'] as List),
        location: value['location'] as String,
        reminderMinutes: value['reminder_minutes'] as int,
        hasReminder: value['has_reminder'] as bool,
      );
  void dispose() {
    if (_ownsService) _service.dispose();
  }
}
