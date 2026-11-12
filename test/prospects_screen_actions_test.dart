import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospects_screen.dart';
import 'package:callerapp_frontend/repositories/agenda_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const prospect = ProspectRecord(
    id: 10,
    name: 'Ana Pérez',
    phone: '9991234567',
    email: 'ana@example.com',
    status: 'Nuevo',
    temperature: 'Caliente',
    avatarColor: Colors.teal,
    statusColor: Colors.cyan,
  );

  AgendaActivity followUp(String medium) => AgendaActivity(
    id: 4,
    prospectId: 10,
    type: 'seguimiento',
    medium: medium,
    title: 'SEGUIMIENTO',
    prospect: 'ANA PÉREZ',
    description: '',
    date: DateTime(2026, 11, 12, 10),
    status: AgendaStatus.pending,
  );

  Future<void> pump(
    WidgetTester tester,
    List<AgendaActivity> activities,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectsScreen(
            loadProspects: () async => [prospect],
            agendaRepository: _FakeAgendaRepository(activities),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('seguimiento WhatsApp muestra solo WhatsApp', (tester) async {
    await pump(tester, [followUp('whatsapp')]);
    expect(
      find.byTooltip('Enviar WhatsApp a Ana Pérez · Seguimiento agendado'),
      findsOneWidget,
    );
    expect(find.byTooltip('Llamar a Ana Pérez'), findsNothing);
  });

  testWidgets('seguimiento telefónico muestra solo llamada', (tester) async {
    await pump(tester, [followUp('telefono')]);
    expect(
      find.byTooltip('Llamar a Ana Pérez · Seguimiento agendado'),
      findsOneWidget,
    );
    expect(find.byTooltip('Enviar WhatsApp a Ana Pérez'), findsNothing);
  });

  testWidgets('sin seguimientos usa llamada', (tester) async {
    await pump(tester, const []);
    expect(find.byTooltip('Llamar a Ana Pérez'), findsOneWidget);
  });
}

class _FakeAgendaRepository extends AgendaRepository {
  _FakeAgendaRepository(this.values);

  final List<AgendaActivity> values;

  @override
  Future<List<AgendaActivity>> readCache() async => values;

  @override
  Future<List<AgendaActivity>> refresh() async => values;
}
