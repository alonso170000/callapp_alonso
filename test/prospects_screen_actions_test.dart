import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospects_screen.dart';
import 'package:callerapp_frontend/repositories/agenda_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void mockUrlLauncherFailure() {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => false);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  }

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

  testWidgets('sin seguimientos muestra el selector de medio', (tester) async {
    await pump(tester, const []);
    expect(
      find.byTooltip('Elegir medio de contacto para Ana Pérez'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Elegir medio de contacto para Ana Pérez'));
    await tester.pumpAndSettle();
    expect(
      find.text('Este prospecto no tiene seguimientos pendientes.'),
      findsOneWidget,
    );
    expect(find.text('Llamar'), findsOneWidget);
    expect(find.text('Enviar WhatsApp'), findsOneWidget);
    expect(find.text('Abrir Facebook'), findsOneWidget);
    expect(find.text('Enviar correo'), findsOneWidget);
    expect(find.text('SÍ, CONTINUAR'), findsOneWidget);
  });

  testWidgets('seguimiento Facebook abre la app sin buscar el perfil', (
    tester,
  ) async {
    mockUrlLauncherFailure();
    await pump(tester, [followUp('facebook')]);
    final action = find.byTooltip(
      'Abrir Facebook a Ana Pérez · Seguimiento agendado',
    );
    expect(action, findsOneWidget);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.textContaining('abrir Facebook'), findsOneWidget);
    await tester.tap(find.text('ENTENDIDO'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo abrir Facebook.'), findsOneWidget);
    expect(
      find.text('Facebook no está disponible para este prospecto.'),
      findsNothing,
    );
  });

  testWidgets('seleccionar llamada pide confirmación antes de marcar', (
    tester,
  ) async {
    await pump(tester, const []);
    await tester.tap(find.byTooltip('Elegir medio de contacto para Ana Pérez'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Llamar'));
    await tester.pump();
    await tester.tap(find.text('SÍ, CONTINUAR'));
    await tester.pumpAndSettle();
    expect(find.text('Antes de marcar'), findsOneWidget);
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
