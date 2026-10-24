import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';

class ProfileSettingRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onPressed;
  final Color titleColor;
  const ProfileSettingRow({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.actionLabel,
    this.onPressed,
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
      if (icon != null && actionLabel != null)
        IconButton(
          tooltip: actionLabel,
          onPressed: onPressed,
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppPalette.of(context).iconChipFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
    ],
  );
}
