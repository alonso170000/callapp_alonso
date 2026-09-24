import 'package:flutter/material.dart';

enum CallProgressStatus { completed, pending, missed }

class WeeklyCallProgress {
  final String dayLabel;
  final int calls;
  final CallProgressStatus status;
  final bool isSelected;

  const WeeklyCallProgress({
    required this.dayLabel,
    required this.calls,
    required this.status,
    this.isSelected = false,
  });
}

class DashboardMetric {
  final int value;
  final String title;
  final Color backgroundColor;

  const DashboardMetric({
    required this.value,
    required this.title,
    required this.backgroundColor,
  });
}

class ProspectItem {
  final String name;
  final String? subtitle;
  final String? timeLabel;
  final Color avatarColor;
  final Color accentColor;

  const ProspectItem({
    required this.name,
    this.subtitle,
    this.timeLabel,
    required this.avatarColor,
    required this.accentColor,
  });
}
