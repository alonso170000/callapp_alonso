import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_activity_tile.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProspectRecord prospect(String type) => ProspectRecord(
    id: 1,
    name: 'Ana',
    phone: '9980000000',
    email: 'ana@example.com',
    status: 'Nuevo',
    temperature: 'Tibio',
    avatarColor: Colors.teal,
    statusColor: Colors.blue,
    tipoProspecto: type,
  );

  testWidgets('la tarjeta muestra etiqueta solo para reactivación', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ProspectCard(prospect: prospect('Reactivación'))),
    );
    expect(find.text('REACTIVACIÓN'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: ProspectCard(prospect: prospect('regular'))),
    );
    expect(find.text('REACTIVACIÓN'), findsNothing);
  });

  testWidgets('agenda exige prospecto asociado para mostrar la etiqueta', (
    tester,
  ) async {
    AgendaActivity activity(int? prospectId) => AgendaActivity(
      prospectId: prospectId,
      tipoProspecto: 'reactivados',
      title: 'SEGUIMIENTO',
      prospect: prospectId == null ? 'Actividad personal' : 'Ana',
      description: 'Descripción',
      date: DateTime(2026, 11, 11, 10),
      status: AgendaStatus.pending,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaActivityTile(activity: activity(1), onTap: () {}),
        ),
      ),
    );
    expect(find.text('REACTIVACIÓN'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaActivityTile(activity: activity(null), onTap: () {}),
        ),
      ),
    );
    expect(find.text('REACTIVACIÓN'), findsNothing);
  });
}
