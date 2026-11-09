import 'package:flutter/material.dart';

import 'prospect_models.dart';
import 'prospect_search.dart';

enum ProspectFilterGroup {
  status,
  nextContact,
  priority,
  assignment,
  result,
  selection,
}

class ActiveFilter {
  const ActiveFilter({required this.label, required this.group});
  final String label;
  final ProspectFilterGroup group;
}

class ProspectFilters {
  factory ProspectFilters.all() => ProspectFilters();
  factory ProspectFilters.forSeller() => ProspectFilters();

  ProspectFilters({
    Set<int>? prospectIds,
    this.sourceLabel,
    this.status,
    this.nextContact,
    this.assignment,
    this.range,
    Set<String>? temperatures,
    Set<String>? results,
    this.sort = 'Atención prioritaria',
  }) : prospectIds = prospectIds == null ? null : {...prospectIds},
       temperatures = {...temperatures ?? priorities.toSet()},
       results = {...results ?? outcomes.toSet()};

  static const priorities = ['Caliente', 'Tibio', 'Frío', 'Sin calificar'];
  static const statusOrder = [
    'Nuevo',
    'Negociación',
    'Cotización',
    'Seguimiento',
    'Contactado y validado',
  ];
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

  final Set<int>? prospectIds;
  final String? sourceLabel;
  String? status;
  String? nextContact;
  String? assignment;
  DateTimeRange? range;
  Set<String> temperatures;
  Set<String> results;
  String sort;

  ProspectFilters copy() => ProspectFilters(
    prospectIds: prospectIds,
    sourceLabel: sourceLabel,
    status: status,
    nextContact: nextContact,
    assignment: assignment,
    range: range,
    temperatures: temperatures,
    results: results,
    sort: sort,
  );

  bool get active =>
      prospectIds != null ||
      status != null ||
      nextContact != null ||
      assignment != null ||
      range != null ||
      !_sameSet(temperatures, priorities) ||
      !_sameSet(results, outcomes);
  bool get hasNarrowing => active;

  bool get isSellerPreset =>
      prospectIds == null &&
      status == null &&
      nextContact == null &&
      assignment == null &&
      range == null &&
      _sameSet(temperatures, priorities) &&
      _sameSet(results, outcomes);

  bool get isAllPreset =>
      prospectIds == null &&
      status == null &&
      nextContact == null &&
      assignment == null &&
      range == null &&
      _sameSet(temperatures, priorities) &&
      _sameSet(results, outcomes);

  List<ActiveFilter> get summary {
    final filters = <ActiveFilter>[];
    if (status != null) {
      filters.add(
        ActiveFilter(
          label: 'Estatus: $status',
          group: ProspectFilterGroup.status,
        ),
      );
    }
    if (nextContact != null) {
      filters.add(
        ActiveFilter(
          label: nextContact == 'Contacto vencido'
              ? 'Contacto: Vencido'
              : 'Contacto: $nextContact',
          group: ProspectFilterGroup.nextContact,
        ),
      );
    }
    if (!_sameSet(temperatures, priorities)) {
      filters.add(
        ActiveFilter(
          label: 'Prioridad: ${_ordered(temperatures, priorities).join(', ')}',
          group: ProspectFilterGroup.priority,
        ),
      );
    }
    if (assignment != null || range != null) {
      final value = assignment == 'Rango personalizado' && range != null
          ? _formatRange(range!)
          : assignment ?? 'Rango personalizado';
      filters.add(
        ActiveFilter(
          label: 'Asignación: $value',
          group: ProspectFilterGroup.assignment,
        ),
      );
    }
    if (!_sameSet(results, outcomes)) {
      filters.add(
        ActiveFilter(
          label: 'Resultado: ${_ordered(results, outcomes).join(', ')}',
          group: ProspectFilterGroup.result,
        ),
      );
    }
    if (prospectIds != null) {
      filters.add(
        ActiveFilter(
          label: 'Selección: ${sourceLabel ?? prospectIds!.length}',
          group: ProspectFilterGroup.selection,
        ),
      );
    }
    return filters;
  }

  /// Filtros avanzados que se muestran como chips. El estatus se elige en su
  /// propia fila de chips, por lo que no se duplica aquí.
  List<ActiveFilter> get visibleSummary => summary
      .where((filter) => filter.group != ProspectFilterGroup.status)
      .toList(growable: false);

  ProspectFilters clearGroup(ProspectFilterGroup group) {
    if (group == ProspectFilterGroup.selection) {
      return ProspectFilters(
        status: status,
        nextContact: nextContact,
        assignment: assignment,
        range: range,
        temperatures: temperatures,
        results: results,
        sort: sort,
      );
    }
    final cleared = copy();
    switch (group) {
      case ProspectFilterGroup.status:
        cleared.status = null;
      case ProspectFilterGroup.nextContact:
        cleared.nextContact = null;
      case ProspectFilterGroup.priority:
        cleared.temperatures = priorities.toSet();
      case ProspectFilterGroup.assignment:
        cleared.assignment = null;
        cleared.range = null;
      case ProspectFilterGroup.result:
        cleared.results = outcomes.toSet();
      case ProspectFilterGroup.selection:
        break;
    }
    return cleared;
  }

  bool matches(ProspectRecord prospect, DateTime now) {
    if (prospectIds != null && !prospectIds!.contains(prospect.id)) {
      return false;
    }
    if (status != null &&
        ProspectSearch.normalize(prospect.status) !=
            ProspectSearch.normalize(status!)) {
      return false;
    }
    if ((!_sameSet(temperatures, priorities) &&
            !_containsNormalized(temperatures, prospect.temperature)) ||
        (!_sameSet(results, outcomes) &&
            !_containsNormalized(results, prospect.lastContactResult))) {
      return false;
    }
    final today = DateUtils.dateOnly(now);
    final next = prospect.nextContact;
    if (nextContact == 'Contacto vencido' &&
        (next == null || !next.isBefore(today))) {
      return false;
    }
    if (nextContact == 'Sin programar' && next != null) return false;
    if (nextContact != null &&
        nextContact != 'Sin programar' &&
        nextContact != 'Contacto vencido') {
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
    if (assignment != null &&
        !(assignment == 'Rango personalizado' && range == null)) {
      final assigned = prospect.assignedAt;
      if (assigned == null) return false;
      late DateTime start;
      late DateTime end;
      if (assignment == 'Rango personalizado') {
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

  int compare(ProspectRecord a, ProspectRecord b, {required DateTime now}) {
    int dates(DateTime? x, DateTime? y, {bool reverse = false}) {
      if (x == null) return y == null ? 0 : 1;
      if (y == null) return -1;
      return reverse ? y.compareTo(x) : x.compareTo(y);
    }

    final result = switch (sort) {
      'Atención prioritaria' => _attention(a, b, now),
      'Próximo contacto' => dates(a.nextContact, b.nextContact),
      'Prioridad' => _priority(a).compareTo(_priority(b)),
      'Asignación más reciente' => dates(
        a.assignedAt,
        b.assignedAt,
        reverse: true,
      ),
      'Asignación más antigua' => dates(a.assignedAt, b.assignedAt),
      'Nombre' => _byName(a, b),
      'Último contacto' => dates(a.lastCallAt, b.lastCallAt, reverse: true),
      _ => _byName(a, b),
    };
    return result == 0 ? _byName(a, b) : result;
  }

  int _attention(ProspectRecord a, ProspectRecord b, DateTime now) {
    int group(ProspectRecord prospect) {
      final normalizedStatus = ProspectSearch.normalize(prospect.status);
      if (normalizedStatus == ProspectSearch.normalize('Venta realizada')) {
        return 100;
      }
      if (prospect.nextContact != null && prospect.nextContact!.isBefore(now)) {
        return 0;
      }
      if (prospect.nextContact != null &&
          DateUtils.isSameDay(prospect.nextContact, now)) {
        return 1;
      }
      final rank = statusRank(prospect.status);
      return rank < 0 ? 2 + statusOrder.length : 2 + rank;
    }

    var result = group(a).compareTo(group(b));
    if (result != 0) return result;
    if (group(a) <= 1) {
      result = a.nextContact!.compareTo(b.nextContact!);
      if (result != 0) return result;
    }
    result = _priority(a).compareTo(_priority(b));
    if (result != 0) return result;
    if (a.assignedAt == null) return b.assignedAt == null ? 0 : 1;
    if (b.assignedAt == null) return -1;
    return b.assignedAt!.compareTo(a.assignedAt!);
  }

  static int statusRank(String value) {
    final normalized = ProspectSearch.normalize(value);
    return statusOrder.indexWhere(
      (item) => ProspectSearch.normalize(item) == normalized,
    );
  }

  static int _priority(ProspectRecord prospect) {
    final value = ProspectSearch.normalize(prospect.temperature);
    final index = priorities.indexWhere(
      (item) => ProspectSearch.normalize(item) == value,
    );
    return index < 0 ? priorities.length : index;
  }

  static int _byName(ProspectRecord a, ProspectRecord b) =>
      ProspectSearch.normalize(a.name)
          .compareTo(ProspectSearch.normalize(b.name));
  static bool _containsNormalized(Set<String> values, String value) {
    final normalized = ProspectSearch.normalize(value);
    return values.any((item) => ProspectSearch.normalize(item) == normalized);
  }

  static bool _sameSet(Set<String> values, Iterable<String> expected) {
    final actual = values.map(ProspectSearch.normalize).toSet();
    final wanted = expected.map(ProspectSearch.normalize).toSet();
    return actual.length == wanted.length && actual.containsAll(wanted);
  }

  static List<String> _ordered(Set<String> selected, List<String> order) =>
      order
          .where((item) => _containsNormalized(selected, item))
          .toList(growable: false);
  static String _formatRange(DateTimeRange range) =>
      '${_two(range.start.day)}/${_two(range.start.month)}/${range.start.year} – ${_two(range.end.day)}/${_two(range.end.month)}/${range.end.year}';
  static String _two(int value) => value.toString().padLeft(2, '0');
}
