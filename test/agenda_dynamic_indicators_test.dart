import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/agenda_screen.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_activity_detail.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_month_calendar.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_week_selector.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AgendaActivity _activity(DateTime date, {String type = 'seguimiento'}) =>
    AgendaActivity(
      id: 1,
      prospectId: 17,
      type: type,
      medium: type == 'seguimiento' ? 'whatsapp' : null,
      title: type.toUpperCase(),
      prospect: 'Ana',
      description: 'Contactar al prospecto',
      date: date,
      status: AgendaStatus.pending,
    );

void main() {
  testWidgets('Week and month only mark dates with supplied activities', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(businessNow());
    final activityDate = today.add(const Duration(days: 1));
    final activities = [_activity(activityDate)];

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            AgendaWeekSelector(
              selectedDate: today,
              activities: activities,
              onSelected: (_) {},
            ),
            Expanded(
              child: AgendaMonthCalendar(
                selectedDate: today,
                activities: activities,
                onSelected: (_) {},
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.byIcon(Icons.remove_rounded), findsNothing);
    expect(
      find.byKey(
        ValueKey(
          'agenda-month-activity-${activityDate.year}-${activityDate.month}-${activityDate.day}',
        ),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('agenda-week-today')), findsOneWidget);
    expect(find.byKey(const ValueKey('agenda-month-today')), findsOneWidget);
  });

  testWidgets('Today uses a different color from the selected date', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(businessNow());
    await tester.pumpWidget(
      MaterialApp(
        home: AgendaMonthCalendar(
          selectedDate: today.add(const Duration(days: 1)),
          activities: const [],
          onSelected: (_) {},
        ),
      ),
    );

    final todayMaterial = tester.widget<Material>(
      find.byKey(const ValueKey('agenda-month-today')),
    );
    expect(todayMaterial.color, isNot(AppColors.primaryColor));
  });

  testWidgets('Follow-up detail displays its contact medium card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaActivityDetail(
            activity: _activity(businessNow()),
            onClose: () {},
            onMessage: () {},
            onCall: () {},
            onOpenProspect: () {},
            onEdit: () {},
            onComplete: () {},
            onReschedule: () {},
          ),
        ),
      ),
    );

    expect(find.text('Medio'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Canal de contacto'), findsOneWidget);
  });

  testWidgets('Completed follow-up opens the saved follow-up detail', (
    tester,
  ) async {
    var opened = false;
    final completed = _activity(businessNow())
        .copyWith(status: AgendaStatus.completed);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaActivityDetail(
            activity: completed,
            onClose: () {},
            onMessage: () {},
            onCall: () {},
            onOpenProspect: () => opened = true,
            onEdit: () => fail('Edit must be hidden'),
            onComplete: () =>
                fail('Completed follow-up must open its prospect'),
            onReschedule: () => fail('Cancel must be hidden'),
          ),
        ),
      ),
    );

    expect(find.text('VER SEGUIMIENTO'), findsOneWidget);
    expect(find.text('EDITAR'), findsNothing);
    expect(find.text('Cancelar'), findsNothing);
    await tester.tap(find.text('VER SEGUIMIENTO'));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Completed non-follow-up does not offer follow-up action', (
    tester,
  ) async {
    final completed = _activity(
      businessNow(),
    ).copyWith(type: 'tarea', title: 'TAREA', status: AgendaStatus.completed);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaActivityDetail(
            activity: completed,
            onClose: () {},
            onMessage: () {},
            onCall: () {},
            onOpenProspect: () {},
            onEdit: () {},
            onComplete: () {},
            onReschedule: () {},
          ),
        ),
      ),
    );

    expect(find.text('VER SEGUIMIENTO'), findsNothing);
  });

  testWidgets('Today button returns Agenda to the current date', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(businessNow());
    await tester.pumpWidget(
      MaterialApp(
        home: AgendaScreen(loadActivities: () async => [_activity(today)]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Periodo siguiente'));
    await tester.pump();
    expect(find.text('MOSTRANDO 0 ACTIVIDADES'), findsOneWidget);
    await tester.tap(find.byTooltip('Ir a hoy'));
    await tester.pump();
    expect(find.text('MOSTRANDO 1 ACTIVIDAD'), findsOneWidget);
  });

  testWidgets('Filter result count includes activities on other dates', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(businessNow());
    await tester.pumpWidget(
      MaterialApp(
        home: AgendaScreen(
          loadActivities: () async => [
            _activity(today),
            _activity(today.add(const Duration(days: 3))),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filtrar actividades'));
    await tester.pumpAndSettle();

    expect(find.text('VER 2 RESULTADOS'), findsOneWidget);
  });
}
