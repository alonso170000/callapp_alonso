import 'dart:convert';

import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/prospects_cache.dart';
import 'package:callerapp_frontend/data/local/search_history_store.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/search_models.dart';
import 'package:callerapp_frontend/repositories/prospect_search_repository.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  const scope = LocalScope(userId: 4, developmentId: 8);

  late AppDatabase database;
  late ProspectsCache cache;
  late SearchHistoryStore history;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    cache = ProspectsCache(database: database);
    history = SearchHistoryStore(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<ProspectSearchRepository> buildRepository(
    ProspectsService service,
  ) async {
    final auth = await _auth(userId: 4, developmentId: 8);
    return ProspectSearchRepository(
      repository: ProspectsRepository(
        auth: auth,
        cache: cache,
        service: service,
      ),
      history: history,
    );
  }

  test('load lee la caché y el historial sin llamar al servicio', () async {
    await cache.replace(scope, [_prospect(1, 'Ana')]);
    await history.add(scope, _recent('ana', DateTime(2026, 11, 2, 9)));
    final service = _FakeProspectsService(
      () async => throw StateError('No debe llamarse al servicio'),
    );
    final repository = await buildRepository(service);

    final snapshot = await repository.load();

    expect(service.fetchCalls, 0);
    expect(snapshot.prospects.single.name, 'Ana');
    expect(snapshot.recentSearches.single.query, 'ana');
    expect(snapshot.cachedAt, isNotNull);
  });

  test(
    'load devuelve listas vacías cuando no hay caché ni historial',
    () async {
      final service = _FakeProspectsService(() async => const []);
      final repository = await buildRepository(service);

      final snapshot = await repository.load();

      expect(snapshot.prospects, isEmpty);
      expect(snapshot.recentSearches, isEmpty);
      expect(snapshot.cachedAt, isNull);
    },
  );

  test(
    'refresh consulta el backend, actualiza la caché y conserva historial',
    () async {
      await history.add(scope, _recent('ana', DateTime(2026, 11, 2, 9)));
      final service = _FakeProspectsService(() async => [_prospect(7, 'Luis')]);
      final repository = await buildRepository(service);

      final snapshot = await repository.refresh();

      expect(service.fetchCalls, 1);
      expect(snapshot.prospects.single.name, 'Luis');
      expect(snapshot.recentSearches.single.query, 'ana');
      expect(snapshot.cachedAt, isNotNull);
      expect((await cache.read(scope)).single.id, 7);
    },
  );

  test('refresh propaga la excepción del repositorio de prospectos', () async {
    final service = _FakeProspectsService(
      () async => throw const ProspectsException('Sin conexión'),
    );
    final repository = await buildRepository(service);

    await expectLater(repository.refresh(), throwsA(isA<ProspectsException>()));
  });

  test('isRefreshDue distingue caché nueva, vencida y ausente', () async {
    final repository = await buildRepository(
      _FakeProspectsService(() async => const []),
    );
    final now = DateTime(2026, 11, 2, 12);

    expect(
      repository.isRefreshDue(
        const SearchSnapshot(prospects: [], recentSearches: []),
        now: now,
      ),
      isTrue,
    );
    expect(
      repository.isRefreshDue(
        _snapshotAt(now.subtract(const Duration(minutes: 9))),
        now: now,
      ),
      isFalse,
    );
    expect(
      repository.isRefreshDue(
        _snapshotAt(now.subtract(const Duration(minutes: 10))),
        now: now,
      ),
      isTrue,
    );
  });

  test('rememberQuery recorta, ignora vacíos y asocia el prospecto', () async {
    final repository = await buildRepository(
      _FakeProspectsService(() async => const []),
    );

    expect(await repository.rememberQuery('   '), isEmpty);

    final first = await repository.rememberQuery(
      '  Ana  ',
      prospect: _prospect(3, 'Ana Torres'),
    );
    expect(first.single.query, 'Ana');
    expect(first.single.prospectId, 3);
    expect(first.single.prospectName, 'Ana Torres');

    final second = await repository.rememberQuery('ANA');
    expect(second, hasLength(1));
    expect(second.single.prospectId, 3);
  });

  test('removeQuery y clearHistory trabajan solo en el ámbito', () async {
    final repository = await buildRepository(
      _FakeProspectsService(() async => const []),
    );
    await repository.rememberQuery('Ana');
    await repository.rememberQuery('Luis');

    final remaining = await repository.removeQuery('ana');
    expect(remaining.map((entry) => entry.query), ['Luis']);

    await repository.clearHistory();
    expect((await repository.load()).recentSearches, isEmpty);
  });

  test('el historial se aísla por usuario y desarrollo', () async {
    final repository = await buildRepository(
      _FakeProspectsService(() async => const []),
    );
    await repository.rememberQuery('Ana');

    final otherScope = SearchHistoryStore(database: database);
    expect(
      await otherScope.read(const LocalScope(userId: 4, developmentId: 99)),
      isEmpty,
    );
  });
}

class _FakeProspectsService extends ProspectsService {
  _FakeProspectsService(this.loader);

  final Future<List<ProspectRecord>> Function() loader;
  int fetchCalls = 0;

  @override
  Future<List<ProspectRecord>> fetch() {
    fetchCalls++;
    return loader();
  }

  @override
  void dispose() {}
}

SearchSnapshot _snapshotAt(DateTime cachedAt) => SearchSnapshot(
  prospects: const [],
  recentSearches: const [],
  cachedAt: cachedAt,
);

ProspectRecord _prospect(int id, String name) => ProspectRecord(
  id: id,
  name: name,
  phone: '5550000000',
  email: 'contacto$id@example.com',
  status: 'Nuevo',
  temperature: 'Tibio',
  avatarColor: Colors.teal,
  statusColor: Colors.blue,
);

RecentSearch _recent(String query, DateTime searchedAt) =>
    RecentSearch(query: query, searchedAt: searchedAt);

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
