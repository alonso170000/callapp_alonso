import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

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
                style: const TextStyle(
                  color: AppColors.homeDeepTeal,
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 137, 118),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFF1D6), width: 3),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  color: Color(0xFFFFD486),
                  size: 48,
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 21,
            child: Container(
              width: 36,
              height: 9,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: 7,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.homeDeepTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: AppColors.homeWarmText,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
