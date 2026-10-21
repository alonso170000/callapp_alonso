import 'dart:convert';

import 'package:callerapp_frontend/data/local/activities_cache.dart';
import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/pending_operations_store.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/outbox_service.dart';
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
