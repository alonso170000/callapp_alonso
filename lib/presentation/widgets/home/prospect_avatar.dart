import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/home_models.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class ProspectAvatar extends StatelessWidget {
  final ProspectItem item;

  const ProspectAvatar({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    const fallback = Icon(
      Icons.person,
      color: AppColors.homeWarmText,
      size: 32,
    );
    return SizedBox.square(
      dimension: 56,
      child: ClipOval(
        child: ColoredBox(
          color: item.avatarColor,
          child: item.avatarUrl == null || item.avatarUrl!.isEmpty
              ? fallback
              : Image.network(
                  item.avatarUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}
