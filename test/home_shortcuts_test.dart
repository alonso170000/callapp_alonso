import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/home_screen.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/home/metric_summary_card.dart';
import 'package:callerapp_frontend/presentation/widgets/home/prospect_section.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_card.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_week_selector.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_activity_detail.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'Home shortcuts preserve selected date and exact results at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final now = DateTime.now();
        final selected = DateTime(
          now.year,
          now.month,
          now.day + (now.weekday == 1 ? 1 : -1),
        );
        ProspectRecord prospect(int id, String status, DateTime assigned) =>
            ProspectRecord(
              id: id,
              name: 'Persona $id',
              phone: '998000000$id',
              email: '',
              status: status,
              temperature: 'Caliente',
              assignedAt: assigned,
              avatarColor: Colors.teal,
              statusColor: Colors.orange,
            );
        AgendaActivity activity(
          int id,
          int prospectId,
          DateTime date,
          AgendaStatus status, {
          String medium = 'llamada',
        }) => AgendaActivity(
          id: id,
          prospectId: prospectId,
          type: 'seguimiento',
          medium: medium,
          title: 'Actividad $id',
          prospect: 'Persona $prospectId',
          description: 'Detalle $id',
          date: date,
          status: status,
        );
        final records = [
          prospect(1, 'Nuevo', selected),
          prospect(2, 'Seguimiento', now),
          prospect(3, 'Nuevo', now),
        ];
        final activities = [
          activity(
            11,
            1,
            selected.add(const Duration(hours: 9)),
            AgendaStatus.completed,
          ),
          activity(
            12,
            2,
            selected.add(const Duration(hours: 10)),
            AgendaStatus.pending,
          ),
          activity(13, 3, now, AgendaStatus.completed),
          activity(
            14,
            3,
            selected.add(const Duration(hours: 11)),
            AgendaStatus.pending,
            medium: 'whatsapp',
          ),
        ];
        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(
              loadActivities: () async => activities,
              loadProspects: () async => records,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final date = find.descendant(
          of: find.byType(AgendaWeekSelector),
          matching: find.text('${selected.day}'),
        );
        await tester.ensureVisible(date);
        await tester.tap(date);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<AgendaWeekSelector>(find.byType(AgendaWeekSelector))
              .selectedDate,
          selected,
        );
        final todaySection = tester
            .widgetList<ProspectSection>(find.byType(ProspectSection))
            .firstWhere((section) => section.title == 'Prospectos del día');
        todaySection.onProspect!(0);
        await tester.pumpAndSettle();
        expect(find.byType(AgendaActivityDetail), findsOneWidget);
        expect(find.text('Actividad 11'), findsWidgets);
        Navigator.pop(tester.element(find.byType(AgendaActivityDetail)));
        await tester.pumpAndSettle();
        expect(find.text('Prospectos del día'), findsOneWidget);
        for (var metric = 0; metric < 2; metric++) {
          final cards = tester
              .widgetList<MetricSummaryCard>(find.byType(MetricSummaryCard))
              .toList();
          expect(cards[metric].metric.value, 1);
          cards[metric].onTap!();
          await tester.pumpAndSettle();
          expect(find.text('MOSTRANDO 1 ACTIVIDAD'), findsOneWidget);
          expect(
            find.text(
              metric == 0
                  ? 'Seguimientos realizados'
                  : 'Seguimientos pendientes',
            ),
            findsOneWidget,
          );
          expect(
            find.text('Actividad ${metric == 0 ? 11 : 12}'),
            findsOneWidget,
          );
          await tester.tap(find.bySemanticsLabel('Inicio').last);
          await tester.pumpAndSettle();
        }
        // Each prospect section opens precisely its own set and exposes a removable filter.
        for (final title in [
          'Prospectos del día',
          'Prospectos nuevos',
          'Seguimientos atrasados',
        ]) {
          await tester.scrollUntilVisible(
            find.text(title),
            180,
            scrollable: find.byType(Scrollable).first,
          );
          final section = tester
              .widgetList<ProspectSection>(find.byType(ProspectSection))
              .firstWhere((section) => section.title == title);
          final expected = section.prospects.map((p) => p.name).toSet();
          section.onOpen!();
          await tester.pumpAndSettle();
          final shown = tester
              .widgetList<ProspectCard>(find.byType(ProspectCard))
              .map((card) => card.prospect.name)
              .toSet();
          expect(expected.containsAll(shown), isTrue);
          expect(
            find.text('MOSTRANDO ${expected.length} PROSPECTOS'),
            findsOneWidget,
          );
          final chip = tester.widget<InputChip>(find.byType(InputChip).first);
          expect(chip.onDeleted, isNotNull);
          chip.onDeleted!();
          await tester.pumpAndSettle();
          expect(find.text('MOSTRANDO 3 PROSPECTOS'), findsOneWidget);
          await tester.tap(find.bySemanticsLabel('Inicio').last);
          await tester.pumpAndSettle();
        }
        await tester.scrollUntilVisible(
          find.byTooltip('Semana siguiente'),
          -180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.byTooltip('Semana siguiente'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Semana siguiente'));
        await tester.pumpAndSettle();
        final emptyMetric = tester
            .widgetList<MetricSummaryCard>(find.byType(MetricSummaryCard))
            .first;
        expect(emptyMetric.metric.value, 0);
        emptyMetric.onTap!();
        await tester.pumpAndSettle();
        expect(find.text('MOSTRANDO 0 ACTIVIDADES'), findsOneWidget);
        expect(find.text('Seguimientos realizados'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('A new prospect opens its prospect detail route', (tester) async {
    final prospect = ProspectRecord(
      id: 7,
      name: 'Prospecto nuevo',
      phone: '9980000007',
      email: '',
      status: 'Nuevo',
      temperature: 'Tibio',
      avatarColor: Colors.teal,
      statusColor: Colors.orange,
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => HomeScreen(
            loadActivities: () async => const [],
            loadProspects: () async => [prospect],
          ),
        ),
        GoRoute(
          path: '/prospectos/:phone',
          builder: (_, state) =>
              Text('Detalle ${state.pathParameters['phone']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Prospectos nuevos'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    final section = tester
        .widgetList<ProspectSection>(find.byType(ProspectSection))
        .firstWhere((section) => section.title == 'Prospectos nuevos');
    section.onProspect!(0);
    await tester.pumpAndSettle();

    expect(find.text('Detalle 9980000007'), findsOneWidget);
  });
}
