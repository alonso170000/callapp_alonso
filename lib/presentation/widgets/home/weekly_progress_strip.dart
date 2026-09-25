import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/presentation/models/home_models.dart';

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
