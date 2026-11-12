import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospect_detail_screen.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_follow_up_form.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/new_agenda_activity_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const prospect = ProspectRecord(
    name: 'Ana',
    phone: '529981234567',
    email: 'ana@example.com',
    status: 'Nuevo',
    temperature: 'Tibio',
    avatarColor: Colors.teal,
    statusColor: Colors.blue,
  );

  AgendaActivity activity(String medium) => AgendaActivity(
    id: 20,
    prospectId: 7,
    type: 'seguimiento',
    medium: medium,
    title: 'SEGUIMIENTO',
    prospect: 'Ana',
    description: 'Contactar al prospecto',
    date: DateTime(2026, 11, 11, 10),
    status: AgendaStatus.pending,
  );

  Future<void> pumpMedium(WidgetTester tester, String medium) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectDetailScreen(
          prospect: prospect,
          sourceActivity: activity(medium),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpWithoutActivity(
    WidgetTester tester,
    ProspectRecord value,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectDetailScreen(
          prospect: value.copyWith(id: 7),
          loadActivities: () async => const [],
        ),
      ),
    );
  }

  testWidgets('WhatsApp reemplaza a Llamar como acción principal', (
    tester,
  ) async {
    await pumpMedium(tester, 'whatsapp');
    expect(find.text('Enviar WhatsApp'), findsOneWidget);
    expect(find.text('Llamar'), findsNothing);
  });

  testWidgets('llamada conserva la acción Llamar', (tester) async {
    await pumpMedium(tester, 'llamada');
    expect(find.text('Llamar'), findsOneWidget);
    expect(find.text('Enviar WhatsApp'), findsNothing);
  });

  testWidgets('correo de contacto conserva separadas las plantillas', (
    tester,
  ) async {
    await pumpMedium(tester, 'correo');
    expect(find.text('Enviar correo'), findsOneWidget);
    expect(find.byTooltip('Correos prediseñados'), findsOneWidget);
    expect(find.text('Llamar'), findsNothing);
  });

  testWidgets('Facebook se presenta deshabilitado', (tester) async {
    await pumpMedium(tester, 'facebook');
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Abrir Facebook'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Llamar'), findsNothing);
    await tester.tap(find.text('Abrir Facebook'));
    await tester.pump();
    expect(
      find.text('El prospecto no tiene Facebook registrado.'),
      findsOneWidget,
    );
  });

  testWidgets('VER ACTIVIDAD permite editar y abrir la cancelación', (
    tester,
  ) async {
    await pumpMedium(tester, 'whatsapp');
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('open-follow-up-completion-activity')),
    );
    await tester.tap(
      find.byKey(const ValueKey('open-follow-up-completion-activity')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    expect(find.text('Cancelar actividad'), findsOneWidget);
    await tester.tap(find.text('VOLVER'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('EDITAR'));
    await tester.pump();
    expect(find.byType(NewAgendaActivityDialog), findsOneWidget);
  });

  testWidgets('sin actividad espera la resolución antes de mostrar Llamar', (
    tester,
  ) async {
    await pumpWithoutActivity(tester, prospect);
    expect(find.bySemanticsLabel('Cargando canal de contacto'), findsOneWidget);
    expect(find.text('Llamar'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Llamar'), findsOneWidget);
  });

  testWidgets('sin actividad y solo email usa Enviar correo', (tester) async {
    await pumpWithoutActivity(
      tester,
      prospect.copyWith(phone: '', email: 'ana@example.com'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Enviar correo'), findsOneWidget);
    expect(find.text('Llamar'), findsNothing);
  });

  testWidgets('sin datos de contacto permite completar Prospecto', (
    tester,
  ) async {
    await pumpWithoutActivity(tester, prospect.copyWith(phone: '', email: ''));
    await tester.pumpAndSettle();
    expect(find.text('Completar datos'), findsOneWidget);
    expect(find.text('Llamar'), findsNothing);
  });

  testWidgets('el formulario notifica el medio sin setState durante build', (
    tester,
  ) async {
    String? resolved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProspectFollowUpForm(
              prospect: prospect.copyWith(id: 7),
              sourceActivity: activity('whatsapp'),
              onMediumChanged: (value) => resolved = value?.backendValue,
              onSaved: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(resolved, 'whatsapp');
    expect(tester.takeException(), isNull);
  });

  testWidgets('el formulario notifica el medio descubierto en la agenda', (
    tester,
  ) async {
    String? resolved;
    final assigned = prospect.copyWith(id: 7);
    final pending = AgendaActivity(
      id: 20,
      prospectId: 7,
      type: 'seguimiento',
      medium: 'correo',
      title: 'SEGUIMIENTO',
      prospect: 'Ana',
      description: 'Enviar información',
      date: DateTime(2026, 11, 11, 10),
      status: AgendaStatus.pending,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProspectFollowUpForm(
              prospect: assigned,
              loadActivities: () async => [pending],
              onMediumChanged: (value) => resolved = value?.backendValue,
              onSaved: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(resolved, 'correo');
    expect(tester.takeException(), isNull);
  });
}
