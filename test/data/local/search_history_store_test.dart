import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/search_history_store.dart';
import 'package:callerapp_frontend/presentation/models/search_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late SearchHistoryStore store;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    store = SearchHistoryStore(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('aísla el historial por usuario y desarrollo', () async {
    const firstScope = LocalScope(userId: 1, developmentId: 10);
    const secondScope = LocalScope(userId: 1, developmentId: 20);

    await store.add(firstScope, _entry('José', DateTime(2026, 11, 2, 9)));
    await store.add(firstScope, _entry('Ana', DateTime(2026, 11, 2, 10)));
    await store.add(secondScope, _entry('Beto', DateTime(2026, 11, 2, 11)));

    expect((await store.read(firstScope)).map((entry) => entry.query), [
      'Ana',
      'José',
    ]);
    expect((await store.read(secondScope)).map((entry) => entry.query), [
      'Beto',
    ]);
  });

  test('deduplica sin distinguir acentos ni mayúsculas', () async {
    const scope = LocalScope(userId: 1, developmentId: 10);
    final first = DateTime(2026, 11, 2, 9);

    await store.add(
      scope,
      _entry('José', first, prospectId: 7, prospectName: 'José Pérez'),
    );
    final second = DateTime(2026, 11, 2, 10);
    await store.add(scope, _entry('jose', second));

    final deduplicated = await store.read(scope);
    expect(deduplicated, hasLength(1));
    expect(deduplicated.single.query, 'jose');
    expect(deduplicated.single.prospectId, 7);
    expect(deduplicated.single.prospectName, 'José Pérez');
    expect(deduplicated.single.searchedAt, second);

    final third = DateTime(2026, 11, 2, 11);
    await store.add(
      scope,
      _entry('JOSÉ', third, prospectId: 9, prospectName: 'Otro José'),
    );
    final replaced = await store.read(scope);
    expect(replaced, hasLength(1));
    expect(replaced.single.prospectId, 9);
    expect(replaced.single.searchedAt, third);
  });

  test('conserva como máximo ocho entradas, las más recientes', () async {
    const scope = LocalScope(userId: 1, developmentId: 10);

    for (var index = 0; index < 10; index++) {
      await store.add(
        scope,
        _entry('término $index', DateTime(2026, 11, 2, 9, index)),
      );
    }

    final entries = await store.read(scope);
    expect(entries, hasLength(SearchHistoryStore.maxEntries));
    expect(entries.first.query, 'término 9');
    expect(entries.last.query, 'término 2');
  });

  test('elimina un término y borra todo el historial', () async {
    const scope = LocalScope(userId: 1, developmentId: 10);
    await store.add(scope, _entry('José', DateTime(2026, 11, 2, 9)));
    await store.add(scope, _entry('Ana', DateTime(2026, 11, 2, 10)));

    final remaining = await store.remove(scope, 'jose');
    expect(remaining.map((entry) => entry.query), ['Ana']);

    await store.clear(scope);
    expect(await store.read(scope), isEmpty);
  });

  test('un historial corrupto no rompe la lectura', () async {
    const scope = LocalScope(userId: 1, developmentId: 10);
    await database.writeMetadata('search_history:1:10', '{esto no es json');

    expect(await store.read(scope), isEmpty);

    final updated = await store.add(
      scope,
      _entry('Ana', DateTime(2026, 11, 2, 9)),
    );
    expect(updated.single.query, 'Ana');
    expect((await store.read(scope)).single.query, 'Ana');
  });

  test('el mantenimiento purga el historial junto con el ámbito', () async {
    const scope = LocalScope(userId: 8, developmentId: 80);
    await store.add(scope, _entry('Ana', DateTime(2026, 11, 2, 9)));

    final raw = await database.database;
    await raw.insert('cache_metadata', {
      'user_id': scope.userId,
      'development_id': scope.developmentId,
      'resource': AppDatabase.prospectsResource,
      'refreshed_at_ms': DateTime.now()
          .subtract(const Duration(days: 31))
          .millisecondsSinceEpoch,
    });

    await database.purgeExpiredScopes(
      DateTime.now().subtract(const Duration(days: 30)),
    );

    expect(await store.read(scope), isEmpty);
  });
}

RecentSearch _entry(
  String query,
  DateTime searchedAt, {
  int? prospectId,
  String? prospectName,
}) => RecentSearch(
  query: query,
  searchedAt: searchedAt,
  prospectId: prospectId,
  prospectName: prospectName,
);
