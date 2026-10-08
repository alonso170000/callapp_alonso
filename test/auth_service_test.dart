import 'dart:convert';

import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'Reads personal data from login response and clears it on logout',
    () async {
      final auth = AuthService(
        baseUrl: 'https://example.com',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'status': 'success',
              'token': 'test-token',
              'usuario': {
                'nombre_completo': 'Ana García',
                'email': 'ana@example.com',
                'telefono': '9981234567',
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      await auth.login('ana', 'secret');
      expect(auth.userName, 'Ana García');
      expect(auth.email, 'ana@example.com');
      expect(auth.phone, '9981234567');
      auth.logout();
      expect(auth.email, isNull);
      expect(auth.phone, isNull);
    },
  );
  test('Uses the signed-in full name and clears it on logout', () async {
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({'nombre_completo': 'María López'})))
        .replaceAll('=', '');
    final auth = AuthService(
      baseUrl: 'https://example.com',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 'success',
            'token': 'header.$payload.signature',
          }),
          200,
        ),
      ),
    );
    await auth.login('maria', 'secret');
    expect(auth.userName, 'María López');
    auth.logout();
    expect(auth.userName, 'Usuario');
  });
  test(
    'Sends username and preserves password; stores and clears session',
    () async {
      final auth = AuthService(
        baseUrl: 'https://example.com/',
        client: MockClient((request) async {
          expect(
            request.url.toString(),
            'https://example.com/api/v1/auth/login',
          );
          expect(jsonDecode(request.body), {
            'username': 'agente',
            'password': ' secret ',
          });
          return http.Response(
            '{"status":"success","token":"test-token","desarrollo_activo":{"id":1}}',
            200,
          );
        }),
      );
      await auth.login(' agente ', ' secret ');
      expect(auth.token, 'test-token');
      expect(auth.userName, 'agente');
      expect(auth.activeDevelopment?['id'], 1);
      auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.activeDevelopment, isNull);
    },
  );

  test('Rejected credentials never create a session', () async {
    final auth = AuthService(
      baseUrl: 'https://example.com',
      client: MockClient(
        (_) async =>
            http.Response('{"message":"Credenciales incorrectas."}', 401),
      ),
    );
    await expectLater(
      auth.login('agente', 'incorrecta'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Credenciales incorrectas.',
        ),
      ),
    );
    expect(auth.isAuthenticated, isFalse);
  });

  test('Rejects invalid success responses and missing configuration', () async {
    final auth = AuthService(
      baseUrl: 'https://example.com',
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    await expectLater(
      auth.login('agente', 'secret'),
      throwsA(isA<AuthException>()),
    );
    expect(auth.isAuthenticated, isFalse);
    await expectLater(
      AuthService(baseUrl: '').login('agente', 'secret'),
      throwsA(isA<AuthException>()),
    );
  });
}
