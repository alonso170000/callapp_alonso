import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:callerapp_frontend/presentation/models/agenda_filters.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/agenda_screen.dart';

void main() {
  test('Combines filters and handles noon and empty selections', () {
    final activity = AgendaActivity(
      title: 'TAREA',
      prospect: 'ANA',
      description: '',
      date: DateTime(2026, 9, 28, 12),
      status: AgendaStatus.pending,
    );
    final filters = AgendaFilters(time: AgendaTimeFilter.morning);
    expect(filters.matches(activity), isFalse);
    filters.time = AgendaTimeFilter.afternoon;
    expect(filters.matches(activity), isTrue);
    filters.prospect = 'OTRO';
    expect(filters.matches(activity), isFalse);
    filters.prospect = 'ANA';
    filters.selectedTypes.clear();
    expect(filters.matches(activity), isFalse);
    filters.selectedTypes.add('Tarea');
    filters.statuses.clear();
    expect(filters.matches(activity), isFalse);
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('Filters apply, cancel and clear at $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AgendaScreen())),
      );
      await tester.tap(find.byTooltip('Filtrar actividades'));
      await tester.pumpAndSettle();
      expect(find.text('VER 3 RESULTADOS'), findsOneWidget);
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Seguimiento'));
      await tester.pumpAndSettle();
      expect(find.text('VER 2 RESULTADOS'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar filtros'));
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 3 ACTIVIDADES'), findsOneWidget);
      await tester.tap(find.byTooltip('Filtrar actividades'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Seguimiento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('VER 2 RESULTADOS'));
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 2 ACTIVIDADES'), findsOneWidget);
      await tester.tap(find.byTooltip('Filtrar actividades'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LIMPIAR FILTROS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('VER 3 RESULTADOS'));
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 3 ACTIVIDADES'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
