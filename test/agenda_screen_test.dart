import 'package:callerapp_frontend/presentation/screens/main_screens/home_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/agenda_screen.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_widgets.dart';
import 'package:callerapp_frontend/presentation/widgets/home/home_card_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

void main() {
  testWidgets('Task completion requires bottom-sheet confirmation', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaScreen(
            loadActivities: () async => [
              AgendaActivity(
                type: 'tarea',
                title: 'TAREA',
                prospect: 'Ana',
                description: 'Enviar documentos',
                date: now,
                status: AgendaStatus.pending,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AgendaActivityTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('COMPLETAR ACTIVIDAD'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.text('¿Confirmas que esta actividad fue completada?'),
      findsOneWidget,
    );
    await tester.tap(find.text('SÍ, COMPLETAR'));
    await tester.pumpAndSettle();
    expect(find.byType(AgendaActivityDetail), findsNothing);
    expect(find.text('Actividad completada.'), findsOneWidget);
  });

  testWidgets('Follow-up cancellation requires confirmation', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaScreen(
            loadActivities: () async => [
              AgendaActivity(
                type: 'seguimiento',
                title: 'SEGUIMIENTO',
                prospect: 'Ana',
                description: 'Seguimiento pendiente',
                date: now,
                status: AgendaStatus.pending,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AgendaActivityTile));
    await tester.pumpAndSettle();

    expect(find.text('COMPLETAR ACTIVIDAD'), findsNothing);
    expect(find.text('EDITAR'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.text(
        '¿Seguro que deseas cancelar esta actividad? Esta acción no se puede deshacer.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('VOLVER'));
    await tester.pumpAndSettle();
    expect(find.byType(AgendaActivityDetail), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SÍ, CANCELAR'));
    await tester.pumpAndSettle();
    expect(find.byType(AgendaActivityDetail), findsNothing);
    expect(find.text('Actividad cancelada.'), findsOneWidget);
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('New activity bottom sheet handles keyboard at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      final controller = AgendaController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgendaScreen(
              controller: controller,
              loadActivities: () async =>
                  demoAgendaActivities(DateUtils.dateOnly(DateTime.now())),
            ),
          ),
        ),
      );
      controller.openNewActivity();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(tester.getBottomLeft(find.byType(BottomSheet)).dy, 844);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('new-activity-description')),
        'Nueva visita',
      );
      final save = find.byKey(const ValueKey('save-new-activity'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Selecciona un prospecto'), findsOneWidget);
      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 3 ACTIVIDADES'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('El botón para agendar solo aparece en Agenda y crea actividad', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          loadActivities: () async =>
              demoAgendaActivities(DateUtils.dateOnly(DateTime.now())),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Agendar nueva actividad'), findsNothing);

    await tester.tap(find.byIcon(Iconsax.calendar_2_copy));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Agendar nueva actividad'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Agendar nueva actividad'));
    await tester.pumpAndSettle();
    expect(find.byType(NewAgendaActivityDialog), findsOneWidget);
    expect(find.text('Nueva actividad'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('new-activity-description')),
      'Revisar documentación',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-new-activity')));
    await tester.tap(find.byKey(const ValueKey('save-new-activity')));
    await tester.pumpAndSettle();

    expect(find.byType(NewAgendaActivityDialog), findsOneWidget);
    expect(find.text('Selecciona un prospecto'), findsOneWidget);
    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle();
    expect(find.text('MOSTRANDO 3 ACTIVIDADES'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Iconsax.home_2_copy));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Agendar nueva actividad'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Month calendar includes adjacent dates and leap day', (
    tester,
  ) async {
    DateTime? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaMonthCalendar(
            selectedDate: DateTime(2028, 2, 16),
            activities: const [],
            onSelected: (date) => selected = date,
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('agenda-month-2028-1-31')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('agenda-month-2028-3-5')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('agenda-month-2028-2-29')));
    expect(selected, DateTime(2028, 2, 29));
    await tester.tap(find.byKey(const ValueKey('agenda-month-2028-3-5')));
    expect(selected, DateTime(2028, 3, 5));
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('Agenda navigation and filters at width $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            loadActivities: () async =>
                demoAgendaActivities(DateUtils.dateOnly(DateTime.now())),
          ),
        ),
      );
      await tester.tap(find.byIcon(Iconsax.calendar_2_copy));
      await tester.pumpAndSettle();
      expect(find.text('MI AGENDA'), findsOneWidget);
      expect(find.text('MOSTRANDO 3 ACTIVIDADES'), findsOneWidget);
      final statusRightEdges = [AgendaStatus.completed, AgendaStatus.overdue]
          .map(
            (status) => tester
                .getRect(find.byKey(ValueKey('agenda-status-${status.name}')))
                .right,
          )
          .toList();
      expect(statusRightEdges.toSet(), hasLength(1));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Periodo siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 0 ACTIVIDADES'), findsOneWidget);
      await tester.tap(find.byTooltip('Ir a hoy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semana'));
      await tester.pumpAndSettle();
      expect(find.byType(AgendaWeekSelector), findsOneWidget);
      final todayIndex = DateTime.now().weekday - 1;
      final otherIndex = (todayIndex + 1) % 7;
      await tester.tap(find.byKey(ValueKey('agenda-week-day-$otherIndex')));
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 0 ACTIVIDADES'), findsOneWidget);
      expect(find.text('No hay actividades para este día.'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('agenda-week-day-$todayIndex')));
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 3 ACTIVIDADES'), findsOneWidget);
      await tester.tap(find.byTooltip('Periodo siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 0 ACTIVIDADES'), findsOneWidget);
      await tester.tap(find.byTooltip('Periodo anterior'));
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 3 ACTIVIDADES'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final period in ['Semana', 'Mes', 'Día']) {
        await tester.tap(find.text(period));
        await tester.pumpAndSettle();
        expect(find.text('MOSTRANDO 3 ACTIVIDADES'), findsOneWidget);
      }
      await tester.tap(find.text('Mes'));
      await tester.pumpAndSettle();
      expect(find.byType(AgendaMonthCalendar), findsOneWidget);
      final today = DateTime.now();
      final otherDay = today.day == 1 ? 2 : 1;
      await tester.tap(
        find.byKey(
          ValueKey('agenda-month-${today.year}-${today.month}-$otherDay'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 0 ACTIVIDADES'), findsOneWidget);
      await tester.tap(
        find.byKey(
          ValueKey('agenda-month-${today.year}-${today.month}-${today.day}'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 3 ACTIVIDADES'), findsOneWidget);
      await tester.tap(find.byTooltip('Periodo siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 0 ACTIVIDADES'), findsOneWidget);
      await tester.tap(find.byTooltip('Periodo anterior'));
      await tester.pumpAndSettle();
      // Return to the exact day even if the next month was shorter.
      await tester.tap(
        find.byKey(
          ValueKey('agenda-month-${today.year}-${today.month}-${today.day}'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 3 ACTIVIDADES'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Día'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Filtrar actividades'));
      await tester.pumpAndSettle();
      for (final status in ['Atrasada', 'Completada', 'Cancelada']) {
        await tester.tap(find.widgetWithText(CheckboxListTile, status));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('VER 1 RESULTADOS'));
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 1 ACTIVIDAD'), findsOneWidget);
      expect(find.byType(AgendaActivityTile), findsOneWidget);
      await tester.tap(find.byType(AgendaActivityTile));
      await tester.pumpAndSettle();
      expect(find.byType(AgendaActivityDetail), findsOneWidget);
      expect(find.byType(AgendaActivityTile), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AgendaActivityDetail),
          matching: find.text('VISITA PRESENCIAL'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AgendaActivityDetail),
          matching: find.text('PENDIENTE'),
        ),
        findsOneWidget,
      );
      expect(find.text('Ubicación'), findsOneWidget);
      expect(find.text('LOTE'), findsOneWidget);
      expect(find.text('Recordatorio'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('minutos antes'), findsOneWidget);
      expect(find.byTooltip('Ver prospecto'), findsOneWidget);
      expect(find.byType(HomeCardArrow), findsOneWidget);
      expect(find.text('VER PROSPECTO'), findsNothing);
      // El relleno táctil mínimo de 48 px desplaza la caja visible del botón
      // pequeño 5 px hacia dentro; por eso se comparan las cajas de diseño
      // (IconButton), que son las que deben compartir el borde derecho.
      Rect actionBox(String tooltip) => tester.getRect(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        ),
      );
      expect(
        actionBox('Ver prospecto').right,
        closeTo(actionBox('Llamar al prospecto').right, 2.1),
      );
      expect(find.text('DESCRIPCIÓN'), findsOneWidget);
      final complete = find.text('COMPLETAR ACTIVIDAD');
      await tester.ensureVisible(complete);
      await tester.tap(complete);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        find.text('¿Confirmas que esta actividad fue completada?'),
        findsOneWidget,
      );
      await tester.tap(find.text('SÍ, COMPLETAR'));
      await tester.pumpAndSettle();
      expect(find.byType(AgendaActivityDetail), findsNothing);
      expect(find.text('Actividad completada.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
