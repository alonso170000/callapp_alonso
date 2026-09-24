import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/home_models.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class HomeHeader extends StatelessWidget {
  final String userName;

  const HomeHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BIENVENIDO',
                style: TextStyle(
                  color: AppColors.homeDeepTeal,
                  fontFamily: 'BebasNeue',
                  fontSize: 34,
                  height: 0.9,
                ),
              ),
              const SizedBox(height: 7),
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

class WeeklyProgressStrip extends StatelessWidget {
  final List<WeeklyCallProgress> days;

  const WeeklyProgressStrip({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: days
          .map((day) => Expanded(child: _WeekDayChip(day: day)))
          .toList(),
    );
  }
}

class MetricSummaryCard extends StatelessWidget {
  final DashboardMetric metric;
  final VoidCallback? onTap;

  const MetricSummaryCard({super.key, required this.metric, this.onTap});

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      color: metric.backgroundColor,
      height: 154,
      onTap: onTap,
      child: Stack(
        children: [
          const Positioned(top: 8, right: 8, child: _ArrowButton()),
          Positioned.fill(
            left: 12,
            right: 12,
            bottom: 14,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'SulphurPoint',
                    fontSize: 54,
                    fontWeight: FontWeight.w700,
                    height: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  metric.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'SulphurPoint',
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    height: 0.9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProspectSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<ProspectItem> prospects;
  final bool showAddButton;
  final double height;
  final VoidCallback? onOpen;
  final VoidCallback? onAdd;

  const ProspectSection({
    super.key,
    required this.title,
    required this.color,
    required this.prospects,
    this.showAddButton = false,
    this.height = 166,
    this.onOpen,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return _TappableCard(
      color: color,
      height: height,
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'SulphurPoint',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
                const _ArrowButton(),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  if (showAddButton && index == 0) {
                    return _AddProspectTile(onTap: onAdd);
                  }

                  final prospectIndex = showAddButton ? index - 1 : index;
                  return ProspectTile(item: prospects[prospectIndex]);
                },
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemCount: prospects.length + (showAddButton ? 1 : 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class ProspectAvatar extends StatelessWidget {
  final ProspectItem item;

  const ProspectAvatar({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.avatarColor,
              ),
            ),
          ),
          Positioned(
            left: -10,
            top: -3,
            child: Container(width: 34, height: 64, color: item.accentColor),
          ),
          Positioned.fill(
            child: Center(
              child: Text(
                item.name.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'SulphurPoint',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 17,
            top: 29,
            child: Icon(Icons.sentiment_satisfied_alt, size: 25),
          ),
        ],
      ),
    );
  }
}

class _WeekDayChip extends StatelessWidget {
  final WeeklyCallProgress day;

  const _WeekDayChip({required this.day});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (day.status) {
      CallProgressStatus.completed => AppColors.homeDeepTeal,
      CallProgressStatus.pending => const Color(0xFF6B8E35),
      CallProgressStatus.missed => const Color(0xFFB7D1CB),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: day.isSelected ? AppColors.homeDeepTeal : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day.dayLabel,
            style: TextStyle(
              color: day.isSelected ? Colors.white : Colors.black,
              fontFamily: 'SulphurPoint',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            day.calls.toString(),
            style: TextStyle(
              color: day.isSelected ? Colors.white : Colors.black,
              fontFamily: 'SulphurPoint',
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            day.status == CallProgressStatus.missed
                ? Icons.check_circle_outline_rounded
                : Icons.check_circle_rounded,
            color: day.isSelected ? AppColors.homeWarmText : statusColor,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _AddProspectTile extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddProspectTile({this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: const SizedBox(
                width: 52,
                height: 52,
                child: Icon(Icons.add_rounded, color: Colors.black, size: 42),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agregar',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'SulphurPoint',
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Icon(
        Icons.north_east_rounded,
        color: Colors.black,
        size: 27,
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

class _TappableCard extends StatelessWidget {
  final Color color;
  final Widget child;
  final double? height;
  final VoidCallback? onTap;

  const _TappableCard({
    required this.color,
    required this.child,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: child),
      ),
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
                color: const Color(0xFFE9573F),
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
