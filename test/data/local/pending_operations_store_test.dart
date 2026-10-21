import 'package:callerapp_frontend/data/local/activities_cache.dart';
import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/pending_operations_store.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late PendingOperationsStore store;
  const first = LocalScope(userId: 1, developmentId: 10);
  const second = LocalScope(userId: 2, developmentId: 20);

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    store = PendingOperationsStore(database: database);
  });
  tearDown(() => database.close());

  test('mantiene FIFO y aísla cada usuario y desarrollo', () async {
    await store.enqueue(
      first,
      kind: 'agenda.complete',
      entityId: 8,
      operationKey: 'a',
      payload: const {},
    );
    await store.enqueue(
      first,
      kind: 'agenda.cancel',
      entityId: 9,
      operationKey: 'b',
      payload: const {},
    );
    await store.enqueue(
      second,
      kind: 'agenda.delete',
      entityId: 8,
      operationKey: 'c',
      payload: const {},
    );

    expect((await store.read(first)).map((value) => value.operationKey), [
      'a',
      'b',
    ]);
    expect((await store.read(second)).single.operationKey, 'c');
  });

  test('recupera syncing sin cambiar la clave ni borrar intentos', () async {
    await store.enqueue(
      first,
      kind: 'agenda.complete',
      entityId: 8,
      operationKey: 'stable',
      payload: const {},
    );
    final operation = (await store.read(first)).single;
    await store.markSyncing(operation);
    await store.recoverInterrupted(first);
    final recovered = (await store.read(first)).single;
    expect(recovered.state, PendingOperationState.pending);
    expect(recovered.operationKey, 'stable');
    expect(recovered.attemptCount, 1);
  });

  test('clearScope y clearAll nunca eliminan el outbox', () async {
    await store.enqueue(
      first,
      kind: 'agenda.complete',
      entityId: 8,
      payload: const {},
    );
    await database.clearScope(first);
    expect(await store.read(first), hasLength(1));
    await database.clearAll();
    expect(await store.read(first), hasLength(1));
  });

  test('remapea actividad, notificación y operaciones dependientes en una transacción', () async {
    final cache = ActivitiesCache(database: database);
    await cache.upsert(
      first,
      AgendaActivity(
        id: -1,
        title: 'Local',
        prospect: 'Ana',
        description: 'Pendiente',
        date: DateTime(2026, 10, 21, 12),
        status: AgendaStatus.pending,
      ),
    );
    await store.enqueue(
      first,
      kind: 'agenda.create',
      entityId: -1,
      operationKey: 'create',
      payload: const {
        'fields': <String, dynamic>{},
        'local_activity': {'id': -1},
      },
    );
    await store.enqueue(
      first,
      kind: 'agenda.complete',
      entityId: -1,
      operationKey: 'complete',
      payload: const {'activity_id': -1},
    );
    final creation = (await store.read(first)).first;
    await store.remapActivityId(creation, temporaryId: -1, serverId: 44);

    expect((await cache.read(first)).single.id, 44);
    final remaining = (await store.read(first)).single;
    expect(remaining.entityId, 44);
    expect(remaining.payload['activity_id'], 44);
  });
}
