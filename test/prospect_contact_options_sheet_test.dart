import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_contact_options_sheet.dart';
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

  Future<void> pump(
    WidgetTester tester, {
    ProspectRecord value = prospect,
    bool agendaVerified = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectContactOptionsSheet(
            prospect: value,
            agendaVerified: agendaVerified,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  FilledButton continueButton(WidgetTester tester) => tester
      .widget<FilledButton>(find.widgetWithText(FilledButton, 'SÍ, CONTINUAR'));

  testWidgets('muestra el mensaje y las cuatro opciones', (tester) async {
    await pump(tester);
    expect(
      find.text('Este prospecto no tiene seguimientos pendientes.'),
      findsOneWidget,
    );
    expect(find.text('Llamar'), findsOneWidget);
    expect(find.text('Enviar WhatsApp'), findsOneWidget);
    expect(find.text('Abrir Facebook'), findsOneWidget);
    expect(find.text('Enviar correo'), findsOneWidget);
    expect(continueButton(tester).onPressed, isNull);
  });

  testWidgets('seleccionar WhatsApp actualiza el aviso y habilita continuar', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Enviar WhatsApp'));
    await tester.pump();
    expect(find.textContaining('Se abrirá WhatsApp'), findsOneWidget);
    expect(continueButton(tester).onPressed, isNotNull);
  });

  testWidgets('sin teléfono ni correo deshabilita los medios reales', (
    tester,
  ) async {
    await pump(
      tester,
      value: prospect.copyWith(phone: '', email: ''),
    );
    expect(find.text('Sin teléfono válido'), findsNWidgets(2));
    expect(find.text('Sin correo válido'), findsOneWidget);
    expect(
      find.text('Abre Facebook; no busca el perfil del prospecto'),
      findsOneWidget,
    );
  });

  testWidgets('Facebook se puede seleccionar y avisa que no busca el perfil', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Abrir Facebook'));
    await tester.pump();
    expect(find.textContaining('no se buscará el perfil'), findsOneWidget);
    expect(continueButton(tester).onPressed, isNotNull);
  });

  testWidgets('sin agenda verificada no afirma que no hay seguimientos', (
    tester,
  ) async {
    await pump(tester, agendaVerified: false);
    expect(
      find.text('No se pudo verificar la agenda de este prospecto.'),
      findsOneWidget,
    );
  });
}
