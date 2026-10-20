import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AgendaActivity activity({
    required int id,
    required DateTime date,
    AgendaStatus status = AgendaStatus.pending,
    bool hasReminder = true,
    int reminderMinutes = 15,
  }) => AgendaActivity(
    id: id,
    type: 'tarea',
    title: 'TAREA',
    prospect: 'Prospecto $id',
    description: 'Actividad de prueba',
    date: date,
    status: status,
    hasReminder: hasReminder,
    reminderMinutes: reminderMinutes,
  );

  test('uses each pending activity reminder and sorts upcoming alerts', () {
    final now = DateTime(2026, 10, 20, 9);
    final reminders = NotificationService.remindersFor([
      activity(id: 1, date: DateTime(2026, 10, 20, 12), reminderMinutes: 30),
      activity(id: 2, date: DateTime(2026, 10, 20, 10), reminderMinutes: 15),
      activity(
        id: 3,
        date: DateTime(2026, 10, 20, 11),
        status: AgendaStatus.completed,
      ),
      activity(
        id: 4,
        date: DateTime(2026, 10, 20, 8),
        status: AgendaStatus.overdue,
      ),
      activity(id: 5, date: DateTime(2026, 10, 20, 13), hasReminder: false),
    ], now: now);

    expect(reminders.map((item) => item.activityId), [2, 1]);
    expect(reminders.first.reminderAt, DateTime(2026, 10, 20, 9, 45));
    expect(reminders.last.reminderAt, DateTime(2026, 10, 20, 11, 30));
  });

  test('does not schedule a reminder whose configured time already passed', () {
    final reminders = NotificationService.remindersFor([
      activity(id: 8, date: DateTime(2026, 10, 20, 9, 10)),
    ], now: DateTime(2026, 10, 20, 9));

    expect(reminders, isEmpty);
  });

  test('inbox contains only alerts whose reminder time already arrived', () {
    final now = DateTime(2026, 10, 20, 10);
    final notifications = NotificationService.inboxNotificationsFor([
      activity(id: 1, date: DateTime(2026, 10, 20, 10, 10)),
      activity(id: 2, date: DateTime(2026, 10, 20, 11)),
      activity(
        id: 3,
        date: DateTime(2026, 10, 20, 9),
        status: AgendaStatus.cancelled,
      ),
    ], now: now);

    expect(notifications.map((item) => item.activityId), [1]);
    expect(notifications.single.reminderAt, DateTime(2026, 10, 20, 9, 55));
  });

  test('creates notifications only for newly assigned prospects', () {
    final now = DateTime(2026, 10, 20, 12);
    ProspectRecord prospect(int id, DateTime assignedAt) => ProspectRecord(
      id: id,
      avatarUrl: 'https://example.com/avatar-$id.png',
      name: 'Prospecto $id',
      phone: '998000000$id',
      email: 'prospecto$id@example.com',
      status: 'Nuevo',
      temperature: 'Tibio',
      avatarColor: Colors.teal,
      statusColor: Colors.green,
      assignedAt: assignedAt,
    );

    final notifications = NotificationService.assignmentNotificationsFor([
      prospect(1, now.subtract(const Duration(minutes: 10))),
      prospect(2, now.subtract(const Duration(days: 8))),
      prospect(3, now.add(const Duration(minutes: 1))),
    ], now: now);

    expect(notifications, hasLength(1));
    expect(notifications.single.activityId, -1);
    expect(
      notifications.single.activity.type,
      NotificationService.assignmentType,
    );
    expect(notifications.single.activity.prospectAvatarUrl, isNotNull);
  });

  test('notifies a prospect that becomes visible even without a new date', () {
    final now = DateTime(2026, 10, 20, 12);
    final prospect = ProspectRecord(
      id: 9,
      name: 'Asignado desde CRM',
      phone: '9980000009',
      email: '',
      status: 'Nuevo',
      temperature: 'Tibio',
      avatarColor: Colors.teal,
      statusColor: Colors.green,
      assignedAt: DateTime(2026, 10, 1),
    );

    final notifications = NotificationService.assignmentNotificationsFor(
      [prospect],
      now: now,
      newlyVisibleProspectIds: const {9},
    );

    expect(notifications.single.activityId, -9);
    expect(notifications.single.reminderAt, now);
  });
}
