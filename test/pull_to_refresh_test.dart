import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospects_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/agenda_screen.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_comments_panel.dart';
import 'package:callerapp_frontend/presentation/models/prospect_history_models.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('Prospects pull refresh retains search and status at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      var loads = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProspectsScreen(
              loadProspects: () async {
                loads++;
                return [
                  ProspectRecord(
                    id: 7,
                    name: loads == 1 ? 'Ana antes' : 'Ana después',
                    phone: '',
                    email: '',
                    status: 'Nuevo',
                    temperature: 'Caliente',
                    avatarColor: Colors.teal,
                    statusColor: Colors.blue,
                  ),
                ];
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final chip = find.widgetWithText(ChoiceChip, 'Nuevo');
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Ana');
      await tester.pumpAndSettle();
      FocusScope.of(tester.element(find.byType(TextField))).unfocus();
      tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(CustomScrollView),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.drag(find.text('MIS PROSPECTOS'), const Offset(0, 450));
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Ana',
      );
      expect(find.text('ANA DESPUÉS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'Empty agenda can retry via pull and preserves date at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        var loads = 0;
        final controller = AgendaController();
        addTearDown(controller.dispose);
        final day = DateTime.now().add(const Duration(days: 2));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AgendaScreen(
                controller: controller,
                loadActivities: () async {
                  loads++;
                  if (loads == 1) throw const AgendaException('Sin conexión');
                  if (loads == 2) return [];
                  return [
                    AgendaActivity(
                      id: 9,
                      title: 'Seguimiento actualizado',
                      type: 'seguimiento',
                      prospect: 'Ana',
                      description: 'Nota actualizada',
                      date: day,
                      status: AgendaStatus.pending,
                    ),
                  ];
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Sin conexión'), findsOneWidget);
        controller.showFromHome(day, {9}, 'Desde Inicio');
        await tester.pumpAndSettle();
        expect(find.text('MOSTRANDO 0 ACTIVIDADES'), findsOneWidget);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 450));
        await tester.pumpAndSettle();
        expect(loads, 3);
        expect(find.text('MOSTRANDO 1 ACTIVIDAD'), findsOneWidget);
        expect(find.text('Desde Inicio'), findsOneWidget);
        expect(find.text('Nota actualizada'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Refreshing comment history reloads notes without rebuilding the form',
    (tester) async {
      var loads = 0;
      final key = GlobalKey<ProspectCommentsPanelState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefreshIndicator(
              onRefresh: () => key.currentState!.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ProspectCommentsPanel(
                  key: key,
                  prospectId: 7,
                  loadComments: () async {
                    loads++;
                    return [
                      ProspectHistoryComment(
                        comment: 'Nota $loads',
                        createdAt: DateTime(2026),
                        results: [],
                      ),
                    ];
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 450),
      );
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect(find.text('Nota 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
