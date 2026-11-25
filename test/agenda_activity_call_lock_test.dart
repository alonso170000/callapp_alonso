import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_activity_detail.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AgendaActivity _activity({required String type}) => AgendaActivity(
  id: 42,
  prospectId: 5,
  type: type,
  medium: type == 'seguimiento' ? 'llamada' : null,
  title: type.toUpperCase(),
  prospect: 'Ana Pérez',
  description: 'Actividad de prueba',
  date: businessNow(),
  status: AgendaStatus.pending,
  deleteUntil: businessNow().add(const Duration(days: 1)),
);

Future<void> _pumpDetail(
  WidgetTester tester, {
  required AgendaActivity activity,
  required bool locked,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: AgendaActivityDetail(
        activity: activity,
        lockedByActiveCall: locked,
        onClose: () {},
        onMessage: () {},
        onCall: () {},
        onOpenProspect: () {},
        onEdit: () {},
        onComplete: () {},
        onReschedule: () {},
        onDelete: () {},
      ),
    ),
  ),
);

OutlinedButton _outlinedButton(WidgetTester tester, String label) =>
    tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(OutlinedButton),
      ),
    );

FilledButton _filledButton(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(
      find.ancestor(of: find.text(label), matching: find.byType(FilledButton)),
    );

void main() {
  testWidgets('bloquea las acciones mutables y muestra el aviso', (
    tester,
  ) async {
    await _pumpDetail(tester, activity: _activity(type: 'tarea'), locked: true);

    expect(
      find.byKey(const ValueKey('activity-call-lock-notice')),
      findsOneWidget,
    );
    expect(_outlinedButton(tester, 'EDITAR').onPressed, isNull);
    expect(_outlinedButton(tester, 'Cancelar').onPressed, isNull);
    expect(_outlinedButton(tester, 'Eliminar').onPressed, isNull);
    expect(_filledButton(tester, 'COMPLETAR ACTIVIDAD').onPressed, isNull);
  });

  testWidgets('mantiene habilitadas las acciones cuando no hay bloqueo', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      activity: _activity(type: 'tarea'),
      locked: false,
    );

    expect(
      find.byKey(const ValueKey('activity-call-lock-notice')),
      findsNothing,
    );
    expect(_outlinedButton(tester, 'EDITAR').onPressed, isNotNull);
    expect(_outlinedButton(tester, 'Cancelar').onPressed, isNotNull);
    expect(_outlinedButton(tester, 'Eliminar').onPressed, isNotNull);
    expect(_filledButton(tester, 'COMPLETAR ACTIVIDAD').onPressed, isNotNull);
  });

  testWidgets('permite atender un seguimiento aunque esté bloqueado', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      activity: _activity(type: 'seguimiento'),
      locked: true,
    );

    expect(_filledButton(tester, 'ATENDER ACTIVIDAD').onPressed, isNotNull);
  });
}
