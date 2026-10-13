import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/new_agenda_activity_dialog.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    for (final type in ['Seguimiento', 'Visita presencial', 'Tarea']) {
      testWidgets(
        '$type saves validated fields with required reminder at $width',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 844);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetViewInsets);
          final auth = AuthService(
            client: MockClient(
              (_) async =>
                  http.Response('{"status":"success","token":"session"}', 200),
            ),
          );
          await auth.login('ana', 'password');
          final prospects = ProspectsService(
            auth: auth,
            client: MockClient(
              (_) async => http.Response(
                '{"success":true,"data":[{"id":17,"nombre":"Ana"}]}',
                200,
              ),
            ),
          );
          var posts = 0;
          final agenda = AgendaService(
            auth: auth,
            client: MockClient((request) async {
              expect(request.method, 'POST');
              expect(request.url.path, '/api/v1/activities');
              expect(request.headers['Authorization'], 'Bearer session');
              final body = jsonDecode(request.body) as Map;
              final scheduled = DateTime.parse(body['programada_at']).toLocal();
              expect(scheduled.isAfter(DateTime.now()), isTrue);
              expect(
                scheduled.difference(DateTime.now()),
                lessThan(const Duration(minutes: 2)),
              );
              expect(body['prospecto_id'], type == 'Tarea' ? null : 17);
              expect(
                DateTime.parse(body['programada_at'])
                    .difference(DateTime.parse(body['recordatorio_at'])),
                const Duration(minutes: 15),
              );
              expect(body.containsKey('estado'), isFalse);
              expect(body.containsKey('responsable_id'), isFalse);
              if (type == 'Seguimiento') {
                expect(body['medio'], 'llamada');
                expect(body.containsKey('ubicacion'), isFalse);
              }
              if (type == 'Visita presencial') {
                expect(body['ubicacion'], 'Lote');
                expect(body.containsKey('medio'), isFalse);
                expect(body.containsKey('descripcion'), isFalse);
              }
              if (type == 'Tarea') {
                expect(body.containsKey('medio'), isFalse);
                expect(body.containsKey('ubicacion'), isFalse);
              }
              posts++;
              if (posts == 1) {
                return http.Response(
                  '{"success":false,"message":"Revisa la actividad"}',
                  400,
                );
              }
              return http.Response('{"success":true,"data":{"id":29}}', 201);
            }),
          );
          addTearDown(prospects.dispose);
          addTearDown(agenda.dispose);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showModalBottomSheet<DateTime>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => NewAgendaActivityDialog(
                        initialDate: DateTime.now(),
                        agendaService: agenda,
                        prospectsService: prospects,
                      ),
                    ),
                    child: const Text('Abrir'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Abrir'));
          await tester.pumpAndSettle();
          if (type != 'Seguimiento') {
            await tester.tap(find.text('Seguimiento'));
            await tester.pumpAndSettle();
            await tester.tap(find.text(type).last);
            await tester.pumpAndSettle();
          }
          if (type != 'Tarea') {
            await tester.tap(find.text('Sin prospecto'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Ana').last);
            await tester.pumpAndSettle();
          }
          if (type != 'Visita presencial') {
            final description = find.byKey(
              const ValueKey('new-activity-description'),
            );
            await tester.ensureVisible(description);
            await tester.enterText(description, 'Confirmar propuesta');
          }
          tester.view.viewInsets = const FakeViewPadding(bottom: 260);
          await tester.pumpAndSettle();
          final save = find.byKey(const ValueKey('save-new-activity'));
          await tester.ensureVisible(save);
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(posts, 1);
          expect(find.byType(NewAgendaActivityDialog), findsOneWidget);
          await tester.ensureVisible(save);
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(posts, 2);
          expect(find.byType(NewAgendaActivityDialog), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
