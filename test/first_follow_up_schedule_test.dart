import 'package:callerapp_frontend/presentation/models/first_follow_up_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializa el horario de negocio como UTC', () {
    final schedule = FirstFollowUpSchedule.fromBusinessTime(
      DateTime(2026, 10, 22, 17, 30),
      reminderBefore: const Duration(minutes: 15),
    );

    expect(schedule.programadaAt, '2026-10-22T22:30:00.000Z');
    expect(schedule.recordatorioAt, '2026-10-22T22:15:00.000Z');
    expect(DateTime.parse(schedule.programadaAt).isUtc, isTrue);
    expect(
      DateTime.parse(schedule.recordatorioAt)
          .isBefore(DateTime.parse(schedule.programadaAt)),
      isTrue,
    );
  });

  test('rechaza una actividad que ya pasó', () {
    final schedule = FirstFollowUpSchedule.fromBusinessTime(
      DateTime(2026, 10, 22, 15, 30),
      reminderBefore: const Duration(minutes: 15),
    );

    expect(
      schedule.validationError(DateTime(2026, 10, 22, 15, 50)),
      'La actividad debe programarse en el futuro.',
    );
  });

  test('acepta un horario futuro con recordatorio anterior', () {
    final schedule = FirstFollowUpSchedule.fromBusinessTime(
      DateTime(2026, 10, 22, 17, 30),
      reminderBefore: const Duration(minutes: 15),
    );

    expect(schedule.validationError(DateTime(2026, 10, 22, 15, 50)), isNull);
  });
}
