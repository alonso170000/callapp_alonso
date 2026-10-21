import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/widgets/notifications/notifications_sheet.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/services/notification_service.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String title;
  final ValueChanged<AgendaActivity>? onNotificationActivity;

  const HomeHeader({
    super.key,
    required this.userName,
    this.title = 'BIENVENIDO',
    this.onNotificationActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontFamily: 'BebasNeue',
                  fontSize: 34,
                  height: 0.9,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.homeDeepTeal,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  userName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.homeWarmText,
                    fontFamily: 'BebasNeue',
                    fontSize: 30,
                    height: 0.95,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _UserAvatar(onNotificationActivity: onNotificationActivity),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.onNotificationActivity});

  final ValueChanged<AgendaActivity>? onNotificationActivity;

  Future<void> _openNotifications(BuildContext context) async {
    final activity = await showNotificationsSheet(context);
    if (activity != null) onNotificationActivity?.call(activity);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NotificationService.instance,
      builder: (context, _) {
        final unread = NotificationService.instance.unreadCount;
        return SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                right: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 137, 118),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Iconsax.user,
                      color: Color(0xFFFFD486),
                      size: 48,
                    ),
                  ),
                ),
              ),
              Positioned(
                key: unread > 0
                    ? const ValueKey('notification-unread-badge')
                    : null,
                right: 0,
                bottom: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: unread > 0
                        ? AppColors.homeNotificationBadge
                        : AppColors.homeDeepTeal,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(
                        color: Theme.of(context).colorScheme.surface,
                        width: 3,
                      ),
                    ),
                  ),
                  child: IconButton(
                    tooltip: 'Notificaciones',
                    padding: EdgeInsets.zero,
                    onPressed: () => _openNotifications(context),
                    icon: unread > 0
                        ? Text(
                            unread > 99 ? '99+' : '$unread',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'BebasNeue',
                              fontSize: 17,
                              height: 1,
                            ),
                          )
                        : const Icon(
                            Icons.notifications_rounded,
                            color: AppColors.homeWarmText,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
