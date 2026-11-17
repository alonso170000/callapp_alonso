import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_week_selector.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AgendaActivity activity(DateTime date, AgendaStatus status) => AgendaActivity(
    type: 'seguimiento',
    medium: 'llamada',
    title: 'SEGUIMIENTO',
    prospect: 'Ana',
    description: 'Confirmar propuesta',
    date: date,
    status: status,
  );

  testWidgets('ignora canceladas al calcular el indicador del día', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(businessNow());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaWeekSelector(
            selectedDate: today,
            activities: [
              activity(today, AgendaStatus.completed),
              activity(
                today.add(const Duration(hours: 1)),
                AgendaStatus.completed,
              ),
              activity(
                today.add(const Duration(hours: 2)),
                AgendaStatus.cancelled,
              ),
            ],
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.task_alt_rounded), findsOneWidget);
    expect(find.byIcon(Icons.update_rounded), findsNothing);
  });

  testWidgets('pulsación prolongada permite regresar a hoy', (tester) async {
    final today = DateUtils.dateOnly(businessNow());
    final selected = today.add(const Duration(days: 8));
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaWeekSelector(
            selectedDate: selected,
            activities: const [],
            onSelected: (date) => result = date,
          ),
        ),
      ),
    );

    await tester.longPress(find.byKey(const ValueKey('agenda-week-day-0')));
    await tester.pumpAndSettle();
    expect(find.text('Regresar a hoy'), findsOneWidget);
    await tester.tap(find.text('Regresar a hoy'));
    await tester.pumpAndSettle();

    expect(result, today);
  });
}
