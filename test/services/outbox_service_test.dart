import 'dart:convert';

import 'package:callerapp_frontend/data/local/activities_cache.dart';
import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/pending_operations_store.dart';
import 'package:callerapp_frontend/data/local/prospects_cache.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/outbox_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test(
    'vacía FIFO y conserva la clave idempotente de cada reintento',
    () async {
      final auth = await _auth();
      final database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(database.close);
      final store = PendingOperationsStore(database: database);
      const scope = LocalScope(userId: 3, developmentId: 6);
      await store.enqueue(
        scope,
        kind: 'agenda.complete',
        entityId: 1,
        operationKey: 'first',
        payload: const {},
      );
      await store.enqueue(
        scope,
        kind: 'agenda.cancel',
        entityId: 2,
        operationKey: 'second',
        payload: const {},
      );
      final agenda = _RecordingAgendaService();
      final service = OutboxService(
        store: store,
        agenda: agenda,
        activities: ActivitiesCache(database: database),
        auth: auth,
      );

      await service.flush();

      expect(agenda.calls, ['complete:1:first', 'cancel:2:second']);
      expect(await store.read(scope), isEmpty);
    },
  );

  test('un conflicto no bloquea una operación independiente', () async {
    final auth = await _auth();
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final store = PendingOperationsStore(database: database);
    const scope = LocalScope(userId: 3, developmentId: 6);
    await store.enqueue(
      scope,
      kind: 'agenda.delete',
      entityId: 1,
      operationKey: 'conflict',
      payload: const {},
    );
    await store.enqueue(
      scope,
      kind: 'agenda.complete',
      entityId: 2,
      operationKey: 'next',
      payload: const {},
    );
    final agenda = _RecordingAgendaService(conflictDelete: true);
    final service = OutboxService(
      store: store,
      agenda: agenda,
      activities: ActivitiesCache(database: database),
      auth: auth,
    );

    await service.flush();

    final remaining = (await store.read(scope)).single;
    expect(remaining.state, PendingOperationState.conflict);
    expect(agenda.calls, contains('complete:2:next'));
  });

  test(
    'una actividad local espera a que el prospecto reciba su id real',
    () async {
      final auth = await _auth();
      final database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(database.close);
      final store = PendingOperationsStore(database: database);
      const scope = LocalScope(userId: 3, developmentId: 6);
      await store.enqueue(
        scope,
        kind: 'prospect.create',
        entityId: -1,
        operationKey: 'prospect',
        payload: const {
          'fields': {'nombre': 'Ana'},
          'local_prospect': {'prospect_id': -1},
        },
      );
      await store.enqueue(
        scope,
        kind: 'agenda.create',
        entityId: -2,
        operationKey: 'activity',
        payload: const {
          'fields': {'prospecto_id': -1, 'tipo': 'llamada'},
        },
      );
      final candidates = _RecordingProspectsService(createdId: 100);
      final agenda = _RecordingAgendaService();
      final service = OutboxService(
        store: store,
        agenda: agenda,
        prospects: candidates,
        activities: ActivitiesCache(database: database),
        prospectsCache: ProspectsCache(database: database),
        auth: auth,
      );

      await service.flush();

      expect(candidates.calls, ['create:prospect']);
      expect(agenda.calls.single, 'create:100:activity');
      expect(await store.read(scope), isEmpty);
    },
  );

  test(
    'un seguimiento espera a que la actividad de origen exista en el servidor',
    () async {
      final auth = await _auth();
      final database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(database.close);
      final store = PendingOperationsStore(database: database);
      const scope = LocalScope(userId: 3, developmentId: 6);
      await store.enqueue(
        scope,
        kind: 'agenda.create',
        entityId: -2,
        operationKey: 'activity',
        payload: const {
          'fields': {'tipo': 'llamada'},
        },
      );
      await store.enqueue(
        scope,
        kind: 'prospect.follow_up',
        entityId: 7,
        operationKey: 'follow-up',
        payload: const {
          'fields': {'actividad_origen_id': -2},
        },
      );
      final candidates = _RecordingProspectsService();
      final agenda = _RecordingAgendaService();
      final service = OutboxService(
        store: store,
        agenda: agenda,
        prospects: candidates,
        activities: ActivitiesCache(database: database),
        prospectsCache: ProspectsCache(database: database),
        auth: auth,
      );

      await service.flush();

      expect(agenda.calls.single, 'create:null:activity');
      expect(candidates.calls.single, 'follow_up:7:500:follow-up');
      expect(await store.read(scope), isEmpty);
    },
  );

  test(
    'ejecuta las mutaciones de prospectos con su clave idempotente',
    () async {
      final auth = await _auth();
      final database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(database.close);
      final store = PendingOperationsStore(database: database);
      const scope = LocalScope(userId: 3, developmentId: 6);
      await store.enqueue(
        scope,
        kind: 'prospect.update',
        entityId: 15,
        operationKey: 'update',
        payload: const {
          'fields': {'nombre': 'Nuevo'},
        },
      );
      await store.enqueue(
        scope,
        kind: 'prospect.follow_up',
        entityId: 15,
        operationKey: 'follow-up',
        payload: const {
          'fields': {'estatus': 'Contactado'},
        },
      );
      await store.enqueue(
        scope,
        kind: 'prospect.discovery',
        entityId: 15,
        operationKey: 'discovery',
        payload: const {
          'fields': {'presupuesto': '500000'},
        },
      );
      final candidates = _RecordingProspectsService();
      final service = OutboxService(
        store: store,
        prospects: candidates,
        activities: ActivitiesCache(database: database),
        prospectsCache: ProspectsCache(database: database),
        auth: auth,
      );

      await service.flush();

      expect(candidates.calls, [
        'update:15:update',
        'follow_up:15:null:follow-up',
        'discovery:15:discovery',
      ]);
      expect(await store.read(scope), isEmpty);
    },
  );

  test('un vaciado sin operaciones no marca una sincronización', () async {
    final auth = await _auth();
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final store = PendingOperationsStore(database: database);
    const scope = LocalScope(userId: 3, developmentId: 6);
    final service = OutboxService(
      store: store,
      agenda: _RecordingAgendaService(),
      activities: ActivitiesCache(database: database),
      auth: auth,
    );

    await service.flush();
    expect(service.revision, 0);

    await store.enqueue(
      scope,
      kind: 'agenda.complete',
      entityId: 1,
      operationKey: 'only',
      payload: const {},
    );
    await service.flush();
    expect(service.revision, 1);

    await service.flush();
    expect(service.revision, 1);
  });

  test(
    'reintentar un prospecto en conflicto informa su propio error',
    () async {
      final auth = await _auth();
      final database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(database.close);
      final store = PendingOperationsStore(database: database);
      const scope = LocalScope(userId: 3, developmentId: 6);
      await store.enqueue(
        scope,
        kind: 'prospect.update',
        entityId: 15,
        operationKey: 'update',
        payload: const {
          'fields': {'nombre': 'Nuevo'},
        },
      );
      final operation = (await store.read(scope)).single;
      await store.markConflict(operation, 'Datos inválidos.');
      final service = OutboxService(
        store: store,
        prospects: _RecordingProspectsService(failUpdate: true),
        activities: ActivitiesCache(database: database),
        prospectsCache: ProspectsCache(database: database),
        auth: auth,
      );

      await expectLater(
        service.retry((await store.read(scope)).single),
        throwsA(isA<ProspectsBusinessException>()),
      );
    },
  );

  test('un prospecto local se crea y luego se renombra', () async {
    final auth = await _auth();
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final store = PendingOperationsStore(database: database);
    const scope = LocalScope(userId: 3, developmentId: 6);
    await store.enqueue(
      scope,
      kind: 'prospect.create',
      entityId: -1,
      operationKey: 'create',
      payload: const {
        'fields': {'nombre': 'Ana'},
        'local_prospect': {'id': -1},
      },
    );
    await store.enqueue(
      scope,
      kind: 'prospect.update',
      entityId: -1,
      operationKey: 'update',
      payload: const {
        'fields': {'nombre': 'Ana María'},
        'local_prospect': {'id': -1},
      },
    );
    final candidates = _RecordingProspectsService(createdId: 100);
    final service = OutboxService(
      store: store,
      prospects: candidates,
      activities: ActivitiesCache(database: database),
      prospectsCache: ProspectsCache(database: database),
      auth: auth,
    );

    await service.flush();

    expect(candidates.calls, ['create:create', 'update:100:update']);
    expect(await store.read(scope), isEmpty);
  });

  test(
    'una creación en conflicto no deja muda a su edición dependiente',
    () async {
      final auth = await _auth();
      final database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(database.close);
      final store = PendingOperationsStore(database: database);
      const scope = LocalScope(userId: 3, developmentId: 6);
      await store.enqueue(
        scope,
        kind: 'prospect.create',
        entityId: -1,
        operationKey: 'create',
        payload: const {
          'fields': {'nombre': 'Ana'},
          'local_prospect': {'id': -1},
        },
      );
      await store.enqueue(
        scope,
        kind: 'prospect.update',
        entityId: -1,
        operationKey: 'update',
        payload: const {
          'fields': {'nombre': 'Ana María'},
          'local_prospect': {'id': -1},
        },
      );
      final create = (await store.read(scope))
          .firstWhere((operation) => operation.kind == 'prospect.create');
      await store.markConflict(create, 'El servidor rechazó la creación.');
      final candidates = _RecordingProspectsService();
      final service = OutboxService(
        store: store,
        prospects: candidates,
        activities: ActivitiesCache(database: database),
        prospectsCache: ProspectsCache(database: database),
        auth: auth,
      );

      await service.flush();

      expect(candidates.calls, isEmpty);
      final remaining = await store.read(scope);
      expect(remaining, hasLength(2));
      final update = remaining.firstWhere(
        (operation) => operation.kind == 'prospect.update',
      );
      expect(update.state, PendingOperationState.conflict);
      expect(
        update.lastError,
        'El registro local del que depende no se pudo crear.',
      );
    },
  );

  test('un fallo recuperable de la creación deja visible su motivo', () async {
    final auth = await _auth();
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final store = PendingOperationsStore(database: database);
    const scope = LocalScope(userId: 3, developmentId: 6);
    await store.enqueue(
      scope,
      kind: 'prospect.create',
      entityId: -1,
      operationKey: 'create',
      payload: const {
        'fields': {'nombre': 'Ana'},
        'local_prospect': {'id': -1},
      },
    );
    await store.enqueue(
      scope,
      kind: 'prospect.update',
      entityId: -1,
      operationKey: 'update',
      payload: const {
        'fields': {'nombre': 'Ana María'},
        'local_prospect': {'id': -1},
      },
    );
    final candidates = _RecordingProspectsService(failCreateRecoverable: true);
    final service = OutboxService(
      store: store,
      prospects: candidates,
      activities: ActivitiesCache(database: database),
      prospectsCache: ProspectsCache(database: database),
      auth: auth,
    );

    await service.flush();

    expect(candidates.calls, ['create:create']);
    final remaining = await store.read(scope);
    expect(remaining, hasLength(2));
    final create = remaining.firstWhere(
      (operation) => operation.kind == 'prospect.create',
    );
    expect(create.state, PendingOperationState.pending);
    expect(create.lastError, isNotNull);
    final update = remaining.firstWhere(
      (operation) => operation.kind == 'prospect.update',
    );
    expect(update.state, PendingOperationState.pending);
  });

  test('una excepción base deja la operación visible y no propaga', () async {
    final auth = await _auth();
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final store = PendingOperationsStore(database: database);
    const scope = LocalScope(userId: 3, developmentId: 6);
    await store.enqueue(
      scope,
      kind: 'prospect.update',
      entityId: 15,
      operationKey: 'update',
      payload: const {
        'fields': {'nombre': 'Nuevo'},
      },
    );
    final service = OutboxService(
      store: store,
      prospects: _RecordingProspectsService(failUpdateWithBase: true),
      activities: ActivitiesCache(database: database),
      prospectsCache: ProspectsCache(database: database),
      auth: auth,
    );

    await service.flush();

    final remaining = (await store.read(scope)).single;
    expect(remaining.state, isNot(PendingOperationState.syncing));
    expect(remaining.lastError, isNotNull);
  });

  test('un error inesperado deja la operación pendiente y visible', () async {
    final auth = await _auth();
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final store = PendingOperationsStore(database: database);
    const scope = LocalScope(userId: 3, developmentId: 6);
    await store.enqueue(
      scope,
      kind: 'prospect.update',
      entityId: 15,
      operationKey: 'update',
      payload: const {
        'fields': {'nombre': 'Nuevo'},
      },
    );
    final service = OutboxService(
      store: store,
      prospects: _RecordingProspectsService(failUpdateWithError: true),
      activities: ActivitiesCache(database: database),
      prospectsCache: ProspectsCache(database: database),
      auth: auth,
    );

    await service.flush();

    final remaining = (await store.read(scope)).single;
    expect(remaining.state, PendingOperationState.pending);
    expect(remaining.lastError, isNotNull);
  });
}

Future<AuthService> _auth() async {
  final auth = AuthService(
    baseUrl: 'https://example.com',
    client: MockClient(
      (_) async => http.Response(
        jsonEncode({
          'status': 'success',
          'token': 'test-token',
          'usuario': {'id': 3, 'nombre_completo': 'Agente'},
          'desarrollo_activo': {'id': 6},
        }),
        200,
      ),
    ),
  );
  await auth.login('agente', 'password');
  return auth;
}

class _RecordingAgendaService extends AgendaService {
  _RecordingAgendaService({this.conflictDelete = false});
  final bool conflictDelete;
  final List<String> calls = [];

  @override
  Future<AgendaActivity> create(
    Map<String, dynamic> fields, {
    String? operationKey,
  }) async {
    calls.add('create:${fields['prospecto_id']}:$operationKey');
    return AgendaActivity(
      id: 500,
      title: 'Actividad local',
      prospect: 'Ana',
      description: 'Pendiente',
      date: DateTime(2026, 10, 22, 9),
      status: AgendaStatus.pending,
    );
  }

  @override
  Future<void> complete(int id, {String? operationKey}) async =>
      calls.add('complete:$id:$operationKey');
  @override
  Future<void> cancel(int id, {String? operationKey}) async =>
      calls.add('cancel:$id:$operationKey');
  @override
  Future<void> delete(int id, {String? operationKey}) async {
    calls.add('delete:$id:$operationKey');
    if (conflictDelete) {
      throw const AgendaBusinessException('La ventana para eliminar terminó.');
    }
  }

  @override
  Future<List<AgendaActivity>> fetch() async => const [];
  @override
  void dispose() {}
}

class _RecordingProspectsService extends ProspectsService {
  _RecordingProspectsService({
    this.createdId = 100,
    this.failUpdate = false,
    this.failCreateRecoverable = false,
    this.failUpdateWithBase = false,
    this.failUpdateWithError = false,
  });

  final int createdId;
  final bool failUpdate;
  final bool failCreateRecoverable;
  final bool failUpdateWithBase;
  final bool failUpdateWithError;
  final List<String> calls = [];

  @override
  Future<int> create(
    Map<String, dynamic> fields, {
    String? operationKey,
  }) async {
    calls.add('create:$operationKey');
    if (failCreateRecoverable) {
      throw const ProspectsRecoverableException('No se pudo conectar.');
    }
    return createdId;
  }

  @override
  Future<void> update(
    int prospectId,
    Map<String, dynamic> fields, {
    String? operationKey,
  }) async {
    calls.add('update:$prospectId:$operationKey');
    if (failUpdate) {
      throw const ProspectsBusinessException('Datos inválidos.');
    }
    if (failUpdateWithBase) {
      throw const ProspectsException(
        'El servidor devolvió una respuesta inválida.',
      );
    }
    if (failUpdateWithError) {
      throw StateError('store caído');
    }
  }

  @override
  Future<void> createFollowUp(
    int prospectId,
    Map<String, dynamic> fields, {
    String? operationKey,
  }) async {
    calls.add(
      'follow_up:$prospectId:${fields['actividad_origen_id']}:$operationKey',
    );
  }

  @override
  Future<void> saveDiscoverySection(
    int prospectId,
    Map<String, dynamic> fields, {
    String? operationKey,
  }) async {
    calls.add('discovery:$prospectId:$operationKey');
  }

  @override
  Future<List<ProspectRecord>> fetch() async => const [];

  @override
  void dispose() {}
}
