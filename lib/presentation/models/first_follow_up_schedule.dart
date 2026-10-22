import 'package:callerapp_frontend/services/business_clock.dart';

/// Horario del primer seguimiento expresado en hora de negocio.
class FirstFollowUpSchedule {
  const FirstFollowUpSchedule({
    required this.scheduledAt,
    required this.reminderAt,
  });

  factory FirstFollowUpSchedule.fromBusinessTime(
    DateTime scheduledAt, {
    required Duration reminderBefore,
  }) => FirstFollowUpSchedule(
    scheduledAt: scheduledAt,
    reminderAt: scheduledAt.subtract(reminderBefore),
  );

  final DateTime scheduledAt;
  final DateTime reminderAt;

  /// `null` si el horario se puede programar; si no, el mensaje para el usuario.
  String? validationError([DateTime? now]) {
    if (!scheduledAt.isAfter(now ?? businessNow())) {
      return 'La actividad debe programarse en el futuro.';
    }
    if (!reminderAt.isBefore(scheduledAt)) {
      return 'El recordatorio debe ser anterior a la actividad.';
    }
    return null;
  }

  /// El backend compara contra UTC, así que la hora de negocio se envía con
  /// zona explícita.
  String get programadaAt => businessTimeToUtcIso8601(scheduledAt);

  String get recordatorioAt => businessTimeToUtcIso8601(reminderAt);
}
