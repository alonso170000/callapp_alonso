import 'package:flutter/material.dart';

import 'prospect_models.dart';

class ProspectFilters {
  factory ProspectFilters.forSeller() => ProspectFilters(
    temperatures: {'Caliente', 'Tibio'},
    sort: 'Atención prioritaria',
  );
  final Set<int>? prospectIds;
  final String? sourceLabel;
  static const priorities = ['Caliente', 'Tibio', 'Frío', 'Sin calificar'];
  static const outcomes = [
    'Contestó',
    'No contestó',
    'Cita programada',
    'Sin contacto',
  ];
  static const sorts = [
    'Atención prioritaria',
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
    Set<int>? prospectIds,
    this.sourceLabel,
    this.nextContact,
    this.assignment,
    this.range,
    Set<String>? temperatures,
    Set<String>? results,
    this.sort = 'Último contacto',
  }) : prospectIds = prospectIds == null ? null : {...prospectIds},
       temperatures = {...temperatures ?? priorities.toSet()},
       results = {...results ?? outcomes.toSet()};

  ProspectFilters copy() => ProspectFilters(
    prospectIds: prospectIds,
    sourceLabel: sourceLabel,
    nextContact: nextContact,
    assignment: assignment,
    range: range,
    temperatures: temperatures,
    results: results,
    sort: sort,
  );
  bool get active =>
      prospectIds != null ||
      nextContact != null ||
      assignment != null ||
      temperatures.length != priorities.length ||
      results.length != outcomes.length;

  bool get isSellerDefault =>
      prospectIds == null &&
      nextContact == null &&
      assignment == null &&
      temperatures.length == 2 &&
      temperatures.containsAll({'Caliente', 'Tibio'}) &&
      results.length == outcomes.length &&
      results.containsAll(outcomes) &&
      sort == 'Atención prioritaria';

  bool matches(ProspectRecord p, DateTime now) {
    if (prospectIds != null && !prospectIds!.contains(p.id)) return false;
    final today = DateUtils.dateOnly(now);
    final next = p.nextContact;
    if ((temperatures.length != priorities.length &&
            !temperatures.contains(p.temperature)) ||
        (results.length != outcomes.length &&
            !results.contains(p.lastContactResult))) {
      return false;
    }
    if (nextContact == 'Atrasados' && (next == null || !next.isBefore(now))) {
      return false;
    }
    if (nextContact == 'Sin programar' && next != null) return false;
    if (nextContact != null &&
        nextContact != 'Sin programar' &&
        nextContact != 'Atrasados') {
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

  int compare(ProspectRecord a, ProspectRecord b, {DateTime? now}) {
    final current = now ?? DateTime.now();
    int dates(DateTime? x, DateTime? y, {bool reverse = false}) {
      if (x == null) return y == null ? 0 : 1;
      if (y == null) return -1;
      return reverse ? y.compareTo(x) : x.compareTo(y);
    }

    final result = switch (sort) {
      'Atención prioritaria' => _attention(a, b, current),
      'Próximo contacto' => dates(a.nextContact, b.nextContact),
      'Prioridad' =>
        (priorities.contains(a.temperature)
                ? priorities.indexOf(a.temperature)
                : priorities.length)
            .compareTo(
              priorities.contains(b.temperature)
                  ? priorities.indexOf(b.temperature)
                  : priorities.length,
            ),
      'Asignación más reciente' => dates(
        a.assignedAt,
        b.assignedAt,
        reverse: true,
      ),
      'Asignación más antigua' => dates(a.assignedAt, b.assignedAt),
      'Nombre' => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      'Último contacto' => dates(a.lastCallAt, b.lastCallAt, reverse: true),
      _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    };
    return result == 0 ? a.name.compareTo(b.name) : result;
  }

  int _attention(ProspectRecord a, ProspectRecord b, DateTime now) {
    int group(ProspectRecord p) {
      if (p.status.trim().toLowerCase() == 'venta realizada') return 5;
      if (p.nextContact != null && p.nextContact!.isBefore(now)) return 0;
      if (p.nextContact != null && DateUtils.isSameDay(p.nextContact, now)) {
        return 1;
      }
      if (p.status.trim().toLowerCase() == 'nuevo') return 2;
      return 3;
    }

    var result = group(a).compareTo(group(b));
    if (result != 0) return result;
    if (group(a) <= 1) {
      result = a.nextContact!.compareTo(b.nextContact!);
      if (result != 0) return result;
    }
    int priority(ProspectRecord p) {
      final index = priorities.indexOf(p.temperature);
      return index < 0 ? priorities.length : index;
    }

    result = priority(a).compareTo(priority(b));
    if (result != 0) return result;
    if (a.assignedAt == null) return b.assignedAt == null ? 0 : 1;
    if (b.assignedAt == null) return -1;
    return b.assignedAt!.compareTo(a.assignedAt!);
  }
}
