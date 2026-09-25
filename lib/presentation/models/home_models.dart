import 'package:callerapp_frontend/resources/colors/colors.dart';
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

// Datos de demostración del dashboard.
const List<WeeklyCallProgress> demoWeeklyProgress = [
  WeeklyCallProgress(
    dayLabel: 'Lun',
    calls: 7,
    status: CallProgressStatus.completed,
  ),
  WeeklyCallProgress(
    dayLabel: 'Mar',
    calls: 8,
    status: CallProgressStatus.pending,
  ),
  WeeklyCallProgress(
    dayLabel: 'Mie',
    calls: 9,
    status: CallProgressStatus.pending,
  ),
  WeeklyCallProgress(
    dayLabel: 'Jue',
    calls: 10,
    status: CallProgressStatus.completed,
  ),
  WeeklyCallProgress(
    dayLabel: 'Vie',
    calls: 11,
    status: CallProgressStatus.pending,
    isSelected: true,
  ),
  WeeklyCallProgress(
    dayLabel: 'Sab',
    calls: 12,
    status: CallProgressStatus.missed,
  ),
  WeeklyCallProgress(
    dayLabel: 'Dom',
    calls: 13,
    status: CallProgressStatus.missed,
  ),
];

const List<DashboardMetric> demoDashboardMetrics = [
  DashboardMetric(
    value: 0,
    title: 'Llamadas\nRealizadas',
    backgroundColor: AppColors.homeGreenCard,
  ),
  DashboardMetric(
    value: 23,
    title: 'Llamadas\nPendientes',
    backgroundColor: AppColors.homeYellowCard,
  ),
];

const List<ProspectItem> demoTodayProspects = [
  ProspectItem(
    name: 'Betsua',
    subtitle: 'Con Cita',
    timeLabel: '10:00 am',
    avatarColor: Color(0xFFBF4242),
    accentColor: Color(0xFF23C9DC),
  ),
  ProspectItem(
    name: 'Alan Do...',
    subtitle: 'Con Cita',
    timeLabel: '11:30 am',
    avatarColor: Color(0xFF81F59B),
    accentColor: Color(0xFFE753C2),
  ),
  ProspectItem(
    name: 'Juan Uch',
    subtitle: 'Con Cita',
    timeLabel: '12:30 pm',
    avatarColor: Color(0xFF078C88),
    accentColor: Color(0xFFF5DB58),
  ),
  ProspectItem(
    name: 'Manuel',
    avatarColor: Color(0xFFA08AF7),
    accentColor: Color(0xFFA08AF7),
  ),
  ProspectItem(
    name: 'Joshua',
    avatarColor: Color(0xFF93DDF2),
    accentColor: Color(0xFFF9B734),
  ),
];

const List<ProspectItem> demoNewProspects = [
  ProspectItem(
    name: 'Karina Do...',
    avatarColor: Color(0xFF86F5A0),
    accentColor: Color(0xFFE64FBF),
  ),
  ProspectItem(
    name: 'Julia Da...',
    avatarColor: Color(0xFF93DDF2),
    accentColor: Color(0xFFFFC334),
  ),
  ProspectItem(
    name: 'Vanesa L.',
    avatarColor: Color(0xFF058F8A),
    accentColor: Color(0xFFE8DA63),
  ),
  ProspectItem(
    name: 'Damian',
    avatarColor: Color(0xFFBF4242),
    accentColor: Color(0xFF23C9DC),
  ),
];

const List<ProspectItem> demoLateCalls = [
  ProspectItem(
    name: 'Julia Da...',
    avatarColor: Color(0xFFA08AF7),
    accentColor: Color(0xFFA08AF7),
  ),
  ProspectItem(
    name: 'Julia Da...',
    avatarColor: Color(0xFF93DDF2),
    accentColor: Color.fromARGB(255, 52, 89, 255),
  ),
  ProspectItem(
    name: 'Damian',
    avatarColor: Color(0xFFBF4242),
    accentColor: Color(0xFF23C9DC),
  ),
  ProspectItem(
    name: 'Karina Do...',
    avatarColor: Color(0xFF86F5A0),
    accentColor: Color(0xFFE64FBF),
  ),
  ProspectItem(
    name: 'Vanesa L.',
    avatarColor: Color(0xFF058F8A),
    accentColor: Color(0xFFE8DA63),
  ),
];
