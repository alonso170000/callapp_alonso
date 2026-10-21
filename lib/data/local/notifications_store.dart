import 'dart:convert';

import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/notification_models.dart';

typedef NotificationScope = LocalScope;

class NotificationsStore {
  NotificationsStore({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> upsert(
    NotificationScope scope,
    List<ActivityNotification> notifications,
  ) async {
    if (notifications.isEmpty) return;
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await database.transaction((transaction) async {
      for (final notification in notifications) {
        await transaction.rawInsert('''
          INSERT INTO activity_notifications (
            user_id, development_id, activity_id, prospect_id, type, medium,
            title, prospect, description, activity_at_ms, reminder_at_ms,
            status, tags_json, location, reminder_minutes, has_reminder,
            last_contact, prospect_avatar_url, completed_at_ms, is_read,
            dismissed, created_at_ms
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, ?)
          ON CONFLICT(user_id, development_id, activity_id) DO UPDATE SET
            prospect_id = excluded.prospect_id,
            type = excluded.type,
            medium = excluded.medium,
            title = excluded.title,
            prospect = excluded.prospect,
            description = excluded.description,
            activity_at_ms = excluded.activity_at_ms,
            reminder_at_ms = excluded.reminder_at_ms,
            status = excluded.status,
            tags_json = excluded.tags_json,
            location = excluded.location,
            reminder_minutes = excluded.reminder_minutes,
            has_reminder = excluded.has_reminder,
            last_contact = excluded.last_contact,
            prospect_avatar_url = excluded.prospect_avatar_url,
            completed_at_ms = excluded.completed_at_ms,
            is_read = CASE
              WHEN activity_notifications.reminder_at_ms <> excluded.reminder_at_ms
                THEN 0
              ELSE activity_notifications.is_read
            END,
            dismissed = CASE
              WHEN activity_notifications.reminder_at_ms <> excluded.reminder_at_ms
                THEN 0
              ELSE activity_notifications.dismissed
            END
          ''', _values(scope, notification));
      }
    });
  }

  Future<List<ActivityNotification>> read(NotificationScope scope) async {
    final database = await _database.databaseOrNull;
    if (database == null) return const [];
    final rows = await database.query(
      'activity_notifications',
      where: 'user_id = ? AND development_id = ? AND dismissed = 0',
      whereArgs: [scope.userId, scope.developmentId],
      orderBy: 'reminder_at_ms DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<bool> contains(NotificationScope scope, int activityId) async {
    final database = await _database.databaseOrNull;
    if (database == null) return false;
    final rows = await database.query(
      'activity_notifications',
      columns: const ['activity_id'],
      where: 'user_id = ? AND development_id = ? AND activity_id = ?',
      whereArgs: [scope.userId, scope.developmentId, activityId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<DateTime?> reminderAt(NotificationScope scope, int activityId) async {
    final database = await _database.databaseOrNull;
    if (database == null) return null;
    final rows = await database.query(
      'activity_notifications',
      columns: const ['reminder_at_ms'],
      where: 'user_id = ? AND development_id = ? AND activity_id = ?',
      whereArgs: [scope.userId, scope.developmentId, activityId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      rows.single['reminder_at_ms'] as int,
    );
  }

  Future<void> markRead(NotificationScope scope, int activityId) async {
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await database.update(
      'activity_notifications',
      {'is_read': 1},
      where: 'user_id = ? AND development_id = ? AND activity_id = ?',
      whereArgs: [scope.userId, scope.developmentId, activityId],
    );
  }

  Future<void> markAllRead(NotificationScope scope) async {
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await database.update(
      'activity_notifications',
      {'is_read': 1},
      where: 'user_id = ? AND development_id = ? AND dismissed = 0',
      whereArgs: [scope.userId, scope.developmentId],
    );
  }

  Future<void> dismiss(NotificationScope scope, int activityId) async {
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await database.update(
      'activity_notifications',
      {'dismissed': 1},
      where: 'user_id = ? AND development_id = ? AND activity_id = ?',
      whereArgs: [scope.userId, scope.developmentId, activityId],
    );
  }

  Future<int> purgeReadOlderThan(
    NotificationScope scope,
    DateTime cutoff,
  ) async {
    final database = await _database.databaseOrNull;
    if (database == null) return 0;
    return database.delete(
      'activity_notifications',
      where: 'user_id = ? AND development_id = ? AND is_read = 1 AND reminder_at_ms < ?',
      whereArgs: [
        scope.userId,
        scope.developmentId,
        cutoff.millisecondsSinceEpoch,
      ],
    );
  }

  List<Object?> _values(
    NotificationScope scope,
    ActivityNotification notification,
  ) {
    final activity = notification.activity;
    return [
      scope.userId,
      scope.developmentId,
      activity.id,
      activity.prospectId,
      activity.type,
      activity.medium,
      activity.title,
      activity.prospect,
      activity.description,
      activity.date.millisecondsSinceEpoch,
      notification.reminderAt.millisecondsSinceEpoch,
      activity.status.name,
      jsonEncode(activity.tags),
      activity.location,
      activity.reminderMinutes,
      activity.hasReminder ? 1 : 0,
      activity.lastContact,
      activity.prospectAvatarUrl,
      activity.completedAt?.millisecondsSinceEpoch,
      DateTime.now().millisecondsSinceEpoch,
    ];
  }

  ActivityNotification _fromRow(Map<String, Object?> row) {
    final statusName = row['status'] as String;
    final status = AgendaStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => AgendaStatus.pending,
    );
    return ActivityNotification(
      isRead: row['is_read'] == 1,
      reminderAt: DateTime.fromMillisecondsSinceEpoch(
        row['reminder_at_ms'] as int,
      ),
      activity: AgendaActivity(
        id: row['activity_id'] as int,
        prospectId: row['prospect_id'] as int?,
        type: row['type'] as String?,
        medium: row['medium'] as String?,
        title: row['title'] as String,
        prospect: row['prospect'] as String,
        description: row['description'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(row['activity_at_ms'] as int),
        status: status,
        tags: (jsonDecode(row['tags_json'] as String) as List)
            .map((value) => value.toString())
            .toList(),
        location: row['location'] as String,
        reminderMinutes: row['reminder_minutes'] as int,
        hasReminder: row['has_reminder'] == 1,
        lastContact: row['last_contact'] as String,
        prospectAvatarUrl: row['prospect_avatar_url'] as String?,
        completedAt: row['completed_at_ms'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                row['completed_at_ms'] as int,
              ),
      ),
    );
  }
}
