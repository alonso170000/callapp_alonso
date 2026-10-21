import 'dart:convert';

import 'package:callerapp_frontend/data/local/activities_cache.dart';
import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/pending_operations_store.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/repositories/agenda_repository.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('guarda la agenda remota dentro del ámbito autenticado', () async {
    final auth = await _auth(userId: 4, developmentId: 8);
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final cache = ActivitiesCache(database: database);
    final repository = AgendaRepository(
      auth: auth,
      cache: cache,
      service: _FakeAgendaService(() async => [_activity(15, 'Visita')]),
    );

    expect((await repository.refresh()).single.title, 'Visita');
    expect((await repository.readCache()).single.id, 15);
  });

  test('un error remoto no elimina la última agenda válida', () async {
    final auth = await _auth(userId: 5, developmentId: 9);
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final cache = ActivitiesCache(database: database);
    const scope = LocalScope(userId: 5, developmentId: 9);
    await cache.replace(scope, [_activity(21, 'Guardada')]);
    final repository = AgendaRepository(
      auth: auth,
      cache: cache,
      service: _FakeAgendaService(
        () async => throw const AgendaException('Sin conexión'),
      ),
    );

    await expectLater(repository.refresh(), throwsA(isA<AgendaException>()));
    expect((await repository.readCache()).single.title, 'Guardada');
  });

  test('proyecta operaciones pendientes sobre el snapshot remoto', () async {
    final auth = await _auth(userId: 6, developmentId: 12);
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final outbox = PendingOperationsStore(database: database);
    const scope = LocalScope(userId: 6, developmentId: 12);
    await outbox.enqueue(
      scope,
      kind: 'agenda.complete',
      entityId: 31,
      payload: const {},
    );
    final repository = AgendaRepository(
      auth: auth,
      cache: ActivitiesCache(database: database),
      outbox: outbox,
      service: _FakeAgendaService(() async => [_activity(31, 'Pendiente')]),
    );

    expect((await repository.refresh()).single.status, AgendaStatus.completed);
    expect(
      (await repository.readCache()).single.status,
      AgendaStatus.completed,
    );
  });

  test(
    'fallo recuperable aplica el cambio y conserva la misma operación',
    () async {
      final auth = await _auth(userId: 7, developmentId: 14);
      final database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(database.close);
      final cache = ActivitiesCache(database: database);
      final outbox = PendingOperationsStore(database: database);
      const scope = LocalScope(userId: 7, developmentId: 14);
      final activity = _activity(41, 'Actividad');
      await cache.replace(scope, [activity]);
      final repository = AgendaRepository(
        auth: auth,
        cache: cache,
        outbox: outbox,
        service: _OfflineAgendaService(() async => [activity]),
      );

      final result = await repository.complete(activity);
      expect(result.isPending, isTrue);
      expect((await cache.read(scope)).single.status, AgendaStatus.completed);
      expect((await outbox.read(scope)).single.kind, 'agenda.complete');
    },
  );
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

AgendaActivity _activity(int id, String title) => AgendaActivity(
  id: id,
  prospectId: id + 100,
  title: title,
  prospect: 'Prospecto $id',
  description: 'Descripción $id',
  date: DateTime(2026, 10, 21, 10),
  status: AgendaStatus.pending,
);

class _FakeAgendaService extends AgendaService {
  _FakeAgendaService(this.loader);

  final Future<List<AgendaActivity>> Function() loader;

  @override
  Future<List<AgendaActivity>> fetch() => loader();

  @override
  void dispose() {}
}

class _OfflineAgendaService extends _FakeAgendaService {
  _OfflineAgendaService(super.loader);

  @override
  Future<void> complete(int id, {String? operationKey}) =>
      throw const AgendaRecoverableException('Sin conexión.');
}
