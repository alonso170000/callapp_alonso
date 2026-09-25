import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';

class ProfileSettingRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onPressed;
  final Color titleColor;
  const ProfileSettingRow({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.actionLabel,
    required this.onPressed,
    this.titleColor = AppColors.homeWarmText,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: profileHeading.copyWith(color: titleColor, fontSize: 18),
            ),
            Text(
              value.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'BebasNeue',
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: actionLabel,
        onPressed: onPressed,
        icon: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.homeBackground,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryColor),
        ),
      ),
    ],
  );
}
