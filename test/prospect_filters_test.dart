import 'package:callerapp_frontend/presentation/models/prospect_filters.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProspectRecord record({
    String name = 'Álvaro',
    String status = 'Nuevo',
    String temperature = 'Caliente',
    String result = 'Contestó',
    DateTime? next,
    DateTime? assigned,
  }) => ProspectRecord(
    name: name,
    phone: '',
    email: '',
    status: status,
    temperature: temperature,
    avatarColor: Colors.red,
    statusColor: Colors.red,
    nextContact: next,
    assignedAt: assigned,
    lastContactResult: result,
  );

  test('presets, summary and clearGroup preserve unrelated filters', () {
    final seller = ProspectFilters.forSeller();
    expect(seller.isSellerPreset, isTrue);
    seller.sort = 'Nombre';
    expect(seller.isSellerPreset, isTrue, reason: 'El preset ignora el orden');
    expect(ProspectFilters.all().isAllPreset, isTrue);

    final filters = ProspectFilters(
      status: 'Nuevo',
      nextContact: 'Hoy',
      assignment: 'Últimos 7 días',
      temperatures: {'Caliente', 'Tibio'},
      results: {'Contestó'},
      prospectIds: {1},
      sourceLabel: 'Nuevos',
    );
    expect(
      filters.summary.map((item) => item.label),
      containsAll([
        'Estatus: Nuevo',
        'Contacto: Hoy',
        'Prioridad: Caliente, Tibio',
        'Asignación: Últimos 7 días',
        'Resultado: Contestó',
        'Selección: Nuevos',
      ]),
    );
    final cleared = filters.clearGroup(ProspectFilterGroup.assignment);
    expect(cleared.assignment, isNull);
    expect(cleared.range, isNull);
    expect(cleared.status, 'Nuevo');
  });

  test('matching is case and accent insensitive', () {
    final now = DateTime(2026, 10, 16, 12);
    final filter = ProspectFilters(
      status: 'NUEVO',
      temperatures: {'caliente'},
      results: {'CONTESTO'},
    );
    for (final value in ['caliente', 'CALIENTE', 'Caliente']) {
      expect(filter.matches(record(temperature: value), now), isTrue);
    }
  });

  test('complete result selection does not hide server result variants', () {
    final now = DateTime(2026, 10, 16, 12);
    final filters = ProspectFilters.all();
    expect(filters.matches(record(result: 'Contacto exitoso'), now), isTrue);
    expect(filters.matches(record(result: 'Sin respuesta'), now), isTrue);
  });

  test('Contacto vencido uses the start of today as boundary', () {
    final now = DateTime(2026, 10, 16, 12);
    final filter = ProspectFilters(nextContact: 'Contacto vencido');
    expect(
      filter.matches(record(next: DateTime(2026, 10, 15, 23, 30)), now),
      isTrue,
    );
    expect(filter.matches(record(next: DateTime(2026, 10, 16)), now), isFalse);
    expect(filter.summary.single.label, 'Contacto: Vencido');
  });

  test('custom range without a range does not restrict', () {
    final filter = ProspectFilters(assignment: 'Rango personalizado');
    expect(filter.matches(record(), DateTime(2026, 10, 16)), isTrue);
  });

  test('custom range summary and matching are inclusive', () {
    final filter = ProspectFilters(
      assignment: 'Rango personalizado',
      range: DateTimeRange(
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 10, 5),
      ),
    );
    expect(filter.summary.single.label, 'Asignación: 01/10/2026 – 05/10/2026');
    expect(
      filter.matches(
        record(assigned: DateTime(2026, 10, 5, 23, 59)),
        DateTime(2026, 10, 16),
      ),
      isTrue,
    );
  });

  test('compare requires now and uses normalized alphabetical tiebreaker', () {
    final filter = ProspectFilters(sort: 'Nombre');
    final values = [record(name: 'Zoe'), record(name: 'Álvaro')]
      ..sort((a, b) => filter.compare(a, b, now: DateTime(2026, 10, 16)));
    expect(values.map((item) => item.name), ['Álvaro', 'Zoe']);
  });
}
