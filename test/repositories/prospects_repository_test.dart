import 'dart:convert';

import 'package:callerapp_frontend/data/local/activities_cache.dart';
import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/catalog_cache.dart';
import 'package:callerapp_frontend/data/local/discovery_cache.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/pending_operations_store.dart';
import 'package:callerapp_frontend/data/local/prospects_cache.dart';
import 'package:callerapp_frontend/data/mappers/prospect_cache_mapper.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/outbox_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('guarda la respuesta remota dentro del ámbito autenticado', () async {
    final auth = await _auth(userId: 4, developmentId: 8);
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final cache = ProspectsCache(database: database);
    final repository = ProspectsRepository(
      auth: auth,
      cache: cache,
      service: _FakeProspectsService(() async => [_prospect(15, 'Ana')]),
    );

    expect((await repository.refresh()).single.name, 'Ana');
    expect((await repository.readCache()).single.id, 15);
  });

  test('detecta los prospectos que no estaban en la caché anterior', () {
    final newIds = ProspectsRepository.newlyVisibleIds(
      [_prospect(1, 'Ana'), _prospect(2, 'Luis')],
      [_prospect(2, 'Luis'), _prospect(3, 'Marta')],
    );

    expect(newIds, {3});
  });

  test('la línea base usa la asignación más reciente de la caché', () {
    final newest = DateTime(2026, 10, 18, 9);
    expect(
      ProspectsRepository.assignmentBaseline([
        _prospect(1, 'Ana', assignedAt: DateTime(2026, 10, 15)),
        _prospect(2, 'Luis', assignedAt: newest),
      ]),
      newest,
    );
  });

  test('sin caché previa no hay línea base y el chequeo es silencioso', () {
    expect(ProspectsRepository.assignmentBaseline(const []), isNull);
    expect(
      ProspectsRepository.assignmentBaseline([_prospect(1, 'Ana')]),
      DateTime.fromMillisecondsSinceEpoch(0),
    );
  });

  test('un error remoto no elimina la última caché válida', () async {
    final auth = await _auth(userId: 5, developmentId: 9);
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final cache = ProspectsCache(database: database);
    const scope = LocalScope(userId: 5, developmentId: 9);
    await cache.replace(scope, [_prospect(21, 'Guardado')]);
    final repository = ProspectsRepository(
      auth: auth,
      cache: cache,
      service: _FakeProspectsService(
        () async => throw const ProspectsException('Sin conexión'),
      ),
    );

    await expectLater(repository.refresh(), throwsA(isA<ProspectsException>()));
    expect((await repository.readCache()).single.name, 'Guardado');
  });

  test('no anuncia como asignado un prospecto creado sin conexión', () {
    expect(
      ProspectsRepository.assignableNewIds(
        [_prospect(1, 'Ana')],
        [_prospect(1, 'Ana'), _prospect(100, 'Propio')],
        {100},
      ),
      isEmpty,
    );
    expect(
      ProspectsRepository.assignableNewIds(
        [_prospect(1, 'Ana')],
        [
          _prospect(1, 'Ana'),
          _prospect(100, 'Propio'),
          _prospect(101, 'Ajeno'),
        ],
        {100},
      ),
      {101},
    );
  });

  test('proyecta las mutaciones pendientes sobre el snapshot remoto', () async {
    final auth = await _auth(userId: 4, developmentId: 8);
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final cache = ProspectsCache(database: database);
    final store = PendingOperationsStore(database: database);
    const scope = LocalScope(userId: 4, developmentId: 8);
    final created = _prospect(-1, 'Creado sin conexión');
    final remote = _prospect(15, 'Nombre remoto');
    final edited = remote.copyWith(name: 'Nombre local');
    await store.enqueue(
      scope,
      kind: 'prospect.create',
      entityId: -1,
      operationKey: 'create',
      payload: {'local_prospect': _row(created)},
    );
    await store.enqueue(
      scope,
      kind: 'prospect.update',
      entityId: 15,
      operationKey: 'update',
      payload: {'local_prospect': _row(edited)},
    );
    final repository = ProspectsRepository(
      auth: auth,
      cache: cache,
      outbox: store,
      service: _FakeProspectsService(
        () async => [remote, _prospect(30, 'Otro')],
      ),
    );

    final projected = await repository.refresh();

    expect(projected.map((prospect) => prospect.id), containsAll([-1, 15, 30]));
    expect(
      projected.firstWhere((prospect) => prospect.id == 15).name,
      'Nombre local',
    );
    expect(
      projected.firstWhere((prospect) => prospect.id == -1).name,
      'Creado sin conexión',
    );
  });

  test(
    'crear sin conexión encola y el reintento remapea el id temporal',
    () async {
      final auth = await _auth(userId: 4, developmentId: 8);
      final database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(database.close);
      final cache = ProspectsCache(database: database);
      final store = PendingOperationsStore(database: database);
      const scope = LocalScope(userId: 4, developmentId: 8);
      final remote = _RecordingProspectsService();
      final sync = OutboxService(
        store: store,
        prospects: remote,
        prospectsCache: cache,
        activities: ActivitiesCache(database: database),
        auth: auth,
      );
      final repository = ProspectsRepository(
        auth: auth,
        cache: cache,
        outbox: store,
        sync: sync,
        service: _FailingCreateService(),
      );

      final result = await repository.create(const {
        'nombre': 'Local',
      }, optimisticProspect: _prospect(0, 'Local'));

      expect(result.isPending, isTrue);
      expect(result.prospect?.id, -1);
      final pending = (await store.read(scope)).single;
      expect(pending.kind, 'prospect.create');
      expect(pending.entityId, -1);

      // El encolado dispara el drenado automático en segundo plano.
      while (sync.isSyncing) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }

      expect(remote.calls, ['create:${pending.operationKey}']);
      expect(await store.read(scope), isEmpty);
      expect((await cache.read(scope)).single.id, 120);
    },
  );

  test('catálogos remotos se guardan y luego resuelven una caída', () async {
    final auth = await _auth(userId: 7, developmentId: 12);
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final catalogs = CatalogCache(database: database);
    final online = ProspectsRepository(
      auth: auth,
      catalogs: catalogs,
      service: _CatalogProspectsService(),
    );

    final downloaded = await online.loadCatalogs();
    expect(downloaded.origins.single['id'], 9);

    final offline = ProspectsRepository(
      auth: auth,
      catalogs: catalogs,
      service: _CatalogProspectsService(failOrigins: true),
    );
    expect((await offline.loadCatalogs()).origins.single['id'], 9);
  });

  test('sin red ni caché de canales relanza el error original', () async {
    final auth = await _auth(userId: 7, developmentId: 12);
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final repository = ProspectsRepository(
      auth: auth,
      catalogs: CatalogCache(database: database),
      service: _CatalogProspectsService(failOrigins: true),
    );

    await expectLater(
      repository.loadCatalogs(),
      throwsA(
        isA<ProspectsRecoverableException>().having(
          (error) => error.message,
          'mensaje',
          'Sin conexión a canales',
        ),
      ),
    );
  });

  test('fallos de estatus y lotes no bloquean los canales', () async {
    final auth = await _auth(userId: 7, developmentId: 12);
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final repository = ProspectsRepository(
      auth: auth,
      catalogs: CatalogCache(database: database),
      service: _CatalogProspectsService(failStatuses: true, failLots: true),
    );

    final result = await repository.loadCatalogs();
    expect(result.origins, isNotEmpty);
    expect(result.statuses, isEmpty);
    expect(result.lots, isEmpty);
  });

  test('warmCatalogs precarga los catálogos una sola vez', () async {
    final auth = await _auth(userId: 7, developmentId: 12);
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    const scope = LocalScope(userId: 7, developmentId: 12);
    final catalogs = CatalogCache(database: database);
    final service = _CatalogProspectsService();
    final repository = ProspectsRepository(
      auth: auth,
      catalogs: catalogs,
      service: service,
    );

    await repository.warmCatalogs();
    expect(service.catalogCalls, 2);
    expect(service.lotsCalls, 1);
    expect(service.developmentCalls, 1);
    expect(await catalogs.read(scope, 'canales'), isNotNull);
    expect(await catalogs.read(scope, 'estatus-prospecto'), isNotNull);
    expect(await catalogs.read(scope, 'lotes:12'), isNotNull);
    expect(await catalogs.read(scope, 'desarrollos'), isNotNull);

    await repository.warmCatalogs();
    expect(service.catalogCalls, 2);
    expect(service.lotsCalls, 1);
    expect(service.developmentCalls, 1);
  });

  test('los lotes se cachean por desarrollo', () async {
    final auth = await _auth(userId: 7, developmentId: 12);
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final catalogs = CatalogCache(database: database);
    final online = ProspectsRepository(
      auth: auth,
      catalogs: catalogs,
      service: _CatalogProspectsService(),
    );
    expect((await online.loadLots(21)).single['desarrollo_id'], 21);
    expect((await online.loadLots(22)).single['desarrollo_id'], 22);

    final offline = ProspectsRepository(
      auth: auth,
      catalogs: catalogs,
      service: _CatalogProspectsService(failLots: true),
    );
    expect((await offline.loadLots(21)).single['desarrollo_id'], 21);
    expect((await offline.loadLots(22)).single['desarrollo_id'], 22);
  });

  test('una edición con id temporal ya sincronizado usa el id real', () async {
    final auth = await _auth(userId: 4, developmentId: 8);
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final cache = ProspectsCache(database: database);
    final store = PendingOperationsStore(database: database);
    const scope = LocalScope(userId: 4, developmentId: 8);
    final created = _prospect(-1, 'Local');
    await cache.upsert(scope, created);
    await store.enqueue(
      scope,
      kind: 'prospect.create',
      entityId: -1,
      operationKey: 'create',
      payload: {'local_prospect': _row(created)},
    );
    final creation = (await store.read(scope)).single;
    await store.remapProspectId(creation, temporaryId: -1, serverId: 88);
    expect(await store.read(scope), isEmpty);

    final remote = _RecordingProspectsService();
    final repository = ProspectsRepository(
      auth: auth,
      cache: cache,
      outbox: store,
      service: remote,
    );

    final result = await repository.update(_prospect(-1, 'Local'), const {
      'nombre': 'Local editado',
    }, optimisticProspect: _prospect(-1, 'Local editado'));

    expect(result.isPending, isFalse);
    expect(result.prospect?.id, 88);
    expect(remote.updatedIds, [88]);
    expect(await store.read(scope), isEmpty);
    expect((await cache.read(scope)).single.id, 88);
  });

  test('el discovery se lee de la caché cuando no hay conexión', () async {
    final auth = await _auth(userId: 4, developmentId: 8);
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    const scope = LocalScope(userId: 4, developmentId: 8);
    final discoveries = DiscoveryCache(database: database);
    await discoveries.write(scope, 5, const {'motivo_propiedad': 'inversion'});
    final repository = ProspectsRepository(
      auth: auth,
      discoveries: discoveries,
      outbox: PendingOperationsStore(database: database),
      service: _DiscoveryProspectsService(offline: true),
    );

    expect(await repository.loadDiscovery(5), {
      'motivo_propiedad': 'inversion',
    });
  });

  test(
    'el discovery superpone las secciones pendientes sobre la red',
    () async {
      final auth = await _auth(userId: 4, developmentId: 8);
      final database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(database.close);
      const scope = LocalScope(userId: 4, developmentId: 8);
      final store = PendingOperationsStore(database: database);
      await store.enqueue(
        scope,
        kind: 'prospect.discovery',
        entityId: 5,
        operationKey: 'discovery',
        payload: const {
          'fields': {
            'seccion': 'necesidad_objetivo',
            'motivo_propiedad': 'inversion',
          },
        },
      );
      final discoveries = DiscoveryCache(database: database);
      final repository = ProspectsRepository(
        auth: auth,
        discoveries: discoveries,
        outbox: store,
        service: _DiscoveryProspectsService(
          payload: const {'presupuesto': 1500, 'tipo_propiedad': 'casa'},
        ),
      );

      expect(await repository.loadDiscovery(5), {
        'presupuesto': 1500,
        'tipo_propiedad': 'casa',
        'motivo_propiedad': 'inversion',
      });
      // La caché queda con el estado optimista para el próximo arranque.
      expect(
        (await discoveries.read(scope, 5))?['motivo_propiedad'],
        'inversion',
      );
    },
  );

  test(
    'una sección de discovery guardada sin conexión queda visible',
    () async {
      final auth = await _auth(userId: 4, developmentId: 8);
      final database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(database.close);
      const scope = LocalScope(userId: 4, developmentId: 8);
      final discoveries = DiscoveryCache(database: database);
      final store = PendingOperationsStore(database: database);
      final repository = ProspectsRepository(
        auth: auth,
        cache: ProspectsCache(database: database),
        discoveries: discoveries,
        outbox: store,
        service: _DiscoveryProspectsService(failSaveOffline: true),
      );

      final result = await repository.saveDiscoverySection(
        _prospect(5, 'Ana'),
        const {
          'seccion': 'necesidad_objetivo',
          'motivo_propiedad': 'inversion',
        },
      );

      expect(result.isPending, isTrue);
      expect(await store.read(scope), hasLength(1));
      expect(await repository.loadDiscovery(5), {
        'motivo_propiedad': 'inversion',
      });
    },
  );
}

/// Servicio de discovery controlable: permite simular falta de conexión y
/// respuestas del servidor sin tocar la red.
class _DiscoveryProspectsService extends ProspectsService {
  _DiscoveryProspectsService({
    this.payload,
    this.offline = false,
    this.failSaveOffline = false,
  });

  final Map<String, dynamic>? payload;
  final bool offline;
  final bool failSaveOffline;
  final List<String> saved = [];

  @override
  Future<Map<String, dynamic>?> discovery(int prospectId) async {
    if (offline) throw const ProspectsOfflineException('No se pudo conectar.');
    return payload;
  }

  @override
  Future<void> saveDiscoverySection(
    int prospectId,
    Map<String, dynamic> fields, {
    String? operationKey,
  }) async {
    saved.add('$prospectId:${fields['seccion']}');
    if (failSaveOffline) {
      throw const ProspectsOfflineException('No se pudo conectar.');
    }
  }

  @override
  Future<List<ProspectRecord>> fetch() async => const [];

  @override
  void dispose() {}
}

Future<AuthService> _auth({
  required int userId,
  required int developmentId,
}) async {
  final auth = AuthService(
    baseUrl: 'https://example.com',
    client: MockClient(
      (_) async => http.Response(
        jsonEncode({
          'status': 'success',
          'token': 'test-token',
          'usuario': {'id': userId, 'nombre_completo': 'Agente'},
          'desarrollo_activo': {'id': developmentId},
        }),
        200,
      ),
    ),
  );
  await auth.login('agente', 'password');
  return auth;
}

ProspectRecord _prospect(int id, String name, {DateTime? assignedAt}) =>
    ProspectRecord(
      id: id,
      name: name,
      phone: '$id',
      email: '$name@example.com',
      status: 'Nuevo',
      temperature: 'Tibio',
      avatarColor: Colors.teal,
      statusColor: Colors.blue,
      assignedAt: assignedAt,
    );

class _FakeProspectsService extends ProspectsService {
  _FakeProspectsService(this.loader);

  final Future<List<ProspectRecord>> Function() loader;

  @override
  Future<List<ProspectRecord>> fetch() => loader();

  @override
  void dispose() {}
}

Map<String, dynamic> _row(ProspectRecord prospect) => Map<String, dynamic>.from(
  ProspectCacheMapper.toRow(prospect, userId: 0, developmentId: 0),
);

class _FailingCreateService extends ProspectsService {
  @override
  Future<int> create(
    Map<String, dynamic> fields, {
    String? operationKey,
  }) async => throw const ProspectsRecoverableException('Sin conexión');

  @override
  Future<List<ProspectRecord>> fetch() async => const [];

  @override
  void dispose() {}
}

class _RecordingProspectsService extends ProspectsService {
  final List<String> calls = [];
  final List<int> updatedIds = [];

  @override
  Future<int> create(
    Map<String, dynamic> fields, {
    String? operationKey,
  }) async {
    calls.add('create:$operationKey');
    return 120;
  }

  @override
  Future<void> update(
    int prospectId,
    Map<String, dynamic> fields, {
    String? operationKey,
  }) async {
    calls.add('update:$prospectId:$operationKey');
    updatedIds.add(prospectId);
  }

  @override
  Future<List<ProspectRecord>> fetch() async => const [];

  @override
  void dispose() {}
}

class _CatalogProspectsService extends ProspectsService {
  _CatalogProspectsService({
    this.failOrigins = false,
    this.failStatuses = false,
    this.failLots = false,
  });

  final bool failOrigins;
  final bool failStatuses;
  final bool failLots;
  int catalogCalls = 0;
  int lotsCalls = 0;
  int developmentCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> catalog(String name) async {
    catalogCalls++;
    if (name == 'canales') {
      if (failOrigins) {
        throw const ProspectsRecoverableException('Sin conexión a canales');
      }
      return const [
        {'id': 9, 'nombre': 'Referido'},
      ];
    }
    if (failStatuses) {
      throw const ProspectsRecoverableException('Sin conexión a estatus');
    }
    return const [
      {'id': 1, 'nombre': 'Nuevo'},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> availableLots([int? developmentId]) async {
    lotsCalls++;
    if (failLots) {
      throw const ProspectsRecoverableException('Sin conexión a lotes');
    }
    return [
      {'id': developmentId ?? 1, 'desarrollo_id': developmentId ?? 12},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> availableDevelopments() async {
    developmentCalls++;
    return const [
      {'id': 12, 'nombre': 'Runa'},
    ];
  }

  @override
  void dispose() {}
}
