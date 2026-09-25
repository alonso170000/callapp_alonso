import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/home_models.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

import 'prospect_avatar.dart';

class ProspectTile extends StatelessWidget {
  final ProspectItem item;

  const ProspectTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ProspectAvatar(item: item),
              const Positioned(right: -3, top: -4, child: _CallBadge()),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontFamily: 'SulphurPoint',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 0.95,
            ),
          ),
          if (item.subtitle != null)
            Text(
              item.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontFamily: 'SulphurPoint',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                height: 0.95,
              ),
            ),
          if (item.timeLabel != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF77893),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.timeLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'SulphurPoint',
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CallBadge extends StatelessWidget {
  const _CallBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 29,
      height: 29,
      decoration: BoxDecoration(
        color: AppColors.homeBadge,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.phone_in_talk_rounded,
        color: Colors.black,
        size: 17,
      ),
    );
  }
}
