import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_activity_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el detalle no muestra el icono del medio de contacto', (
    tester,
  ) async {
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
    final activity = AgendaActivity(
      id: 9,
      prospectId: 5,
      type: 'seguimiento',
      medium: 'whatsapp',
      title: 'SEGUIMIENTO',
      prospect: 'Ana Pérez',
      description: '',
      date: DateTime(2026, 11, 12),
      status: AgendaStatus.pending,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaActivityDetail(
            activity: activity,
            loadProspects: () async => [prospect],
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
    await tester.pumpAndSettle();

    expect(find.byTooltip('Enviar WhatsApp a Ana Pérez'), findsNothing);
    expect(find.byTooltip('Ver prospecto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
