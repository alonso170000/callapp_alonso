import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
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
                  onSaved: (_) => saved++,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Llamada telefónica'), findsNothing);
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
      const MaterialApp(home: ProspectDetailScreen(prospect: prospect)),
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
}
