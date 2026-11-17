import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospect_detail_screen.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_prospect_selector.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/new_agenda_activity_dialog.dart';
import 'package:callerapp_frontend/repositories/agenda_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final prospect = demoProspects[2].copyWith(id: 17);

  testWidgets(
    'sin seguimiento abre actividad con tipo y prospecto bloqueados',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final repository = _FakeAgendaRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ProspectDetailScreen(
            prospect: prospect,
            agendaRepository: repository,
            loadActivities: () async => const [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin agendar'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('next-contact-time-indicator')),
        findsNothing,
      );
      final nextIndicator = find.byKey(
        const ValueKey('schedule-follow-up-indicator'),
      );
      final assignmentIndicator = find.byKey(
        const ValueKey('assignment-date-indicator'),
      );
      final saleIndicator = find.byKey(const ValueKey('sale-indicator'));
      expect(
        tester.getTopLeft(nextIndicator).dy,
        tester.getTopLeft(assignmentIndicator).dy,
      );
      expect(
        tester.getTopLeft(assignmentIndicator).dy,
        tester.getTopLeft(saleIndicator).dy,
      );
      expect(
        tester.getSize(nextIndicator).height,
        tester.getSize(assignmentIndicator).height,
      );
      expect(
        tester.getSize(assignmentIndicator).height,
        tester.getSize(saleIndicator).height,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.byKey(const ValueKey('schedule-follow-up-indicator')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NewAgendaActivityDialog), findsOneWidget);
      final typeField = find.descendant(
        of: find.byKey(const ValueKey('activity-type-field')),
        matching: find.byType(DropdownButtonFormField<String>),
      );
      expect(
        tester.widget<DropdownButtonFormField<String>>(typeField).onChanged,
        isNull,
      );
      final selector = tester.widget<AgendaProspectSelector<int>>(
        find.byKey(const ValueKey('new-activity-prospect-selector')),
      );
      expect(selector.value, prospect.id);
      expect(selector.enabled, isFalse);
      expect(find.text(prospect.name), findsWidgets);
      expect(tester.takeException(), isNull);

      final description = find.byKey(
        const ValueKey('new-activity-description'),
      );
      await tester.ensureVisible(description);
      await tester.enterText(description, 'Confirmar propuesta');
      final save = find.byKey(const ValueKey('save-new-activity'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.byType(NewAgendaActivityDialog), findsNothing);
      expect(find.text('Seguimiento agendado.'), findsOneWidget);
      expect(find.text('Sin agendar'), findsNothing);
      expect(
        find.byKey(const ValueKey('next-contact-time-indicator')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('schedule-follow-up-indicator')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.byType(NewAgendaActivityDialog), findsNothing);
    },
  );

  testWidgets('con seguimiento pendiente el indicador no abre el formulario', (
    tester,
  ) async {
    final activity = AgendaActivity(
      id: 8,
      prospectId: prospect.id,
      type: 'seguimiento',
      title: 'SEGUIMIENTO',
      prospect: prospect.name,
      description: 'Confirmar propuesta',
      date: DateTime(2026, 11, 20, 10),
      status: AgendaStatus.pending,
      medium: 'llamada',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProspectDetailScreen(
          prospect: prospect.copyWith(nextContact: activity.date),
          sourceActivity: activity,
          agendaRepository: _FakeAgendaRepository(),
          loadActivities: () async => [activity],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nextIndicator = find.byKey(
      const ValueKey('schedule-follow-up-indicator'),
    );
    final timeIndicator = find.byKey(
      const ValueKey('next-contact-time-indicator'),
    );
    final assignmentIndicator = find.byKey(
      const ValueKey('assignment-date-indicator'),
    );
    final saleIndicator = find.byKey(const ValueKey('sale-indicator'));
    expect(timeIndicator, findsOneWidget);
    expect(find.text('Sin\nventa'), findsOneWidget);
    expect(
      tester.getTopLeft(timeIndicator).dy,
      tester.getTopLeft(nextIndicator).dy,
    );
    for (final indicator in [assignmentIndicator, saleIndicator]) {
      expect(
        tester.getTopLeft(indicator).dy,
        tester.getTopLeft(nextIndicator).dy,
      );
      expect(
        tester.getSize(indicator).height,
        tester.getSize(nextIndicator).height,
      );
    }
    await tester.tap(
      find.byKey(const ValueKey('schedule-follow-up-indicator')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.byType(NewAgendaActivityDialog), findsNothing);
  });
}

class _FakeAgendaRepository extends AgendaRepository {
  @override
  Future<AgendaMutationResult> create(
    Map<String, dynamic> fields, {
    required AgendaActivity optimisticActivity,
  }) async => AgendaMutationResult(
    AgendaMutationState.saved,
    activity: optimisticActivity.copyWith(id: 99),
  );
}
