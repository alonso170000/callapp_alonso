import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospects_screen.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_card.dart';

void main() {
  Future<AuthService> login() async {
    final auth = AuthService(
      baseUrl: 'https://example.com',
      client: MockClient(
        (_) async =>
            http.Response('{"status":"success","token":"session"}', 200),
      ),
    );
    await auth.login('agente', 'password');
    return auth;
  }

  test('Uses existing GET endpoint without added parameters and maps its exact response', () async {
    final service = ProspectsService(
      auth: await login(),
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'https://example.com/api/v1/leads');
        expect(request.headers['Authorization'], 'Bearer session');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 15,
                'nombre': 'Ana',
                'ciudad': 'Cancún',
                'estatus': 'Nuevo',
                'canal': 'Facebook',
                'avatar_url': '/static/avatars/ana.png',
                'fecha_asignacion': '2026-10-09T12:00:00Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(service.dispose);
    final record = (await service.fetch()).single;
    expect(record.id, 15);
    expect(record.city, 'Cancún');
    expect(record.avatarUrl, 'https://example.com/static/avatars/ana.png');
    expect(record.phone, isEmpty);
    expect(record.email, isEmpty);
    expect(record.temperature, 'Sin calificar');
    expect(record.nextContact, isNull);
    expect(record.assignedAt, isNotNull);
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('Extended API card shows actual follow-up at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.now();
      final last = DateTime(now.year, now.month, now.day - 2, 10);
      final next = DateTime(now.year, now.month, now.day + 1, 14, 30);
      final service = ProspectsService(
        auth: await login(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 16,
                  'nombre': 'Luis Antonio',
                  'estatus': 'Cotización',
                  'telefono_normalizado': '529980000001',
                  'correo': 'luis@example.com',
                  'prioridad': 'caliente',
                  'comentario': 'Llamada de seguimiento pendiente.',
                  'ultima_llamada_at': last.toUtc().toIso8601String(),
                  'proximo_contacto_at': next.toUtc().toIso8601String(),
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      addTearDown(service.dispose);
      final record = (await service.fetch()).single;
      expect(record.phone, '529980000001');
      expect(record.email, 'luis@example.com');
      expect(record.nextContact, next);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ProspectCard(prospect: record),
            ),
          ),
        ),
      );
      expect(find.text('Llamada · Hace 2 días'), findsOneWidget);
      expect(find.text('COTIZACIÓN'), findsOneWidget);
      expect(find.text('CALIENTE'), findsOneWidget);
      expect(find.text('Llamada de seguimiento pendiente.'), findsOneWidget);
      expect(find.text('02:30 PM'), findsOneWidget);
      await tester.tap(find.byTooltip('Llamar a Luis Antonio'));
      await tester.pumpAndSettle();
      expect(find.text('529980000001'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('Empty response stays empty', () async {
    final service = ProspectsService(
      auth: await login(),
      client: MockClient(
        (_) async => http.Response('{"success":true,"data":[]}', 200),
      ),
    );
    addTearDown(service.dispose);
    expect(await service.fetch(), isEmpty);
  });

  for (final code in [401, 403, 500]) {
    test('Handles HTTP $code', () async {
      final service = ProspectsService(
        auth: await login(),
        client: MockClient((_) async => http.Response('{}', code)),
      );
      addTearDown(service.dispose);
      await expectLater(service.fetch(), throwsA(isA<ProspectsException>()));
    });
  }

  for (final width in [320.0, 390.0]) {
    testWidgets('Retries failed load at $width without demo fallback', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProspectsScreen(
              loadProspects: () async {
                if (++calls == 1) {
                  throw const ProspectsException('Error de conexión');
                }
                return [];
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Error de conexión'), findsOneWidget);
      expect(find.text('BETSUA'), findsNothing);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('No se encontraron prospectos'), findsOneWidget);
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    });
  }
}
