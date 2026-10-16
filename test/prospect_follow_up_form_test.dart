import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_follow_up_form.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospect_detail_screen.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingProspectsService extends ProspectsService {
  int? prospectId;
  Map<String, dynamic>? fields;

  @override
  Future<void> createFollowUp(
    int prospectId,
    Map<String, dynamic> fields,
  ) async {
    this.prospectId = prospectId;
    this.fields = fields;
  }
}

void main() {
  const prospect = ProspectRecord(
    id: 17,
    name: 'Ana real',
    phone: '',
    email: '',
    status: 'Nuevo',
    temperature: 'Caliente',
    avatarColor: Colors.teal,
    statusColor: Colors.orange,
  );

  for (final width in [320.0, 390.0]) {
    testWidgets(
      'Programs a locked follow-up activity, summarizes it and saves both at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final service = _RecordingProspectsService();
        var saved = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ProspectFollowUpForm(
                  prospect: prospect,
                  prospectsService: service,
                  loadActivities: () async => [],
                  onSaved: (_) => saved++,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Llamada telefónica'), findsNothing);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('No existe una actividad de seguimiento'),
          findsOneWidget,
        );
        final acknowledge = find.byKey(
          const ValueKey('acknowledge-follow-up-completion'),
        );
        await tester.ensureVisible(acknowledge);
        await tester.tap(acknowledge);
        await tester.pump();
        expect(
          find.byKey(const ValueKey('follow-up-activity-form')),
          findsNothing,
        );
        await tester.tap(
          find.bySemanticsLabel('¿Programar siguiente contacto?').last,
        );
        await tester.pump();
        expect(find.text('Seguimiento'), findsWidgets);
        expect(find.text(prospect.name), findsWidgets);
        expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
        expect(find.text('Seleccionar fecha'), findsNothing);
        expect(find.text('Seleccionar hora'), findsNothing);
        final activityForm = find.byKey(
          const ValueKey('follow-up-activity-form'),
        );
        final completionNotice = find.byKey(
          const ValueKey('follow-up-completion-notice'),
        );
        expect(
          tester.getTopLeft(completionNotice).dy,
          greaterThanOrEqualTo(tester.getBottomLeft(activityForm).dy),
        );

        await tester.enterText(
          find.byKey(const ValueKey('follow-up-activity-description')),
          'Confirmar propuesta',
        );
        final saveActivity = find.byKey(
          const ValueKey('save-follow-up-activity'),
        );
        await tester.ensureVisible(saveActivity);
        await tester.tap(saveActivity);
        await tester.pump();
        expect(
          find.byKey(const ValueKey('follow-up-activity-summary')),
          findsOneWidget,
        );
        expect(find.text('Confirmar propuesta'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('edit-follow-up-activity')));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('follow-up-activity-form')),
          findsOneWidget,
        );
        await tester.ensureVisible(saveActivity);
        await tester.tap(saveActivity);
        await tester.pump();

        final saveFollowUp = find.widgetWithText(FilledButton, 'GUARDAR').last;
        await tester.ensureVisible(saveFollowUp);
        await tester.tap(saveFollowUp);
        await tester.pumpAndSettle();
        expect(saved, 1);
        expect(service.prospectId, 17);
        expect(service.fields?['actividad'], isA<Map<String, dynamic>>());
        expect(service.fields?['actividad']['tipo'], 'seguimiento');
        expect(service.fields?['actividad']['prospecto_id'], 17);
        expect(
          service.fields?['actividad']['descripcion'],
          'Confirmar propuesta',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Phone call completion enables and preselects telephone method', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectDetailScreen(
          prospect: prospect,
          loadActivities: () async => [],
        ),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Llamar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finish-prospect-call')));
    await tester.pumpAndSettle();
    expect(find.text('Llamada telefónica'), findsOneWidget);
    final method = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).at(1),
    );
    expect(method.initialValue, 'Llamada telefónica');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Agenda source locks its medium, confirms completion and preserves a visit',
    (tester) async {
      final now = DateTime.now().add(const Duration(days: 1));
      final followUp = AgendaActivity(
        id: 9,
        prospectId: 17,
        type: 'seguimiento',
        medium: 'whatsapp',
        title: 'SEGUIMIENTO',
        prospect: prospect.name,
        description: 'Contactar por WhatsApp',
        date: now,
        status: AgendaStatus.pending,
      );
      final visit = AgendaActivity(
        id: 10,
        prospectId: 17,
        type: 'visita presencial',
        title: 'VISITA PRESENCIAL',
        prospect: prospect.name,
        description: 'Visitar el lote',
        date: now.add(const Duration(hours: 2)),
        status: AgendaStatus.pending,
      );
      final service = _RecordingProspectsService();
      AgendaActivity? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProspectFollowUpForm(
                prospect: prospect,
                prospectsService: service,
                sourceActivity: followUp,
                loadActivities: () async => [followUp, visit],
                onOpenActivity: (activity) => opened = activity,
                onSaved: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('actividad abierta desde Agenda'),
        findsOneWidget,
      );
      final method = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).at(1),
      );
      expect(method.initialValue, 'WhatsApp');
      expect(method.onChanged, isNull);
      final other = find.byKey(const ValueKey('other-active-activity-10'));
      await tester.ensureVisible(other);
      await tester.tap(other);
      expect(opened?.id, 10);
      final acknowledge = find.byKey(
        const ValueKey('acknowledge-follow-up-completion'),
      );
      await tester.ensureVisible(acknowledge);
      await tester.tap(acknowledge);
      final save = find.widgetWithText(FilledButton, 'GUARDAR').last;
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(service.fields?['actividad_origen_id'], 9);
      expect(service.fields?['medio'], 'whatsapp');
      expect(tester.takeException(), isNull);
    },
  );
}
