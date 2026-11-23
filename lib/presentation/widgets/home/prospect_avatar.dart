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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
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
          if (item.marker case final marker?)
            Positioned(
              right: 0,
              bottom: 0,
              child: Semantics(
                label: marker == ProspectActivityMarker.overdue
                    ? 'Actividad atrasada'
                    : 'Actividad pendiente',
                child: Container(
                  key: Key('prospect-activity-marker-${item.name}'),
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.homeOrangeSection,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: marker == ProspectActivityMarker.overdue
                          ? AppColors.homeActivityOverdue
                          : AppColors.homeActivityPending,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
