import 'package:callerapp_frontend/presentation/models/agenda_models.dart';

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
