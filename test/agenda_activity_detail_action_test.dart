import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/contact_medium.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_activity_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const prospect = ProspectRecord(
    id: 5,
    name: 'Ana Pérez',
    phone: '9991234567',
    email: 'ana@example.com',
    status: 'Nuevo',
    temperature: 'Caliente',
    avatarColor: Colors.teal,
    statusColor: Colors.cyan,
  );

  AgendaActivity activity(String medium) => AgendaActivity(
    id: 9,
    prospectId: 5,
    type: 'seguimiento',
    medium: medium,
    title: 'SEGUIMIENTO',
    prospect: 'Ana Pérez',
    description: '',
    date: DateTime(2026, 11, 12),
    status: AgendaStatus.pending,
  );

  Future<void> pump(
    WidgetTester tester,
    String medium,
    ValueChanged<ContactMedium> onContact, {
    ProspectRecord value = prospect,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaActivityDetail(
            activity: activity(medium),
            loadProspects: () async => [value],
            onClose: () {},
            onMessage: () {},
            onCall: () {},
            onContact: onContact,
            onOpenProspect: () {},
            onEdit: () {},
            onComplete: () {},
            onReschedule: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra solo la acción WhatsApp del seguimiento', (
    tester,
  ) async {
    ContactMedium? received;
    await pump(tester, 'whatsapp', (value) => received = value);
    final action = find.byTooltip(
      'Enviar WhatsApp a Ana Pérez · Seguimiento agendado',
    );
    expect(action, findsOneWidget);
    expect(find.byTooltip('Llamar a Ana Pérez'), findsNothing);
    await tester.tap(action);
    expect(received, ContactMedium.whatsapp);
  });

  testWidgets('muestra la acción telefónica asignada', (tester) async {
    ContactMedium? received;
    await pump(tester, 'telefono', (value) => received = value);
    final action = find.byTooltip('Llamar a Ana Pérez · Seguimiento agendado');
    expect(action, findsOneWidget);
    expect(find.byTooltip('Enviar WhatsApp a Ana Pérez'), findsNothing);
    await tester.tap(action);
    expect(received, ContactMedium.llamada);
  });

  testWidgets('Facebook con actividad queda habilitado', (tester) async {
    ContactMedium? received;
    await pump(tester, 'facebook', (value) => received = value);
    final action = find.byTooltip(
      'Abrir Facebook a Ana Pérez · Seguimiento agendado',
    );
    expect(action, findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(of: action, matching: find.byType(IconButton)),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(action);
    expect(received, ContactMedium.facebook);
  });

  testWidgets('deshabilita WhatsApp cuando falta teléfono', (tester) async {
    await pump(tester, 'whatsapp', (_) {}, value: prospect.copyWith(phone: ''));
    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(
          'Enviar WhatsApp a Ana Pérez · Seguimiento agendado',
        ),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNull);
  });
}
