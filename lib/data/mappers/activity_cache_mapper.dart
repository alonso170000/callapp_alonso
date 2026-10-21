import 'dart:convert';

import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/services/business_clock.dart';

/// Convierte actividades entre el modelo de la app y la fila SQLite.
///
/// El estado se guarda tal como lo reporta el servidor
/// (`pendiente`, `completada`, `cancelada`). El estado "atrasado" se recalcula
/// al leer con el reloj de negocio, porque depende del momento de la consulta.
class ActivityCacheMapper {
  const ActivityCacheMapper._();

  static Map<String, Object?> toRow(
    AgendaActivity activity, {
    required int userId,
    required int developmentId,
  }) => {
    'user_id': userId,
    'development_id': developmentId,
    'activity_id': activity.id,
    'prospect_id': activity.prospectId,
    'prospect_avatar_url': activity.prospectAvatarUrl,
    'type': activity.type,
    'medium': activity.medium,
    'title': activity.title,
    'prospect': activity.prospect,
    'description': activity.description,
    'activity_at_ms': activity.date.millisecondsSinceEpoch,
    'server_status': serverStatus(activity.status),
    'tags_json': jsonEncode(activity.tags),
    'location': activity.location,
    'reminder_minutes': activity.reminderMinutes,
    'has_reminder': activity.hasReminder ? 1 : 0,
    'last_contact': activity.lastContact,
    'completed_at_ms': activity.completedAt?.millisecondsSinceEpoch,
    'delete_until_ms': activity.deleteUntil?.millisecondsSinceEpoch,
  };

  static AgendaActivity fromRow(Map<String, Object?> row, {DateTime? now}) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      row['activity_at_ms']! as int,
    );
    final reference = now ?? businessNow();
    final rawStatus = row['server_status'] as String? ?? 'pendiente';
    return AgendaActivity(
      id: row['activity_id']! as int,
      prospectId: row['prospect_id'] as int?,
      prospectAvatarUrl: row['prospect_avatar_url'] as String?,
      type: row['type'] as String?,
      medium: row['medium'] as String?,
      title: row['title']! as String,
      prospect: row['prospect']! as String,
      description: row['description']! as String,
      date: date,
      status: statusFromServer(rawStatus, date: date, now: reference),
      tags: (jsonDecode(row['tags_json'] as String? ?? '[]') as List)
          .map((value) => value.toString())
          .toList(),
      location: row['location']! as String,
      reminderMinutes: row['reminder_minutes']! as int,
      hasReminder: row['has_reminder'] == 1,
      lastContact: row['last_contact']! as String,
      completedAt: _date(row['completed_at_ms']),
      deleteUntil: _date(row['delete_until_ms']),
    );
  }

  /// Estado persistible: "atrasado" se guarda como "pendiente".
  static String serverStatus(AgendaStatus status) => switch (status) {
    AgendaStatus.completed => 'completada',
    AgendaStatus.cancelled => 'cancelada',
    AgendaStatus.pending || AgendaStatus.overdue => 'pendiente',
  };

  /// Reconstruye el estado usando la fecha y el momento actual.
  static AgendaStatus statusFromServer(
    String raw, {
    required DateTime date,
    required DateTime now,
  }) => switch (raw) {
    'completada' => AgendaStatus.completed,
    'cancelada' => AgendaStatus.cancelled,
    _ => date.isBefore(now) ? AgendaStatus.overdue : AgendaStatus.pending,
  };

  static DateTime? _date(Object? value) => switch (value) {
    final int milliseconds => DateTime.fromMillisecondsSinceEpoch(milliseconds),
    _ => null,
  };
}
