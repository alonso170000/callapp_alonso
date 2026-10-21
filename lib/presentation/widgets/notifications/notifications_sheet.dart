import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/notification_models.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/services/notification_service.dart';

Future<AgendaActivity?> showNotificationsSheet(BuildContext context) =>
    showModalBottomSheet<AgendaActivity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => const _NotificationsSheet(),
    );

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  Timer? _elapsedTimer;
  NotificationInboxFilter _filter = NotificationInboxFilter.all;

  @override
  void initState() {
    super.initState();
    _elapsedTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  String _sectionLabel(DateTime value, DateTime now) {
    final date = DateUtils.dateOnly(value);
    final today = DateUtils.dateOnly(now);
    if (date == today) return 'HOY';
    if (date == today.subtract(const Duration(days: 1))) return 'AYER';
    const months = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    return '${date.day} DE ${months[date.month - 1]} DE ${date.year}';
  }

  List<Widget> _notificationSections(
    List<ActivityNotification> notifications,
    DateTime now,
  ) {
    final widgets = <Widget>[];
    String? previousSection;
    for (final notification in notifications) {
      final section = _sectionLabel(notification.reminderAt, now);
      if (section != previousSection) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 14));
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
            child: Text(
              section,
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
        previousSection = section;
      }
      widgets.add(
        Dismissible(
          key: ValueKey('dismiss-notification-${notification.activityId}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) =>
              NotificationService.instance.dismiss(notification.activityId),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: AppColors.notificationDismissBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, color: Colors.white),
                Text(
                  'ELIMINAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'BebasNeue',
                  ),
                ),
              ],
            ),
          ),
          child: _NotificationCard(
            notification: notification,
            now: now,
            onTap: () async {
              await NotificationService.instance.markRead(
                notification.activityId,
              );
              if (mounted) Navigator.pop(context, notification.activity);
            },
          ),
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: AnimatedBuilder(
      animation: NotificationService.instance,
      builder: (context, _) {
        final palette = AppPalette.of(context);
        final service = NotificationService.instance;
        final notifications = service.reminders.where((notification) {
          return switch (_filter) {
            NotificationInboxFilter.all => true,
            NotificationInboxFilter.unread => !notification.isRead,
            NotificationInboxFilter.read => notification.isRead,
          };
        }).toList();
        final now = businessNow();
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .78,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'NOTIFICACIONES',
                          style: profileHeading.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar notificaciones',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                if (!service.enabled || service.permissionGranted == false)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.warmBannerFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      !service.enabled
                          ? 'Las notificaciones están desactivadas desde tu perfil.'
                          : 'Permite las notificaciones en el dispositivo para recibir alertas en tiempo real.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SulphurPoint',
                        fontSize: 15,
                        color: palette.warmBannerForeground,
                      ),
                    ),
                  ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Row(
                    children: [
                      for (final entry in {
                        NotificationInboxFilter.all: 'Todas',
                        NotificationInboxFilter.unread: 'Pendientes',
                        NotificationInboxFilter.read: 'Leídas',
                      }.entries) ...[
                        FilterChip(
                          selected: _filter == entry.key,
                          label: Text(entry.value),
                          onSelected: (_) =>
                              setState(() => _filter = entry.key),
                          selectedColor: palette.chipSelectedFill,
                          checkmarkColor: palette.chipSelectedForeground,
                          labelStyle: TextStyle(
                            fontFamily: 'SulphurPoint',
                            color: _filter == entry.key
                                ? palette.chipSelectedForeground
                                : palette.chipForeground,
                          ),
                          side: BorderSide(color: palette.chipBorder),
                        ),
                        const SizedBox(width: 7),
                      ],
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed:
                        service.reminders.any(
                          (notification) => !notification.isRead,
                        )
                        ? service.markAllRead
                        : null,
                    icon: const Icon(Icons.done_all),
                    label: const Text('Marcar todas como leídas'),
                  ),
                ),
                if (notifications.isEmpty)
                  const Flexible(child: _EmptyNotifications())
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(top: 12),
                      children: _notificationSections(notifications, now),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
      child: Column(
        children: [
          Icon(
            Iconsax.notification_copy,
            size: 66,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes notificaciones recientes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SulphurPoint',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aquí verás los recordatorios de tu agenda y los prospectos que se te asignen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SulphurPoint',
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.now,
    required this.onTap,
  });

  final ActivityNotification notification;
  final DateTime now;
  final VoidCallback onTap;

  String _two(int value) => value.toString().padLeft(2, '0');

  String get _medium => switch (notification.activity.medium) {
    'llamada' => 'LLAMADA',
    'whatsapp' => 'WHATSAPP',
    'facebook' => 'FACEBOOK',
    'correo' => 'CORREO',
    _ => '',
  };

  String get _elapsed {
    final elapsed = now.difference(notification.reminderAt);
    if (elapsed.inDays > 0) return '${elapsed.inDays}d';
    if (elapsed.inHours > 0) return '${elapsed.inHours}h';
    return '${elapsed.inMinutes.clamp(0, 59)}m';
  }

  Color get _titleColor => switch (notification.activity.type) {
    'seguimiento' => AppColors.homeYellowCard,
    NotificationService.assignmentType => AppColors.notificationAssignment,
    _ => AppColors.notificationTitleVisit,
  };

  Color get _tagColor => switch (notification.activity.type) {
    'seguimiento' => AppColors.homeYellowCard,
    NotificationService.assignmentType => AppColors.notificationAssignmentTag,
    _ => AppColors.notificationTagVisit,
  };

  @override
  Widget build(BuildContext context) {
    final activity = notification.activity;
    final date = activity.date;
    final hasProspect =
        activity.prospect.trim().isNotEmpty &&
        activity.prospect.toLowerCase() != 'actividad personal';
    return Material(
      color: AppPalette.of(context).brandFill,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('notification-${notification.activityId}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationAvatar(activity: activity),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'BebasNeue',
                              fontSize: 23,
                              height: 1,
                              color: _titleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!notification.isRead) ...[
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            key: ValueKey(
                              'new-notification-${notification.activityId}',
                            ),
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.notificationUnread,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _elapsed,
                          style: const TextStyle(
                            fontFamily: 'SulphurPoint',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (hasProspect) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.3),
                        ),
                        child: Text(
                          activity.prospect.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'BebasNeue',
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        if (_medium.isNotEmpty)
                          _NotificationTag(label: _medium, color: _tagColor),
                        _NotificationTag(
                          key: ValueKey(
                            'notification-date-${notification.activityId}',
                          ),
                          label:
                              '${_two(date.day)}/${_two(date.month)}/${date.year}',
                          color: _dateTagColor(date),
                        ),
                        _NotificationTag(
                          key: ValueKey(
                            'notification-time-${notification.activityId}',
                          ),
                          label: '${_two(date.hour)}:${_two(date.minute)}',
                          color: _timeTagColor(date),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _dateTagColor(DateTime date) {
    if (notification.activity.type == NotificationService.assignmentType) {
      return _tagColor;
    }
    return DateUtils.dateOnly(date).isBefore(DateUtils.dateOnly(now))
        ? AppColors.notificationOverdueTag
        : _tagColor;
  }

  Color _timeTagColor(DateTime date) {
    if (notification.activity.type == NotificationService.assignmentType) {
      return _tagColor;
    }
    return date.isBefore(now) ? AppColors.notificationOverdueTag : _tagColor;
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({required this.activity});

  final AgendaActivity activity;

  @override
  Widget build(BuildContext context) {
    final isFollowUp = activity.type == 'seguimiento';
    final avatarUrl = activity.prospectAvatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl,
          key: ValueKey('notification-avatar-${activity.prospectId}'),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(isFollowUp),
        ),
      );
    }
    return _fallback(isFollowUp);
  }

  Widget _fallback(bool isFollowUp) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: isFollowUp
          ? AppColors.notificationFollowUp
          : AppColors.notificationVisit,
      child: Icon(
        isFollowUp ? Icons.phone_in_talk_outlined : Icons.person,
        color: isFollowUp
            ? AppColors.notificationFollowUpIcon
            : AppColors.notificationVisitIcon,
        size: 25,
      ),
    );
  }
}

class _NotificationTag extends StatelessWidget {
  const _NotificationTag({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    color: color,
    child: Text(
      label,
      style: const TextStyle(
        fontFamily: 'BebasNeue',
        fontSize: 15,
        height: 1,
        color: Colors.black,
      ),
    ),
  );
}
