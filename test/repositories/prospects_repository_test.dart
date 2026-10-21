import 'dart:convert';

import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/prospects_cache.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
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
