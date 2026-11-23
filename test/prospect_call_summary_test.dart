import 'package:callerapp_frontend/presentation/models/call_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_history_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProspectCallRecord call(String outcome, {int id = 1}) => ProspectCallRecord(
    id: id,
    startedAt: DateTime(2026, 9, 15, 10),
    durationSeconds: 10,
    durationEstimated: false,
    outcome: outcome,
    phone: '9980000000',
    audioState: 'pendiente',
  );

  test('calcula 75 por ciento de llamadas contestadas', () {
    final summary = ProspectCallSummary.fromRecords([
      call(ProspectCallOutcome.answered.value, id: 1),
      call(ProspectCallOutcome.answered.value, id: 2),
      call(ProspectCallOutcome.answered.value, id: 3),
      call(ProspectCallOutcome.unanswered.value, id: 4),
    ]);

    expect(summary.answered, 3);
    expect(summary.unanswered, 1);
    expect(summary.total, 4);
    expect(summary.answeredPercent, 75);
    expect(summary.unansweredPercent, 25);
  });

  test('todo resultado distinto de contestada cuenta como no contestado', () {
    final summary = ProspectCallSummary.fromRecords([
      call(ProspectCallOutcome.voicemail.value, id: 1),
      call(ProspectCallOutcome.invalidNumber.value, id: 2),
      call(ProspectCallOutcome.other.value, id: 3),
      call('resultado_desconocido', id: 4),
    ]);

    expect(summary.answered, 0);
    expect(summary.unanswered, 4);
  });

  test('la lista vacía produce porcentajes cero', () {
    final summary = ProspectCallSummary.fromRecords(const []);

    expect(summary.total, 0);
    expect(summary.isEmpty, isTrue);
    expect(summary.answeredPercent, 0);
    expect(summary.unansweredPercent, 0);
  });

  test('redondea un tercio a 33 y mantiene el total en 100', () {
    final summary = ProspectCallSummary.fromRecords([
      call(ProspectCallOutcome.answered.value, id: 1),
      call(ProspectCallOutcome.unanswered.value, id: 2),
      call(ProspectCallOutcome.other.value, id: 3),
    ]);

    expect(summary.answeredPercent, 33);
    expect(summary.unansweredPercent, 67);
    expect(summary.answeredPercent + summary.unansweredPercent, 100);
  });
}
