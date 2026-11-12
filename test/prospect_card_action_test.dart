import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/contact_medium.dart';
import 'package:callerapp_frontend/presentation/models/prospect_action.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const prospect = ProspectRecord(
    id: 1,
    name: 'Ana Pérez',
    phone: '9991234567',
    email: 'ana@example.com',
    status: 'Nuevo',
    temperature: 'Caliente',
    avatarColor: Colors.teal,
    statusColor: Colors.cyan,
  );
  final followUp = AgendaActivity(
    id: 2,
    prospectId: 1,
    type: 'seguimiento',
    medium: 'whatsapp',
    title: 'SEGUIMIENTO',
    prospect: 'ANA',
    description: '',
    date: DateTime(2026, 11, 12),
    status: AgendaStatus.pending,
  );

  Future<void> pump(
    WidgetTester tester,
    ProspectAction action,
    ValueChanged<ContactMedium> callback, {
    ProspectRecord value = prospect,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProspectCard(
          prospect: value,
          action: action,
          onContact: (medium) async => callback(medium),
        ),
      ),
    ),
  );

  testWidgets('WhatsApp muestra una sola acción contextual', (tester) async {
    ContactMedium? received;
    await pump(
      tester,
      ProspectAction(medium: ContactMedium.whatsapp, activity: followUp),
      (value) => received = value,
    );
    expect(find.byType(IconButton), findsOneWidget);
    expect(
      find.byTooltip('Enviar WhatsApp a Ana Pérez · Seguimiento agendado'),
      findsOneWidget,
    );
    expect(find.byTooltip('Llamar a Ana Pérez'), findsNothing);
    await tester.tap(find.byType(IconButton));
    expect(received, ContactMedium.whatsapp);
  });

  testWidgets('llamada entrega el medio al callback', (tester) async {
    ContactMedium? received;
    await pump(
      tester,
      const ProspectAction(medium: ContactMedium.llamada),
      (value) => received = value,
    );
    expect(find.byTooltip('Llamar a Ana Pérez'), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    expect(received, ContactMedium.llamada);
  });

  testWidgets('WhatsApp queda deshabilitado sin teléfono', (tester) async {
    await pump(
      tester,
      const ProspectAction(medium: ContactMedium.whatsapp),
      (_) {},
      value: prospect.copyWith(phone: ''),
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
  });
}
