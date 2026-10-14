import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/widgets/notifications/notifications_sheet.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String title;

  const HomeHeader({
    super.key,
    required this.userName,
    this.title = 'BIENVENIDO',
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
        const _UserAvatar(),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
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
                child: Icon(Iconsax.user, color: Color(0xFFFFD486), size: 48),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.homeDeepTeal,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.homeBackground, width: 3),
                ),
              ),
              child: IconButton(
                tooltip: 'Notificaciones',
                padding: EdgeInsets.zero,
                onPressed: () => showNotificationsSheet(context),
                icon: const Icon(
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
  }
}
