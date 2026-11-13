import 'dart:convert';

import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/session_store.dart';
import 'package:callerapp_frontend/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('consulta la ruta protegida y devuelve la versión', () async {
    late http.Request request;
    final client = MockClient((value) async {
      request = value;
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {'version': 'abc123'},
        }),
        200,
      );
    });
    final auth = AuthService(
      baseUrl: 'https://example.com',
      sessionStore: MemorySessionStore()
        ..session = const StoredSession(
          token: 'token-prueba',
          userId: 1,
          activeDevelopment: {'id': 2},
        ),
    );
    await auth.restoreSession();
    final service = SyncService(client: client, auth: auth);

    expect(await service.fetchVersion(), 'abc123');
    expect(request.url.path, '/api/v1/sync/version');
    expect(request.headers['Authorization'], 'Bearer token-prueba');
    expect(request.headers['Accept'], 'application/json');
  });

  test('rechaza una respuesta sin versión válida', () async {
    final auth = AuthService(
      baseUrl: 'https://example.com',
      sessionStore: MemorySessionStore()
        ..session = const StoredSession(
          token: 'token-prueba',
          userId: 1,
          activeDevelopment: {'id': 2},
        ),
    );
    await auth.restoreSession();
    final service = SyncService(
      auth: auth,
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    await expectLater(service.fetchVersion(), throwsA(isA<SyncException>()));
  });
}
