import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_history_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_follow_up_form.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospect_detail_screen.dart';
import 'package:callerapp_frontend/services/phone_call_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingProspectsService extends ProspectsService {
  int? prospectId;
  Map<String, dynamic>? fields;

  @override
  Future<void> createFollowUp(
    int prospectId,
    Map<String, dynamic> fields, {
    String? operationKey,
  }) async {
    this.prospectId = prospectId;
    this.fields = fields;
  }

  @override
  Future<List<ProspectHistoryComment>> contactHistory(int id) async => const [];
}

void main() {
  const prospect = ProspectRecord(
    id: 17,
    name: 'Ana real',
    phone: '9981234567',
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
    Uri? dialedUri;
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectDetailScreen(
          prospect: prospect,
          loadActivities: () async => [],
          phoneCallService: PhoneCallService(
            canLaunch: (_) async => true,
            launch: (uri) async {
              dialedUri = uri;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Llamar'));
    await tester.pumpAndSettle();
    expect(dialedUri, Uri(scheme: 'tel', path: '9981234567'));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    final finishCall = find.byKey(const ValueKey('finish-prospect-call'));
    await tester.ensureVisible(finishCall);
    await tester.tap(finishCall);
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
                telephoneCallCompleted: true,
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
      final detail = find.byKey(
        const ValueKey('open-follow-up-completion-activity'),
      );
      await tester.ensureVisible(detail);
      await tester.tap(detail);
      expect(opened?.id, 9);
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

  testWidgets(
    'Agenda follow-up disables save and requests a call before registering',
    (tester) async {
      final followUp = AgendaActivity(
        id: 19,
        prospectId: 17,
        type: 'seguimiento',
        medium: 'llamada',
        title: 'SEGUIMIENTO',
        prospect: prospect.name,
        description: 'Realizar llamada',
        date: DateTime.now().add(const Duration(hours: 1)),
        status: AgendaStatus.pending,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProspectFollowUpForm(
                prospect: prospect,
                sourceActivity: followUp,
                loadActivities: () async => [followUp],
                onSaved: (_) => fail('Must remain blocked before the call'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'GUARDAR').last,
      );
      expect(save.onPressed, isNull);
      final saveArea = find.byKey(const ValueKey('follow-up-save-area'));
      await tester.ensureVisible(saveArea);
      await tester.tap(saveArea);
      await tester.pump();
      expect(find.text('Primero debes realizar una llamada.'), findsOneWidget);
    },
  );

  testWidgets('Completed follow-up keeps the original form style read-only', (
    tester,
  ) async {
    final completed = AgendaActivity(
      id: 24,
      prospectId: 17,
      type: 'seguimiento',
      medium: 'whatsapp',
      title: 'SEGUIMIENTO',
      prospect: prospect.name,
      description: 'Confirmar propuesta',
      date: DateTime(2026, 10, 20, 10),
      status: AgendaStatus.completed,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProspectFollowUpForm(
              prospect: prospect,
              prospectsService: _RecordingProspectsService(),
              sourceActivity: completed,
              readOnly: true,
              onSaved: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acerca del seguimiento'), findsOneWidget);
    expect(find.text('GUARDAR'), findsNothing);
    expect(find.text('CANCELAR'), findsNothing);
    final status = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).first,
    );
    expect(status.onChanged, isNull);
    expect(
      tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(DropdownButtonFormField<String>).first,
              matching: find.text('Nuevo'),
            ),
          )
          .any((text) => text.style?.color == AppColors.prospectFormFieldText),
      isTrue,
    );
  });
}
