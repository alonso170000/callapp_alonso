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
    VoidCallback? onOptions,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProspectCard(
          prospect: value,
          action: action,
          onContact: (medium) async => callback(medium),
          onContactOptions: onOptions,
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

  testWidgets('sin actividad abre las opciones de contacto', (tester) async {
    var opened = false;
    ContactMedium? received;
    await pump(
      tester,
      const ProspectAction(medium: ContactMedium.llamada),
      (value) => received = value,
      onOptions: () => opened = true,
    );
    expect(
      find.byTooltip('Elegir medio de contacto para Ana Pérez'),
      findsOneWidget,
    );
    expect(find.byTooltip('Llamar a Ana Pérez'), findsNothing);
    await tester.tap(find.byType(IconButton));
    expect(opened, isTrue);
    expect(received, isNull);
  });

  testWidgets('Facebook con actividad queda habilitado', (tester) async {
    ContactMedium? received;
    final facebookFollowUp = AgendaActivity(
      id: 3,
      prospectId: 1,
      type: 'seguimiento',
      medium: 'facebook',
      title: 'SEGUIMIENTO',
      prospect: 'ANA',
      description: '',
      date: DateTime(2026, 11, 12),
      status: AgendaStatus.pending,
    );
    await pump(
      tester,
      ProspectAction(
        medium: ContactMedium.facebook,
        activity: facebookFollowUp,
      ),
      (value) => received = value,
    );
    expect(find.byType(IconButton), findsOneWidget);
    expect(
      find.byTooltip('Abrir Facebook a Ana Pérez · Seguimiento agendado'),
      findsOneWidget,
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNotNull,
    );
    await tester.tap(find.byType(IconButton));
    expect(received, ContactMedium.facebook);
  });

  testWidgets('WhatsApp queda deshabilitado sin teléfono', (tester) async {
    await pump(
      tester,
      ProspectAction(medium: ContactMedium.whatsapp, activity: followUp),
      (_) {},
      value: prospect.copyWith(phone: ''),
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
  });
}
