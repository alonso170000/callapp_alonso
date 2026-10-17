import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/agenda_filters.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/agenda_screen.dart';

void main() {
  test(
    '17:00 Cancun stays pending before 17:00 regardless of reminder time',
    () {
      final data = {
        'id': 7,
        'tipo': 'seguimiento',
        'medio': 'llamada',
        'estado': 'pendiente',
        'programada_at': '2026-10-13T22:00:00.000Z',
        'recordatorio_at': '2026-10-13T21:00:00.000Z',
      };
      final before = DateTime.parse('2026-10-13T16:59:00-05:00');
      final activity = AgendaService.fromJson(data, now: before);
      expect(activity.status, AgendaStatus.pending);
      expect(activity.date, DateTime(2026, 10, 13, 17));
      expect(
        AgendaService.fromJson(
          data,
          now: DateTime.parse('2026-10-13T17:01:00-05:00'),
        ).status,
        AgendaStatus.overdue,
      );
    },
  );
  test('Uses API server time to derive pending activity status', () {
    final activity = AgendaService.fromJson({
      'id': 9,
      'tipo': 'seguimiento',
      'estado': 'pendiente',
      'programada_at': '2026-10-16T22:00:00.000Z',
      'server_now': '2026-10-16T17:30:00.000Z',
    }, now: DateTime.parse('2026-10-17T01:00:00.000Z'));

    expect(activity.status, AgendaStatus.pending);
  });
  test('Maps the activity completion timestamp to Cancun time', () {
    final activity = AgendaService.fromJson({
      'id': 10,
      'tipo': 'seguimiento',
      'estado': 'completada',
      'programada_at': '2026-10-17T15:00:00.000Z',
      'completada_at': '2026-10-17T16:30:00.000Z',
    }, now: DateTime(2026, 10, 17, 12));

    expect(activity.completedAt, DateTime(2026, 10, 17, 11, 30));
    expect(activity.copyWith().completedAt, activity.completedAt);
  });
  final now = DateTime(2026, 10, 12, 12);
  Map<String, dynamic> row(String state, DateTime date) => {
    'id': 8,
    'prospecto_id': 7,
    'tipo': 'llamada',
    'titulo': 'Revisar propuesta',
    'estado': state,
    'programada_at': date.toUtc().toIso8601String(),
    'prospecto_nombre': 'Ana',
    'descripcion': 'Confirmar visita',
  };
  test('Maps status, date, actual title and filter type without fabricated metadata', () {
    for (final entry in {
      'completada': AgendaStatus.completed,
      'cancelada': AgendaStatus.cancelled,
      'pendiente': AgendaStatus.overdue,
    }.entries) {
      final activity = AgendaService.fromJson(
        row(entry.key, now.subtract(const Duration(hours: 1))),
        now: now,
      );
      expect(activity.status, entry.value);
      expect(activity.id, 8);
      expect(activity.title, 'Revisar propuesta');
      expect(activity.date, now.subtract(const Duration(hours: 1)));
      expect(activity.hasReminder, isFalse);
      expect(
        AgendaFilters(selectedTypes: {'Llamada'}).matches(activity),
        isTrue,
      );
    }
    final activity = AgendaService.fromJson(
      row('pendiente', now.add(const Duration(hours: 1))),
      now: now,
    );
    expect(activity.status, AgendaStatus.pending);
    expect(activity.copyWith(status: AgendaStatus.completed).id, 8);
  });
  test('Authenticated endpoint fetch and empty response', () async {
    final auth = AuthService(
      baseUrl: 'https://example.com',
      client: MockClient(
        (_) async =>
            http.Response('{"status":"success","token":"session"}', 200),
      ),
    );
    await auth.login('ana', 'password');
    var empty = false;
    final service = AgendaService(
      auth: auth,
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/activities');
        expect(request.headers['Authorization'], 'Bearer session');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': empty ? [] : [row('pendiente', now)],
          }),
          200,
        );
      }),
    );
    addTearDown(service.dispose);
    expect((await service.fetch()).single.prospect, 'Ana');
    empty = true;
    expect(await service.fetch(), isEmpty);
  });
  for (final status in [401, 404, 500]) {
    test(
      'HTTP $status has a distinct diagnostic even with HTML body',
      () async {
        final auth = AuthService(
          client: MockClient(
            (_) async =>
                http.Response('{"status":"success","token":"session"}', 200),
          ),
        );
        await auth.login('ana', 'password');
        final service = AgendaService(
          auth: auth,
          client: MockClient(
            (_) async => http.Response('<html>Error</html>', status),
          ),
        );
        addTearDown(service.dispose);
        await expectLater(
          service.fetch(),
          throwsA(
            isA<AgendaException>().having(
              (error) => error.message,
              'message',
              contains(switch (status) {
                401 => 'sesión expiró',
                404 => 'despliegue',
                _ => 'HTTP 500',
              }),
            ),
          ),
        );
      },
    );
  }
  for (final width in [320.0, 390.0]) {
    testWidgets('Agenda retries and displays API activities at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final today = DateTime.now();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgendaScreen(
              loadActivities: () async {
                if (++calls == 1) {
                  throw const AgendaException('Error de conexión');
                }
                return [
                  AgendaService.fromJson({
                    ...row(
                      'pendiente',
                      DateTime(today.year, today.month, today.day, 23, 59),
                    ),
                    'tipo': 'seguimiento',
                    'medio': 'llamada',
                  }, now: today),
                ];
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Error de conexión'), findsOneWidget);
      expect(find.text('ALAN DORANTES'), findsNothing);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 1 ACTIVIDAD'), findsOneWidget);
      final activity = find.text('Revisar propuesta');
      await tester.scrollUntilVisible(
        activity,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(activity, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
