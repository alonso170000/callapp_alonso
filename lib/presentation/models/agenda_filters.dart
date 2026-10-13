import 'agenda_models.dart';

enum AgendaTimeFilter { all, morning, afternoon }

class AgendaFilters {
  final Set<int>? activityIds;
  final String? sourceLabel;
  static const types = ['Seguimiento', 'Visita presencial', 'Tarea'];
  final Set<String> selectedTypes;
  final Set<AgendaStatus> statuses;
  String? prospect;
  AgendaTimeFilter time;

  AgendaFilters({
    Set<int>? activityIds,
    this.sourceLabel,
    Set<String>? selectedTypes,
    Set<AgendaStatus>? statuses,
    this.prospect,
    this.time = AgendaTimeFilter.all,
  }) : activityIds = activityIds == null ? null : {...activityIds},
       selectedTypes = {...selectedTypes ?? types},
       statuses = {...statuses ?? AgendaStatus.values};

  AgendaFilters copy() => AgendaFilters(
    activityIds: activityIds,
    sourceLabel: sourceLabel,
    selectedTypes: selectedTypes,
    statuses: statuses,
    prospect: prospect,
    time: time,
  );
  bool get active =>
      activityIds != null ||
      selectedTypes.length != types.length ||
      statuses.length != AgendaStatus.values.length ||
      prospect != null ||
      time != AgendaTimeFilter.all;

  bool matches(AgendaActivity activity) =>
      (activityIds == null || activityIds!.contains(activity.id)) &&
      selectedTypes.any(
        (type) =>
            type.toUpperCase() ==
            (activity.type ?? activity.title).toUpperCase(),
      ) &&
      statuses.contains(activity.status) &&
      (prospect == null || prospect == activity.prospect) &&
      switch (time) {
        AgendaTimeFilter.all => true,
        AgendaTimeFilter.morning => activity.date.hour < 12,
        AgendaTimeFilter.afternoon => activity.date.hour >= 12,
      };
}
