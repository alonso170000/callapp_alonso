import 'dart:async';

import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/catalog_cache.dart';
import 'package:callerapp_frontend/data/local/discovery_cache.dart';
import 'package:callerapp_frontend/data/local/pending_operations_store.dart';
import 'package:callerapp_frontend/data/local/prospects_cache.dart';
import 'package:callerapp_frontend/data/mappers/prospect_cache_mapper.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_catalog_models.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/notification_service.dart';
import 'package:callerapp_frontend/services/outbox_service.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';

enum ProspectMutationState { saved, pending }

class ProspectMutationResult {
  const ProspectMutationResult(this.state, {this.prospect});
  final ProspectMutationState state;
  final ProspectRecord? prospect;
  bool get isPending => state == ProspectMutationState.pending;
}

class ProspectsRepository {
  ProspectsRepository({
    ProspectsService? service,
    ProspectsCache? cache,
    DiscoveryCache? discoveries,
    PendingOperationsStore? outbox,
    OutboxService? sync,
    CatalogCache? catalogs,
    AuthService? auth,
  }) : _service = service ?? ProspectsService(auth: auth),
       _ownsService = service == null,
       _cache = cache ?? ProspectsCache(),
       _discoveries = discoveries ?? DiscoveryCache(),
       _outbox = outbox ?? PendingOperationsStore(),
       _sync = sync ?? OutboxService.instance,
       _catalogs = catalogs ?? CatalogCache(),
       _auth = auth ?? AuthService.instance;

  final ProspectsService _service;
  final bool _ownsService;
  final ProspectsCache _cache;
  final DiscoveryCache _discoveries;
  final PendingOperationsStore _outbox;
  final OutboxService _sync;
  final CatalogCache _catalogs;
  final AuthService _auth;

  LocalScope get scope {
    final userId = _auth.userId ?? _service.userId;
    final developmentId = _auth.developmentId ?? _service.developmentId;
    if (userId == null || developmentId == null) {
      throw const ProspectsSessionException(
        'La sesión no identifica al usuario o desarrollo activo.',
      );
    }
    return LocalScope(userId: userId, developmentId: developmentId);
  }

  Future<List<ProspectRecord>> readCache() => _cache.read(scope);

  Future<List<ProspectRecord>> refresh() async {
    final currentScope = scope;
    final previous = await _cachedOrEmpty(currentScope);
    final projected = await _project(currentScope, await _service.fetch());
    try {
      await _cache.replace(currentScope, projected);
    } catch (_) {}
    try {
      final visible = newlyVisibleIds(previous, projected);
      final locallyCreated = await _outbox.consumeLocallyCreated(
        currentScope,
        visible,
      );
      await NotificationService.instance.syncAssignedProspects(
        projected.where((prospect) => (prospect.id ?? 0) > 0).toList(),
        userId: currentScope.userId,
        developmentId: currentScope.developmentId,
        newlyVisibleProspectIds: assignableNewIds(
          previous,
          projected,
          locallyCreated,
        ),
        baseline: assignmentBaseline(previous),
      );
    } catch (_) {}
    unawaited(_sync.flush());
    unawaited(warmCatalogs());
    return projected;
  }

  Future<ProspectCatalogs> loadCatalogs() async {
    final currentScope = scope;
    final lotsName = 'lotes:${currentScope.developmentId}';
    final cached = await Future.wait([
      _catalogs.read(currentScope, 'canales'),
      _catalogs.read(currentScope, 'estatus-prospecto'),
      _catalogs.read(currentScope, lotsName),
    ]);

    final remote = await Future.wait([
      _fetchCatalog(() => _service.catalog('canales')),
      _fetchCatalog(() => _service.catalog('estatus-prospecto')),
      _fetchCatalog(_service.availableLots),
    ]);
    final origins = remote[0].rows;
    final statuses = remote[1].rows;
    final lots = remote[2].rows;
    final originsError = remote[0].error;

    final resolvedOrigins = _preferRemote(origins, cached[0]);
    final resolvedStatuses = _preferRemote(statuses, cached[1]);
    final resolvedLots = _preferRemote(lots, cached[2]);
    if (origins?.isNotEmpty == true) {
      await _catalogs.write(currentScope, 'canales', origins!);
    }
    if (statuses?.isNotEmpty == true) {
      await _catalogs.write(currentScope, 'estatus-prospecto', statuses!);
    }
    if (lots?.isNotEmpty == true) {
      await _catalogs.write(currentScope, lotsName, lots!);
    }
    if (resolvedOrigins.isEmpty) {
      throw originsError ??
          const ProspectsBusinessException(
            'No hay orígenes disponibles para registrar el prospecto.',
          );
    }
    return ProspectCatalogs(
      origins: resolvedOrigins,
      statuses: resolvedStatuses,
      lots: resolvedLots,
    );
  }

  Future<List<Map<String, dynamic>>> loadDevelopments() => _loadCatalogList(
    name: 'desarrollos',
    remote: _service.availableDevelopments,
  );

  Future<List<Map<String, dynamic>>> loadLots(int developmentId) =>
      _loadCatalogList(
        name: 'lotes:$developmentId',
        remote: () => _service.availableLots(developmentId),
      );

  Future<List<Map<String, dynamic>>> _loadCatalogList({
    required String name,
    required Future<List<Map<String, dynamic>>> Function() remote,
  }) async {
    final currentScope = scope;
    final cached = await _catalogs.read(currentScope, name);
    try {
      final rows = await remote();
      if (rows.isNotEmpty) await _catalogs.write(currentScope, name, rows);
      return rows.isNotEmpty ? rows : (cached ?? rows);
    } on ProspectsException {
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Descarga cada catálogo sin que el fallo de uno cancele a los demás.
  Future<({List<Map<String, dynamic>>? rows, ProspectsException? error})>
  _fetchCatalog(Future<List<Map<String, dynamic>>> Function() load) async {
    try {
      return (rows: await load(), error: null);
    } on ProspectsException catch (error) {
      return (rows: null, error: error);
    }
  }

  Future<void> warmCatalogs() async {
    try {
      final currentScope = scope;
      if (!await _catalogs.isWarmDue(currentScope)) return;
      await _catalogs.markWarmAttempt(currentScope);
      final lotsName = 'lotes:${currentScope.developmentId}';
      if (await _catalogs.read(currentScope, 'canales') == null ||
          await _catalogs.read(currentScope, 'estatus-prospecto') == null ||
          await _catalogs.read(currentScope, lotsName) == null) {
        await loadCatalogs();
      }
      if (await _catalogs.read(currentScope, 'desarrollos') == null) {
        await loadDevelopments();
      }
    } on Object {
      // La precarga es oportunista y no cambia el resultado del refresh.
    }
  }

  static List<Map<String, dynamic>> _preferRemote(
    List<Map<String, dynamic>>? remote,
    List<Map<String, dynamic>>? cached,
  ) => remote?.isNotEmpty == true ? remote! : (cached ?? const []);

  /// Ids que deben generar un aviso de asignación: nuevos para la caché y que
  /// no provengan de una creación hecha por el propio usuario sin conexión.
  static Set<int> assignableNewIds(
    List<ProspectRecord> previous,
    List<ProspectRecord> current,
    Set<int> locallyCreated,
  ) => newlyVisibleIds(previous, current).difference(locallyCreated);

  Future<ProspectMutationResult> create(
    Map<String, dynamic> fields, {
    required ProspectRecord optimisticProspect,
  }) async {
    final currentScope = scope;
    final key = PendingOperationsStore.newOperationKey();
    try {
      final id = await _service.create(fields, operationKey: key);
      final saved = optimisticProspect.copyWith(id: id);
      await _cache.upsert(currentScope, saved);
      return ProspectMutationResult(
        ProspectMutationState.saved,
        prospect: saved,
      );
    } on ProspectsRecoverableException {
      if (!_outbox.isAvailable) rethrow;
      final local = optimisticProspect.copyWith(
        id: await _nextTemporaryId(currentScope),
      );
      await _cache.upsert(currentScope, local);
      await _outbox.enqueue(
        currentScope,
        kind: 'prospect.create',
        entityId: local.id,
        operationKey: key,
        payload: {'fields': fields, 'local_prospect': _prospectJson(local)},
      );
      unawaited(_sync.flush());
      return ProspectMutationResult(
        ProspectMutationState.pending,
        prospect: local,
      );
    }
  }

  Future<ProspectMutationResult> update(
    ProspectRecord prospect,
    Map<String, dynamic> fields, {
    required ProspectRecord optimisticProspect,
  }) => _mutate(
    prospect,
    kind: 'prospect.update',
    fields: fields,
    optimistic: optimisticProspect,
    remote: (id, key) => _service.update(id, fields, operationKey: key),
  );

  Future<ProspectMutationResult> createFollowUp(
    ProspectRecord prospect,
    Map<String, dynamic> fields, {
    String? operationKey,
  }) {
    final priority = switch (fields['prioridad']) {
      'caliente' => 'Caliente',
      'tibio' => 'Tibio',
      'frio' => 'Frío',
      _ => prospect.temperature,
    };
    final isTelephone = fields['medio'] == 'telefono';
    final optimistic = prospect.copyWith(
      status: fields['estatus'] as String? ?? prospect.status,
      temperature: priority,
      lastContactResult: fields['hubo_exito'] == true
          ? 'Contacto exitoso'
          : 'Sin respuesta',
      lastCallAt: isTelephone ? businessNow() : null,
      lastCallStatus: isTelephone
          ? (fields['hubo_exito'] == true ? 'Contestada' : 'No contestada')
          : null,
      daysSinceContact: isTelephone ? 0 : null,
    );
    return _mutate(
      prospect,
      kind: 'prospect.follow_up',
      fields: fields,
      optimistic: optimistic,
      operationKey: operationKey,
      remote: (id, key) =>
          _service.createFollowUp(id, fields, operationKey: key),
    );
  }

  Future<ProspectMutationResult> saveDiscoverySection(
    ProspectRecord prospect,
    Map<String, dynamic> fields,
  ) async {
    final result = await _mutate(
      prospect,
      kind: 'prospect.discovery',
      fields: fields,
      optimistic: prospect,
      remote: (id, key) =>
          _service.saveDiscoverySection(id, fields, operationKey: key),
    );
    final id = result.prospect?.id;
    if (id != null && id > 0) await rememberDiscovery(id, fields);
    return result;
  }

  /// Devuelve el discovery del prospecto priorizando la red, cayendo a la caché
  /// local cuando no hay conexión y superponiendo las secciones que aún están
  /// pendientes de sincronizar.
  Future<Map<String, dynamic>?> loadDiscovery(int prospectId) async {
    final currentScope = scope;
    final cached = await _discoveries.read(currentScope, prospectId);
    Map<String, dynamic>? remote;
    try {
      remote = await _service.discovery(prospectId);
    } on ProspectsRecoverableException {
      if (cached == null) rethrow;
    }
    final merged = <String, dynamic>{...?cached, ...?remote};
    for (final operation in await _outbox.read(
      currentScope,
      includeConflicts: false,
    )) {
      if (operation.kind != 'prospect.discovery') continue;
      if (operation.entityId != prospectId) continue;
      final fields = operation.payload['fields'];
      if (fields is Map) {
        merged.addAll(Map<String, dynamic>.from(fields)..remove('seccion'));
      }
    }
    if (remote?.isNotEmpty == true) {
      await _discoveries.write(currentScope, prospectId, merged);
    }
    return merged.isEmpty ? remote : merged;
  }

  /// Guarda localmente los campos de una sección de discovery para que sigan
  /// visibles sin conexión, aunque la operación todavía esté pendiente.
  Future<void> rememberDiscovery(int prospectId, Map<String, dynamic> fields) {
    final payload = Map<String, dynamic>.from(fields)..remove('seccion');
    return _discoveries.merge(scope, prospectId, payload);
  }

  Future<ProspectMutationResult> _mutate(
    ProspectRecord prospect, {
    required String kind,
    required Map<String, dynamic> fields,
    required ProspectRecord optimistic,
    required Future<void> Function(int id, String key) remote,
    String? operationKey,
  }) async {
    final currentScope = scope;
    var id = prospect.id;
    if (id == null) {
      throw const ProspectsBusinessException(
        'El prospecto no tiene un identificador válido.',
      );
    }
    var projected = optimistic;
    if (id < 0) {
      // La pantalla todavía puede tener el id temporal de una creación que ya
      // se sincronizó; se resuelve al id real para no perder la edición.
      final resolved = await _outbox.resolveLocalId(
        currentScope,
        'prospect',
        id,
      );
      if (resolved != null && resolved > 0) {
        id = resolved;
        projected = optimistic.copyWith(id: resolved);
      }
    }
    final key = operationKey ?? PendingOperationsStore.newOperationKey();
    if (id < 0) {
      await _cache.upsert(currentScope, projected);
      await _outbox.enqueue(
        currentScope,
        kind: kind,
        entityId: id,
        operationKey: key,
        payload: {'fields': fields, 'local_prospect': _prospectJson(projected)},
      );
      unawaited(_sync.flush());
      return ProspectMutationResult(
        ProspectMutationState.pending,
        prospect: projected,
      );
    }
    try {
      await remote(id, key);
      await _cache.upsert(currentScope, projected);
      return ProspectMutationResult(
        ProspectMutationState.saved,
        prospect: projected,
      );
    } on ProspectsRecoverableException {
      if (!_outbox.isAvailable) rethrow;
      await _cache.upsert(currentScope, projected);
      await _outbox.enqueue(
        currentScope,
        kind: kind,
        entityId: id,
        operationKey: key,
        payload: {'fields': fields, 'local_prospect': _prospectJson(projected)},
      );
      unawaited(_sync.flush());
      return ProspectMutationResult(
        ProspectMutationState.pending,
        prospect: projected,
      );
    }
  }

  Future<List<ProspectRecord>> _project(
    LocalScope currentScope,
    List<ProspectRecord> remote,
  ) async {
    final values = {
      for (final prospect in remote)
        if (prospect.id != null) prospect.id!: prospect,
    };
    for (final operation in await _outbox.read(
      currentScope,
      includeConflicts: false,
    )) {
      if (operation.kind != 'prospect.create' &&
          operation.kind != 'prospect.update' &&
          operation.kind != 'prospect.follow_up') {
        continue;
      }
      final raw = operation.payload['local_prospect'];
      if (operation.entityId != null && raw is Map) {
        values[operation.entityId!] = _prospectFromJson(
          Map<String, dynamic>.from(raw),
        );
      }
    }
    return values.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<List<ProspectRecord>> _cachedOrEmpty(LocalScope currentScope) async {
    try {
      return await _cache.read(currentScope);
    } catch (_) {
      return const [];
    }
  }

  Future<int> _nextTemporaryId(LocalScope currentScope) async {
    final ids = (await _cache.read(currentScope))
        .map((prospect) => prospect.id ?? 0)
        .where((id) => id < 0);
    return ids.isEmpty ? -1 : ids.reduce((a, b) => a < b ? a : b) - 1;
  }

  static Map<String, dynamic> _prospectJson(ProspectRecord prospect) =>
      Map<String, dynamic>.from(
        ProspectCacheMapper.toRow(prospect, userId: 0, developmentId: 0),
      );

  static ProspectRecord _prospectFromJson(Map<String, dynamic> value) =>
      ProspectCacheMapper.fromRow(Map<String, Object?>.from(value));

  static Set<int> newlyVisibleIds(
    List<ProspectRecord> previous,
    List<ProspectRecord> current,
  ) {
    final knownIds = previous
        .map((prospect) => prospect.id)
        .whereType<int>()
        .where((id) => id > 0)
        .toSet();
    return current
        .map((prospect) => prospect.id)
        .whereType<int>()
        .where((id) => id > 0 && !knownIds.contains(id))
        .toSet();
  }

  static DateTime? assignmentBaseline(List<ProspectRecord> previous) {
    final persisted = previous.where((prospect) => (prospect.id ?? 0) > 0);
    if (persisted.isEmpty) return null;
    DateTime? latest;
    for (final prospect in persisted) {
      final assignedAt = prospect.assignedAt;
      if (assignedAt != null &&
          (latest == null || assignedAt.isAfter(latest))) {
        latest = assignedAt;
      }
    }
    return latest ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  void dispose() {
    if (_ownsService) _service.dispose();
  }
}
