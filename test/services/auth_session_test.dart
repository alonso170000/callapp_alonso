import 'dart:convert';

import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('el login guarda la sesión en el almacén', () async {
    final store = MemorySessionStore();
    final auth = _auth(store, userId: 4, developmentId: 8);

    await auth.login('agente', 'password');

    expect(store.session, isNotNull);
    expect(store.session!.token, 'test-token');
    expect(store.session!.userId, 4);
    expect(store.session!.activeDevelopment?['id'], 8);
  });

  test('restaura la sesión sin consultar la red', () async {
    final store = MemorySessionStore()..session = _storedSession(userId: 7);

    final auth = AuthService(
      sessionStore: store,
      baseUrl: 'https://example.com',
      client: MockClient(
        (_) async => throw StateError('No debe consultar la red'),
      ),
    );
    await auth.restoreSession();

    expect(auth.isAuthenticated, isTrue);
    expect(auth.userId, 7);
    expect(auth.developmentId, 12);
    expect(auth.userName, 'Agente');
  });

  test('descarta y limpia una sesión con token vencido', () async {
    final store = MemorySessionStore()
      ..session = StoredSession(
        token: _token({
          'usuario_id': 1,
          'exp':
              DateTime.now()
                  .subtract(const Duration(hours: 1))
                  .millisecondsSinceEpoch ~/
              1000,
        }),
      );
    final auth = AuthService(
      sessionStore: store,
      baseUrl: 'https://example.com',
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    await auth.restoreSession();

    expect(auth.isAuthenticated, isFalse);
    expect(store.session, isNull);
  });

  test('cerrar sesión conserva la caché pero borra las credenciales', () async {
    final store = MemorySessionStore();
    final auth = _auth(store, userId: 4, developmentId: 8);
    await auth.login('agente', 'password');

    auth.logout();
    await Future<void>.delayed(Duration.zero);

    expect(auth.isAuthenticated, isFalse);
    expect(auth.userId, isNull);
    expect(store.session, isNull);
  });
}

AuthService _auth(
  SessionStore store, {
  required int userId,
  required int developmentId,
}) => AuthService(
  sessionStore: store,
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

StoredSession _storedSession({required int userId}) => StoredSession(
  token: _token({'usuario_id': userId}),
  userId: userId,
  userName: 'Agente',
  activeDevelopment: const {'id': 12},
);

String _token(Map<String, Object?> payload) {
  String encode(Map<String, Object?> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'none'})}.${encode(payload)}.signature';
}
