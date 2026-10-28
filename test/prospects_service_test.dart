import 'dart:convert';
import 'dart:io';

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

  test('Sends Cube ACR AMR recordings with their audio MIME type', () async {
    final client = _RecordingClient();
    final directory = await Directory.systemTemp.createTemp(
      'callerapp_audio_test_',
    );
    final audio = File(
      '${directory.path}/phone_20261028-113530_529982938140.amr',
    );
    await audio.writeAsBytes([1, 2, 3]);
    addTearDown(() => directory.delete(recursive: true));
    final service = ProspectsService(auth: await login(), client: client);
    addTearDown(service.dispose);

    await service.uploadCallAudio(12, audio.path);

    expect(client.request.url.path, '/api/v1/leads/calls/12/audio');
    expect(utf8.decode(client.body), contains('content-type: audio/amr'));
  });

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
    expect(record.assignedAt, DateTime(2026, 10, 9, 7));
  });

  test(
    'Creates a follow-up and its next activity through one endpoint',
    () async {
      final fields = {
        'estatus': 'Seguimiento',
        'prioridad': 'caliente',
        'medio': 'telefono',
        'hubo_exito': true,
        'nota': 'Contacto realizado',
        'actividad': {
          'tipo': 'seguimiento',
          'prospecto_id': 17,
          'medio': 'llamada',
          'descripcion': 'Confirmar propuesta',
          'programada_at': '2026-10-20T15:00:00.000Z',
          'recordatorio_at': '2026-10-20T14:45:00.000Z',
        },
      };
      final service = ProspectsService(
        auth: await login(),
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url.toString(),
            'https://example.com/api/v1/leads/17/follow-ups',
          );
          expect(request.headers['Idempotency-Key'], 'follow-key');
          expect(jsonDecode(request.body), fields);
          return http.Response(
            '{"success":true,"data":{"contact_id":4,"activity_id":9}}',
            201,
          );
        }),
      );
      addTearDown(service.dispose);
      await service.createFollowUp(17, fields, operationKey: 'follow-key');
    },
  );

  test(
    'Loads and saves discovery sections through the lead endpoints',
    () async {
      final requests = <http.Request>[];
      final service = ProspectsService(
        auth: await login(),
        client: MockClient((request) async {
          requests.add(request);
          expect(request.headers['Authorization'], 'Bearer session');
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'tipo_propiedad': 'casa',
                  'ubicacion': ['Quintana Roo', 'Yucatán'],
                },
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          expect(request.headers['Idempotency-Key'], 'discovery-key');
          expect(jsonDecode(request.body), {
            'seccion': 'motivadores_compra',
            'motivo_compra': ['precio', 'otro'],
            'otro_motivo_compra': 'Promoción',
          });
          return http.Response('{"success":true,"data":{"id":8}}', 200);
        }),
      );
      addTearDown(service.dispose);

      final discovery = await service.discovery(17);
      expect(discovery?['tipo_propiedad'], 'casa');
      await service.saveDiscoverySection(17, {
        'seccion': 'motivadores_compra',
        'motivo_compra': ['precio', 'otro'],
        'otro_motivo_compra': 'Promoción',
      }, operationKey: 'discovery-key');

      expect(requests, hasLength(2));
      expect(
        requests.first.url.toString(),
        'https://example.com/api/v1/leads/17/discovery',
      );
      expect(requests.last.method, 'POST');
    },
  );

  test('Maps activity identifiers from the contact history', () async {
    final service = ProspectsService(
      auth: await login(),
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/leads/17/contact-history');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 8,
                'actividad_id': 9,
                'siguiente_actividad_id': 10,
                'medio': 'whatsapp',
                'hubo_exito': true,
                'nota': 'Confirmó la información',
                'fecha_hora': '2026-10-20T15:00:00.000Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(service.dispose);

    final entry = (await service.contactHistory(17)).single;
    expect(entry.id, 8);
    expect(entry.activityId, 9);
    expect(entry.nextActivityId, 10);
  });

  test('Loads closers from the role-filtered endpoint', () async {
    final service = ProspectsService(
      auth: await login(),
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://example.com/api/v1/agents/closers',
        );
        return http.Response(
          '{"success":true,"data":[{"id":8,"nombre_completo":"Cerrador Dos","rol":"cerrador"}]}',
          200,
        );
      }),
    );
    addTearDown(service.dispose);

    final closers = await service.availableClosers();
    expect(closers.single['id'], 8);
    expect(closers.single['nombre_completo'], 'Cerrador Dos');
  });

  test(
    'Un 409 con la operación en proceso se trata como recuperable',
    () async {
      final service = ProspectsService(
        auth: await login(),
        client: MockClient(
          (_) async => http.Response(
            '{"success":false,"message":"La operación todavía está en proceso. Intenta nuevamente."}',
            409,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      addTearDown(service.dispose);

      await expectLater(
        service.update(15, {'nombre': 'Ana'}, operationKey: 'repetida'),
        throwsA(isA<ProspectsRecoverableException>()),
      );
    },
  );

  test('Un 409 con la clave reusada sigue siendo un conflicto', () async {
    final service = ProspectsService(
      auth: await login(),
      client: MockClient(
        (_) async => http.Response(
          '{"success":false,"message":"La clave de idempotencia ya fue usada con otra operación."}',
          409,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    addTearDown(service.dispose);

    await expectLater(
      service.update(15, {'nombre': 'Ana'}, operationKey: 'reusada'),
      throwsA(isA<ProspectsBusinessException>()),
    );
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

class _RecordingClient extends http.BaseClient {
  late http.BaseRequest request;
  late List<int> body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest value) async {
    request = value;
    body = await value.finalize().expand((bytes) => bytes).toList();
    return http.StreamedResponse(
      Stream.value(utf8.encode('{"success":true,"data":{}}')),
      201,
      headers: const {'content-type': 'application/json'},
    );
  }
}
