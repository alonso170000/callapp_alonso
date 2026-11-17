import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/scripts_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Future<AuthService> authenticatedAuth() async {
    final auth = AuthService(
      client: MockClient(
        (_) async => http.Response(
          '{"status":"success","token":"test","usuario":{"id":3},"desarrollo_activo":{"id":4}}',
          200,
        ),
      ),
    );
    await auth.login('agente', 'password');
    return auth;
  }

  test('envía desarrollo y tipo de prospecto', () async {
    final auth = await authenticatedAuth();
    late Uri requested;
    final service = ScriptsService(
      auth: auth,
      client: MockClient((request) async {
        requested = request.url;
        return http.Response('{"success":true,"data":{"guiones":[]}}', 200);
      }),
    );
    addTearDown(service.dispose);

    await service.fetch(developmentId: 22, tipoProspecto: 'reactivado');

    expect(requested.queryParameters['desarrollo_id'], '22');
    expect(requested.queryParameters['tipo_prospecto'], 'reactivado');
  });

  test('un 403 no expira la sesión', () async {
    final auth = await authenticatedAuth();
    final service = ScriptsService(
      auth: auth,
      client: MockClient(
        (_) async =>
            http.Response('{"success":false,"message":"Sin acceso"}', 403),
      ),
    );
    addTearDown(service.dispose);

    await expectLater(
      service.fetch(developmentId: 99),
      throwsA(
        isA<ScriptsException>().having(
          (error) => error.message,
          'mensaje',
          contains('acceso'),
        ),
      ),
    );
    expect(auth.isAuthenticated, isTrue);
  });
}
