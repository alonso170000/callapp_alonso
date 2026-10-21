import 'dart:convert';

import 'package:callerapp_frontend/data/local/prospects_cache.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/prospect_assignment_controller.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('consulta al arrancar y deja de hacerlo al detenerse', (
    tester,
  ) async {
    final auth = await _auth(userId: 4, developmentId: 8);
    final service = _CountingProspectsService();
    final controller = ProspectAssignmentController(
      repository: ProspectsRepository(
        auth: auth,
        cache: _FakeCache(),
        service: service,
      ),
      auth: auth,
      interval: const Duration(seconds: 30),
    );
    addTearDown(controller.dispose);

    controller.start();
    await tester.pump();
    expect(service.requests, 1);

    await tester.pump(const Duration(seconds: 31));
    expect(service.requests, 2);

    controller.dispose();
    await tester.pump(const Duration(minutes: 1));
    expect(service.requests, 2);
  });

  test('no consulta si la sesión no tiene usuario o desarrollo', () async {
    final service = _CountingProspectsService();
    final auth = AuthService(baseUrl: 'https://example.com');
    final controller = ProspectAssignmentController(
      repository: ProspectsRepository(
        auth: auth,
        cache: _FakeCache(),
        service: service,
      ),
      auth: auth,
    );
    addTearDown(controller.dispose);

    await controller.check();

    expect(service.requests, 0);
    expect(controller.lastError, isNull);
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

class _CountingProspectsService extends ProspectsService {
  int requests = 0;

  @override
  Future<List<ProspectRecord>> fetch() async {
    requests++;
    return [
      ProspectRecord(
        id: 1,
        name: 'Prospecto asignado',
        phone: '9980000001',
        email: '',
        status: 'Nuevo',
        temperature: 'Tibio',
        avatarColor: Colors.teal,
        statusColor: Colors.green,
        assignedAt: DateTime.now(),
      ),
    ];
  }

  @override
  void dispose() {}
}

class _FakeCache extends ProspectsCache {
  @override
  Future<List<ProspectRecord>> read(ProspectCacheScope scope) async => const [];

  @override
  Future<void> replace(
    ProspectCacheScope scope,
    List<ProspectRecord> prospects,
  ) async {}
}
