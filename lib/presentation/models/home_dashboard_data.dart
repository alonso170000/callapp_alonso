import 'package:flutter/material.dart';

import 'agenda_models.dart';
import 'home_models.dart';
import 'prospect_models.dart';

class HomeTodayEntry {
  final ProspectRecord prospect;
  final AgendaActivity activity;
  final ProspectActivityMarker? marker;

  const HomeTodayEntry({
    required this.prospect,
    required this.activity,
    required this.marker,
  });
}

/// Builds the activity metrics shown on the home dashboard.
class HomeDashboardData {
  HomeDashboardData(
    this.prospects,
    this.activities,
    this.now, {
    DateTime? selectedDate,
  }) : selectedDate = DateUtils.dateOnly(selectedDate ?? now);
  final DateTime selectedDate;
  final List<ProspectRecord> prospects;
  final List<AgendaActivity> activities;
  final DateTime now;

  bool isCall(AgendaActivity a) =>
      a.type == 'llamada' || (a.type == 'seguimiento' && a.medium == 'llamada');
  bool isTrackedFollowUp(AgendaActivity a) {
    final type = (a.type ?? a.title).trim().toLowerCase();
    if (type == 'llamada') return true;
    if (type != 'seguimiento') return false;
    const trackedMedia = {'llamada', 'whatsapp', 'facebook', 'correo'};
    return trackedMedia.contains(a.medium?.trim().toLowerCase());
  }

  bool isOpen(AgendaActivity a) =>
      a.status == AgendaStatus.pending || a.status == AgendaStatus.overdue;
  bool isToday(DateTime date) => DateUtils.isSameDay(date, selectedDate);
  DateTime get cutoff {
    final end = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day + 1,
    );
    return end.isBefore(now) ? end : now;
  }

  List<AgendaActivity> get callsToday =>
      activities.where((a) => isCall(a) && isToday(a.date)).toList();
  List<AgendaActivity> get followUpsToday =>
      activities.where((a) => isTrackedFollowUp(a) && isToday(a.date)).toList();
  int get completed =>
      followUpsToday.where((a) => a.status == AgendaStatus.completed).length;
  int get pending => followUpsToday.where(isOpen).length;
  List<AgendaActivity> get overdueFollowUps =>
      activities
          .where(
            (a) => isTrackedFollowUp(a) && isOpen(a) && a.date.isBefore(cutoff),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  List<ProspectRecord> get newProspects =>
      prospects.where((p) => p.status.trim().toLowerCase() == 'nuevo').toList()
        ..sort((a, b) {
          if (a.assignedAt == null) {
            return b.assignedAt == null ? a.name.compareTo(b.name) : 1;
          }
          if (b.assignedAt == null) return -1;
          final result = b.assignedAt!.compareTo(a.assignedAt!);
          return result == 0 ? a.name.compareTo(b.name) : result;
        });
  List<ProspectRecord> prospectsFor(Iterable<AgendaActivity> source) {
    final ids = <int>{};
    final byId = {
      for (final p in prospects)
        if (p.id != null) p.id: p,
    };
    return [
      for (final a in source)
        if (byId.containsKey(a.prospectId) && ids.add(a.prospectId!))
          byId[a.prospectId]!,
    ];
  }

  List<ProspectRecord> get todayProspects => prospectsFor(todayActivities);
  List<HomeTodayEntry> get todayEntries {
    final prospectsById = {
      for (final prospect in prospects)
        if (prospect.id != null) prospect.id!: prospect,
    };
    final activitiesByProspect = <int, List<AgendaActivity>>{};
    for (final activity in todayActivities) {
      final prospectId = activity.prospectId;
      if (prospectId == null || !prospectsById.containsKey(prospectId)) {
        continue;
      }
      activitiesByProspect.putIfAbsent(prospectId, () => []).add(activity);
    }

    final entries = <HomeTodayEntry>[];
    for (final group in activitiesByProspect.entries) {
      final open = group.value.where(isOpen).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final done =
          group.value
              .where((activity) => activity.status == AgendaStatus.completed)
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
      final representative = open.isNotEmpty
          ? open.first
          : done.isNotEmpty
          ? done.first
          : null;
      if (representative == null) continue;
      final marker = switch (representative.status) {
        AgendaStatus.overdue => ProspectActivityMarker.overdue,
        AgendaStatus.pending => ProspectActivityMarker.pending,
        _ => null,
      };
      entries.add(
        HomeTodayEntry(
          prospect: prospectsById[group.key]!,
          activity: representative,
          marker: marker,
        ),
      );
    }
    entries.sort((a, b) {
      final markerOrder = (a.marker == null ? 1 : 0).compareTo(
        b.marker == null ? 1 : 0,
      );
      if (markerOrder != 0) return markerOrder;
      final dateOrder = a.activity.date.compareTo(b.activity.date);
      return dateOrder != 0
          ? dateOrder
          : a.prospect.name.compareTo(b.prospect.name);
    });
    return entries;
  }

  List<AgendaActivity> get todayActivities =>
      activities
          .where(
            (activity) =>
                isToday(activity.date) &&
                activity.status != AgendaStatus.cancelled,
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  List<WeeklyCallProgress> get week {
    final today = selectedDate;
    final monday = DateTime(
      today.year,
      today.month,
      today.day - today.weekday + 1,
    );
    const labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return List.generate(7, (i) {
      final day = DateTime(monday.year, monday.month, monday.day + i);
      final calls = activities
          .where(
            (a) =>
                isCall(a) &&
                DateUtils.isSameDay(a.date, day) &&
                a.status != AgendaStatus.cancelled,
          )
          .toList();
      return WeeklyCallProgress(
        date: day,
        dayLabel: labels[i],
        calls: calls.length,
        isSelected: DateUtils.isSameDay(day, today),
        status: calls.isEmpty
            ? CallProgressStatus.missed
            : calls.every((a) => a.status == AgendaStatus.completed)
            ? CallProgressStatus.completed
            : CallProgressStatus.pending,
      );
    });
  }
}
