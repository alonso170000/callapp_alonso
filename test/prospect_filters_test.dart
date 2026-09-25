import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_filters.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_filters_sheet.dart';

void main() {
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
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Caliente'));
    await tester.pumpAndSettle();
    expect(find.text('VER 2 RESULTADOS'), findsOneWidget);
    expect(initial.temperatures.length, 3);
    await tester.tap(find.byTooltip('Cerrar filtros'));
    await tester.pumpAndSettle();
    expect(applied, isNull);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Caliente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LIMPIAR FILTROS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VER 3 RESULTADOS'));
    await tester.pumpAndSettle();
    expect(applied!.active, isFalse);
    expect(tester.takeException(), isNull);
  });
}
