import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:flutter/foundation.dart';

enum NotificationTargetType { prospect, activity }

@immutable
class NotificationTarget {
  const NotificationTarget({required this.type, required this.id});

  final NotificationTargetType type;
  final int id;

  @override
  bool operator ==(Object other) =>
      other is NotificationTarget && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);

  @override
  String toString() => 'NotificationTarget($type, $id)';
}

enum NotificationInboxFilter { all, unread, read }

class ActivityNotification {
  const ActivityNotification({
    required this.activity,
    required this.reminderAt,
    required this.isRead,
  });

  final AgendaActivity activity;
  final DateTime reminderAt;
  final bool isRead;

  int get activityId => activity.id!;
  String get title => activity.title;
  String get prospect => activity.prospect;
  DateTime get activityAt => activity.date;
  int get minutesBefore => activity.reminderMinutes;

  ActivityNotification copyWith({bool? isRead}) => ActivityNotification(
    activity: activity,
    reminderAt: reminderAt,
    isRead: isRead ?? this.isRead,
  );
}
