import 'package:flutter/material.dart';

import 'prospect_models.dart';

class ProspectFilters {
  static const priorities = ['Caliente', 'Tibio', 'Frío'];
  static const outcomes = [
    'Contestó',
    'No contestó',
    'Cita programada',
    'Sin contacto',
  ];
  static const sorts = [
    'Próximo contacto',
    'Último contacto',
    'Prioridad',
    'Asignación más reciente',
    'Asignación más antigua',
    'Nombre',
  ];
  String? nextContact;
  String? assignment;
  DateTimeRange? range;
  Set<String> temperatures;
  Set<String> results;
  String sort;

  ProspectFilters({
    this.nextContact,
    this.assignment,
    this.range,
    Set<String>? temperatures,
    Set<String>? results,
    this.sort = 'Último contacto',
  }) : temperatures = {...temperatures ?? priorities.toSet()},
       results = {...results ?? outcomes.toSet()};

  ProspectFilters copy() => ProspectFilters(
    nextContact: nextContact,
    assignment: assignment,
    range: range,
    temperatures: temperatures,
    results: results,
    sort: sort,
  );
  bool get active =>
      nextContact != null ||
      assignment != null ||
      temperatures.length != priorities.length ||
      results.length != outcomes.length;

  bool matches(ProspectRecord p, DateTime now) {
    final today = DateUtils.dateOnly(now);
    final next = p.nextContact;
    if (!temperatures.contains(p.temperature) ||
        !results.contains(p.lastContactResult)) {
      return false;
    }
    if (nextContact == 'Sin programar' && next != null) return false;
    if (nextContact != null && nextContact != 'Sin programar') {
      if (next == null) return false;
      final start = nextContact == 'Esta semana'
          ? DateTime(today.year, today.month, today.day - today.weekday + 1)
          : DateTime(
              today.year,
              today.month,
              today.day + (nextContact == 'Mañana' ? 1 : 0),
            );
      final end = DateTime(
        start.year,
        start.month,
        start.day + (nextContact == 'Esta semana' ? 7 : 1),
      );
      if (next.isBefore(start) || !next.isBefore(end)) return false;
    }
    if (assignment != null) {
      final assigned = p.assignedAt;
      if (assigned == null) return false;
      DateTime start;
      DateTime end;
      if (assignment == 'Rango personalizado') {
        if (range == null) return false;
        start = DateUtils.dateOnly(range!.start);
        end = DateTime(range!.end.year, range!.end.month, range!.end.day + 1);
      } else {
        final days = switch (assignment) {
          'Ayer' => 1,
          'Últimos 7 días' => 6,
          'Últimos 30 días' => 29,
          _ => 0,
        };
        start = DateTime(today.year, today.month, today.day - days);
        end = assignment == 'Ayer'
            ? today
            : DateTime(today.year, today.month, today.day + 1);
      }
      if (assigned.isBefore(start) || !assigned.isBefore(end)) return false;
    }
    return true;
  }

  int compare(ProspectRecord a, ProspectRecord b) {
    int dates(DateTime? x, DateTime? y, {bool reverse = false}) {
      if (x == null) return y == null ? 0 : 1;
      if (y == null) return -1;
      return reverse ? y.compareTo(x) : x.compareTo(y);
    }

    final result = switch (sort) {
      'Próximo contacto' => dates(a.nextContact, b.nextContact),
      'Prioridad' =>
        priorities
            .indexOf(a.temperature)
            .compareTo(priorities.indexOf(b.temperature)),
      'Asignación más reciente' => dates(
        a.assignedAt,
        b.assignedAt,
        reverse: true,
      ),
      'Asignación más antigua' => dates(a.assignedAt, b.assignedAt),
      'Nombre' => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      _ => a.daysSinceContact.compareTo(b.daysSinceContact),
    };
    return result == 0 ? a.name.compareTo(b.name) : result;
  }
}
