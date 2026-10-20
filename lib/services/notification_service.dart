import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/notification_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/data/local/notifications_store.dart';

class NotificationService extends ChangeNotifier {
  NotificationService._();

  static final instance = NotificationService._();
  static const _payloadPrefix = 'callerapp:activity:';
  static const _notificationIdOffset = 1000000;
  static const _channelId = 'activity_reminders';
  static const _locationName = 'America/Cancun';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final NotificationsStore _store = NotificationsStore();
  final List<ActivityNotification> _reminders = [];
  List<AgendaActivity> _lastActivities = const [];
  NotificationScope? _scope;
  bool _initialized = false;
  bool _enabled = true;
  bool? _permissionGranted;
  Timer? _nextInboxTimer;
  Timer? _cleanupTimer;

  List<ActivityNotification> get reminders => List.unmodifiable(_reminders);
  bool get enabled => _enabled;
  bool? get permissionGranted => _permissionGranted;
  int get unreadCount =>
      _reminders.where((notification) => !notification.isRead).length;

  static const assignmentType = 'nuevo_prospecto';

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_locationName));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    try {
      _initialized = await _plugin.initialize(settings: settings) ?? false;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    if (value) {
      await syncActivities(_lastActivities);
    } else {
      await clearActivityReminders(clearActivities: false);
    }
  }

  Future<void> syncActivities(
    List<AgendaActivity> activities, {
    int? userId,
    int? developmentId,
  }) async {
    _lastActivities = List.unmodifiable(activities);
    if (userId != null && developmentId != null) {
      _scope = NotificationScope(userId: userId, developmentId: developmentId);
    }
    final now = businessNow();
    final next = remindersFor(activities, now: now);
    final inbox = inboxNotificationsFor(activities, now: now);
    await _persistInbox(inbox, now);
    _scheduleInboxRefresh(next, now);
    _scheduleCleanup();
    notifyListeners();
    if (!_initialized || kIsWeb) return;

    try {
      await _cancelScheduledActivityNotifications();
      if (!_enabled || next.isEmpty) return;

      final schedulingMode = await _requestPermissions();
      if (_permissionGranted == false) return;
      for (final reminder in next) {
        final scheduled = tz.TZDateTime(
          tz.local,
          reminder.reminderAt.year,
          reminder.reminderAt.month,
          reminder.reminderAt.day,
          reminder.reminderAt.hour,
          reminder.reminderAt.minute,
          reminder.reminderAt.second,
        );
        await _plugin.zonedSchedule(
          id: _notificationId(reminder.activityId),
          title: 'Recordatorio: ${reminder.title}',
          body:
              '${reminder.prospect} · Actividad en ${reminder.minutesBefore} minutos.',
          scheduledDate: scheduled,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              'Recordatorios de actividades',
              channelDescription:
                  'Avisos de tareas, visitas y seguimientos pendientes.',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: schedulingMode,
          payload: '$_payloadPrefix${reminder.activityId}',
        );
      }
    } catch (_) {
      _permissionGranted = false;
      notifyListeners();
    }
  }

  Future<void> syncAssignedProspects(
    List<ProspectRecord> prospects, {
    required int userId,
    required int developmentId,
    Set<int> newlyVisibleProspectIds = const {},
  }) async {
    final scope = NotificationScope(
      userId: userId,
      developmentId: developmentId,
    );
    _scope = scope;
    final now = businessNow();
    final assignments = assignmentNotificationsFor(
      prospects,
      now: now,
      newlyVisibleProspectIds: newlyVisibleProspectIds,
    );
    if (assignments.isEmpty) {
      await _reloadStored(scope, now);
      return;
    }

    final newAssignments = <ActivityNotification>[];
    for (final notification in assignments) {
      final storedReminder = await _store.reminderAt(
        scope,
        notification.activityId,
      );
      if (storedReminder != notification.reminderAt) {
        newAssignments.add(notification);
      }
    }
    await _store.upsert(scope, assignments);
    await _reloadStored(scope, now);
    _scheduleCleanup();
    notifyListeners();
    await _showAssignmentAlerts(newAssignments);
  }

  Future<AndroidScheduleMode> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final notifications = await android.requestNotificationsPermission();
      _permissionGranted = notifications ?? true;
      if (_permissionGranted == false) {
        notifyListeners();
        return AndroidScheduleMode.inexactAllowWhileIdle;
      }
      var exact = await android.canScheduleExactNotifications() ?? false;
      if (!exact) {
        await android.requestExactAlarmsPermission();
        exact = await android.canScheduleExactNotifications() ?? false;
      }
      notifyListeners();
      return exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      _permissionGranted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      notifyListeners();
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> clearActivityReminders({bool clearActivities = true}) async {
    _nextInboxTimer?.cancel();
    _cleanupTimer?.cancel();
    if (clearActivities) {
      _lastActivities = const [];
      _scope = null;
    }
    _reminders.clear();
    notifyListeners();
    if (!_initialized || kIsWeb) return;
    try {
      await _cancelScheduledActivityNotifications();
    } catch (_) {
      // Closing the session must not fail if the operating system is busy.
    }
  }

  Future<void> _cancelScheduledActivityNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final notification in pending) {
      if (notification.payload?.startsWith(_payloadPrefix) ?? false) {
        await _plugin.cancel(id: notification.id);
      }
    }
  }

  Future<void> markRead(int activityId) async {
    final index = _reminders.indexWhere(
      (notification) => notification.activityId == activityId,
    );
    if (index != -1 && !_reminders[index].isRead) {
      _reminders[index] = _reminders[index].copyWith(isRead: true);
      notifyListeners();
    }
    final scope = _scope;
    if (scope != null) await _store.markRead(scope, activityId);
  }

  Future<void> markAllRead() async {
    for (var index = 0; index < _reminders.length; index++) {
      _reminders[index] = _reminders[index].copyWith(isRead: true);
    }
    notifyListeners();
    final scope = _scope;
    if (scope != null) await _store.markAllRead(scope);
  }

  Future<void> dismiss(int activityId) async {
    _reminders.removeWhere(
      (notification) => notification.activityId == activityId,
    );
    notifyListeners();
    final scope = _scope;
    if (scope != null) await _store.dismiss(scope, activityId);
  }

  Future<void> _persistInbox(
    List<ActivityNotification> inbox,
    DateTime now,
  ) async {
    final scope = _scope;
    if (scope == null) {
      _reminders
        ..clear()
        ..addAll(inbox);
      return;
    }
    try {
      await _store.upsert(scope, inbox);
      await _store.purgeReadOlderThan(
        scope,
        now.subtract(const Duration(days: 7)),
      );
      final stored = await _store.read(scope);
      _reminders
        ..clear()
        ..addAll(stored);
    } catch (_) {
      _reminders
        ..clear()
        ..addAll(inbox);
    }
  }

  Future<void> _reloadStored(NotificationScope scope, DateTime now) async {
    try {
      await _store.purgeReadOlderThan(
        scope,
        now.subtract(const Duration(days: 7)),
      );
      final stored = await _store.read(scope);
      _reminders
        ..clear()
        ..addAll(stored);
    } catch (_) {
      // La bandeja volverá a sincronizarse en la siguiente consulta.
    }
  }

  Future<void> _showAssignmentAlerts(
    List<ActivityNotification> notifications,
  ) async {
    if (!_enabled || notifications.isEmpty || kIsWeb) return;
    await initialize();
    if (!_initialized) return;
    try {
      await _requestPermissions();
      if (_permissionGranted == false) return;
      for (final notification in notifications) {
        await _plugin.show(
          id: _notificationId(notification.activityId),
          title: 'Nuevo prospecto asignado',
          body:
              '${notification.prospect} ya está disponible en Mis prospectos.',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              'Recordatorios de actividades',
              channelDescription: 'Avisos de tareas, visitas, seguimientos y prospectos asignados.',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: '$_payloadPrefix${notification.activityId}',
        );
      }
    } catch (_) {
      // La asignación permanece visible en la bandeja aunque falle el aviso SO.
    }
  }

  void _scheduleCleanup() {
    _cleanupTimer?.cancel();
    if (_scope == null) return;
    _cleanupTimer = Timer.periodic(const Duration(hours: 12), (_) async {
      final scope = _scope;
      if (scope == null) return;
      try {
        await _store.purgeReadOlderThan(
          scope,
          businessNow().subtract(const Duration(days: 7)),
        );
        final stored = await _store.read(scope);
        _reminders
          ..clear()
          ..addAll(stored);
        notifyListeners();
      } catch (_) {
        // A transient SQLite failure is retried on the next sync or cycle.
      }
    });
  }

  static List<ActivityNotification> remindersFor(
    List<AgendaActivity> activities, {
    required DateTime now,
  }) {
    final reminders = <ActivityNotification>[];
    for (final activity in activities) {
      final id = activity.id;
      final isPending =
          activity.status == AgendaStatus.pending ||
          activity.status == AgendaStatus.overdue;
      if (id == null || !isPending || !activity.hasReminder) continue;
      final reminderAt = activity.date.subtract(
        Duration(minutes: activity.reminderMinutes),
      );
      if (!reminderAt.isAfter(now)) continue;
      reminders.add(
        ActivityNotification(
          activity: activity,
          reminderAt: reminderAt,
          isRead: false,
        ),
      );
    }
    reminders.sort((a, b) => a.reminderAt.compareTo(b.reminderAt));
    return reminders;
  }

  static List<ActivityNotification> inboxNotificationsFor(
    List<AgendaActivity> activities, {
    required DateTime now,
  }) {
    final notifications = <ActivityNotification>[];
    for (final activity in activities) {
      final id = activity.id;
      final isPending =
          activity.status == AgendaStatus.pending ||
          activity.status == AgendaStatus.overdue;
      if (id == null || !isPending || !activity.hasReminder) continue;
      final reminderAt = activity.date.subtract(
        Duration(minutes: activity.reminderMinutes),
      );
      if (reminderAt.isAfter(now)) continue;
      notifications.add(
        ActivityNotification(
          activity: activity,
          reminderAt: reminderAt,
          isRead: false,
        ),
      );
    }
    notifications.sort((a, b) => b.reminderAt.compareTo(a.reminderAt));
    return notifications;
  }

  static List<ActivityNotification> assignmentNotificationsFor(
    List<ProspectRecord> prospects, {
    required DateTime now,
    Set<int> newlyVisibleProspectIds = const {},
  }) {
    final cutoff = now.subtract(const Duration(days: 7));
    final notifications = <ActivityNotification>[];
    for (final prospect in prospects) {
      final id = prospect.id;
      final assignedAt = newlyVisibleProspectIds.contains(id)
          ? now
          : prospect.assignedAt;
      if (id == null ||
          assignedAt == null ||
          assignedAt.isBefore(cutoff) ||
          assignedAt.isAfter(now)) {
        continue;
      }
      notifications.add(
        ActivityNotification(
          reminderAt: assignedAt,
          isRead: false,
          activity: AgendaActivity(
            id: -id,
            prospectId: id,
            prospectAvatarUrl: prospect.avatarUrl,
            type: assignmentType,
            title: 'NUEVO PROSPECTO',
            prospect: prospect.name,
            description: 'Se te asignó un nuevo prospecto.',
            date: assignedAt,
            status: AgendaStatus.pending,
            hasReminder: false,
            reminderMinutes: 0,
          ),
        ),
      );
    }
    notifications.sort((a, b) => b.reminderAt.compareTo(a.reminderAt));
    return notifications;
  }

  void _scheduleInboxRefresh(
    List<ActivityNotification> upcoming,
    DateTime now,
  ) {
    _nextInboxTimer?.cancel();
    if (upcoming.isEmpty) return;
    final delay = upcoming.first.reminderAt.difference(now);
    _nextInboxTimer = Timer(
      delay.isNegative ? Duration.zero : delay + const Duration(seconds: 1),
      () => syncActivities(
        _lastActivities,
        userId: _scope?.userId,
        developmentId: _scope?.developmentId,
      ),
    );
  }

  static int _notificationId(int activityId) =>
      _notificationIdOffset + (activityId % 1000000000);
}
