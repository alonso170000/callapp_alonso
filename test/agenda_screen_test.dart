import 'package:callerapp_frontend/presentation/screens/main_screens/home_screen.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

void main() {
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
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.tap(find.byIcon(Iconsax.calendar_2_copy));
      await tester.pumpAndSettle();
      expect(find.text('MI AGENDA'), findsOneWidget);
      expect(find.text('MOSTRANDO 3 ACTIVIDADES'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Periodo siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 0 ACTIVIDADES'), findsOneWidget);
      await tester.tap(find.text('Volver a hoy'));
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
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'PENDIENTE'));
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 1 ACTIVIDAD'), findsOneWidget);
      expect(find.byType(AgendaActivityTile), findsOneWidget);
      await tester.tap(find.byType(AgendaActivityTile));
      await tester.pumpAndSettle();
      expect(find.text('Estado: PENDIENTE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
