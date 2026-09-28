import 'agenda_models.dart';

enum AgendaTimeFilter { all, morning, afternoon }

class AgendaFilters {
  static const types = [
    'Seguimiento',
    'Visita presencial',
    'Tarea',
    'Recordatorio personal',
    'Llamada',
  ];
  final Set<String> selectedTypes;
  final Set<AgendaStatus> statuses;
  String? prospect;
  AgendaTimeFilter time;

  AgendaFilters({
    Set<String>? selectedTypes,
    Set<AgendaStatus>? statuses,
    this.prospect,
    this.time = AgendaTimeFilter.all,
  }) : selectedTypes = {...selectedTypes ?? types},
       statuses = {...statuses ?? AgendaStatus.values};

  AgendaFilters copy() => AgendaFilters(
    selectedTypes: selectedTypes,
    statuses: statuses,
    prospect: prospect,
    time: time,
  );
  bool get active =>
      selectedTypes.length != types.length ||
      statuses.length != AgendaStatus.values.length ||
      prospect != null ||
      time != AgendaTimeFilter.all;

  bool matches(AgendaActivity activity) =>
      selectedTypes.any(
        (type) => type.toUpperCase() == activity.title.toUpperCase(),
      ) &&
      statuses.contains(activity.status) &&
      (prospect == null || prospect == activity.prospect) &&
      switch (time) {
        AgendaTimeFilter.all => true,
        AgendaTimeFilter.morning => activity.date.hour < 12,
        AgendaTimeFilter.afternoon => activity.date.hour >= 12,
      };
}
