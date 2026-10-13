import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_filters.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_filters_sheet.dart';

void main() {
  test(
    'Seller default includes actionable leads and orders urgent contacts first',
    () {
      final now = DateTime(2026, 10, 16, 12);
      ProspectRecord lead(
        String name, {
        String status = 'Seguimiento',
        String priority = 'Caliente',
        DateTime? next,
      }) => ProspectRecord(
        name: name,
        phone: '',
        email: '',
        status: status,
        temperature: priority,
        nextContact: next,
        avatarColor: Colors.teal,
        statusColor: Colors.orange,
      );
      final overdue = lead('Vencido', next: DateTime(2026, 10, 15));
      final today = lead('Hoy', next: DateTime(2026, 10, 16, 17));
      final fresh = lead('Nuevo', status: 'Nuevo');
      final hot = lead('Caliente', priority: 'Caliente');
      final cold = lead('Frío', priority: 'Frío');
      final sale = lead('Venta', status: 'Venta realizada', priority: 'Frío');
      final filter = ProspectFilters.forSeller();
      final result =
          [
              cold,
              hot,
              sale,
              fresh,
              today,
              overdue,
            ].where((p) => filter.matches(p, now)).toList()
            ..sort((a, b) => filter.compare(a, b, now: now));
      expect(result.map((p) => p.name), [
        'Vencido',
        'Hoy',
        'Nuevo',
        'Caliente',
      ]);
      expect(filter.copy().temperatures, {'Caliente', 'Tibio'});
      expect(ProspectFilters().matches(cold, now), isTrue);
    },
  );
  test('Overdue uses actual contact time and last-contact sort uses recorded dates', () {
    final now = DateTime(2026, 10, 16, 12);
    ProspectRecord lead(DateTime? next, DateTime? last) => ProspectRecord(
      name: 'Test',
      phone: '',
      email: '',
      status: 'Seguimiento',
      temperature: 'Caliente',
      nextContact: next,
      lastCallAt: last,
      avatarColor: Colors.teal,
      statusColor: Colors.orange,
    );
    final filters = ProspectFilters(nextContact: 'Atrasados');
    expect(
      filters.matches(
        lead(now.subtract(const Duration(minutes: 1)), null),
        now,
      ),
      isTrue,
    );
    expect(
      filters.matches(lead(now.add(const Duration(minutes: 1)), null), now),
      isFalse,
    );
    expect(filters.matches(lead(null, null), now), isFalse);
    final sorter = ProspectFilters(sort: 'Último contacto');
    expect(
      sorter.compare(
        lead(null, now),
        lead(null, now.subtract(const Duration(days: 1))),
      ),
      lessThan(0),
    );
    expect(sorter.compare(lead(null, null), lead(null, now)), greaterThan(0));
  });
  ProspectRecord record({DateTime? next, DateTime? assigned}) => ProspectRecord(
    name: 'Test',
    phone: '',
    email: '',
    status: 'Nuevo',
    temperature: 'Caliente',
    avatarColor: Colors.red,
    statusColor: Colors.red,
    appointment: DateTime(2026),
    nextContact: next,
    assignedAt: assigned,
    lastContactResult: 'Contestó',
  );
  test('Contact and assignment boundaries and empty selections', () {
    final now = DateTime(2026, 10, 16, 18);
    final filters = ProspectFilters(nextContact: 'Hoy');
    expect(filters.matches(record(next: DateTime(2026, 10, 16)), now), isTrue);
    expect(filters.matches(record(next: DateTime(2026, 10, 17)), now), isFalse);
    filters.nextContact = 'Sin programar';
    expect(filters.matches(record(), now), isTrue);
    filters.assignment = 'Rango personalizado';
    filters.range = DateTimeRange(
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 5),
    );
    expect(
      filters.matches(record(assigned: DateTime(2026, 10, 5, 23, 59)), now),
      isTrue,
    );
    expect(
      filters.matches(record(assigned: DateTime(2026, 10, 6)), now),
      isFalse,
    );
    filters.temperatures.clear();
    expect(
      filters.matches(record(assigned: DateTime(2026, 10, 5)), now),
      isFalse,
    );
  });
  testWidgets('Sheet edits a draft, closes without applying and resets', (
    tester,
  ) async {
    final initial = ProspectFilters();
    ProspectFilters? applied;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                applied = await showModalBottomSheet<ProspectFilters>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SizedBox(
                    height: 500,
                    child: ProspectFiltersSheet(
                      initial: initial,
                      count: (filters) => filters.temperatures.length,
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(CheckboxListTile, 'Caliente'),
    );
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Caliente'));
    await tester.pumpAndSettle();
    expect(
      find.text('VER ${ProspectFilters.priorities.length - 1} RESULTADOS'),
      findsOneWidget,
    );
    expect(initial.temperatures.length, ProspectFilters.priorities.length);
    await tester.tap(find.byTooltip('Cerrar filtros'));
    await tester.pumpAndSettle();
    expect(applied, isNull);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(CheckboxListTile, 'Caliente'),
    );
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Caliente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LIMPIAR FILTROS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VER 2 RESULTADOS'));
    await tester.pumpAndSettle();
    expect(applied!.temperatures, {'Caliente', 'Tibio'});
    expect(applied!.sort, 'Atención prioritaria');
    expect(applied!.nextContact, isNull);
    expect(applied!.assignment, isNull);
    expect(tester.takeException(), isNull);
  });
}
