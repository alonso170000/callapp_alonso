import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';

void main() {
  Future<AuthService> auth() async {
    final auth = AuthService(
      baseUrl: 'https://example.com',
      client: MockClient(
        (_) async =>
            http.Response('{"status":"success","token":"session"}', 200),
      ),
    );
    await auth.login('ana', 'password');
    return auth;
  }

  test(
    'Delete uses authenticated endpoint and reports expired window',
    () async {
      var expired = false;
      final service = AgendaService(
        auth: await auth(),
        client: MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.path, '/api/v1/activities/9');
          expect(request.headers['Authorization'], 'Bearer session');
          return expired
              ? http.Response(
                  '{"success":false,"message":"Plazo vencido"}',
                  409,
                )
              : http.Response('{"success":true}', 200);
        }),
      );
      addTearDown(service.dispose);
      await service.delete(9);
      expired = true;
      await expectLater(
        service.delete(9),
        throwsA(
          isA<AgendaException>().having(
            (e) => e.message,
            'message',
            'Plazo vencido',
          ),
        ),
      );
    },
  );
  test(
    'Deletion deadline uses server creation time instead of device clock',
    () {
      final now = DateTime(2026, 10, 14, 14);
      final activity = AgendaService.fromJson({
        'id': 9,
        'tipo': 'seguimiento',
        'estado': 'pendiente',
        'programada_at': '2026-10-14T22:00:00Z',
        'created_at': '2026-10-14T20:00:00Z',
        'server_now': '2026-10-14T20:04:00Z',
        'puede_eliminar': 1,
      }, now: now);
      expect(activity.deleteUntil, now.add(const Duration(minutes: 1)));
      expect(activity.copyWith().deleteUntil, activity.deleteUntil);
    },
  );
  test(
    'History reads notes and actual media with no fabricated contact outcomes',
    () async {
      final service = ProspectsService(
        auth: await auth(),
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/leads/17/contact-history');
          expect(request.headers['Authorization'], 'Bearer session');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'nota': 'Nota real',
                  'medio': 'correo',
                  'fecha_hora': '2026-10-14T15:23:00Z',
                },
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(service.dispose);
      final comments = await service.contactHistory(17);
      expect(comments.single.comment, 'Nota real');
      expect(comments.single.medium, 'correo');
      expect(comments.single.results, isEmpty);
      expect(
        comments.single.createdAt.toUtc(),
        DateTime.parse('2026-10-14T15:23:00Z'),
      );
    },
  );
}
