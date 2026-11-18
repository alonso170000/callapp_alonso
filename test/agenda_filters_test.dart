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

  test('normaliza tipos de API, llamadas y nombres de prospecto', () {
    final visit = AgendaActivity(
      type: 'visita_presencial',
      title: 'VISITA',
      prospect: '  Ana Pérez  ',
      description: '',
      date: DateTime(2026, 11, 18, 10),
      status: AgendaStatus.pending,
    );
    final visitFilters = AgendaFilters(
      selectedTypes: {'Visita presencial'},
      prospect: 'ana pérez',
    );
    expect(visitFilters.matches(visit), isTrue);

    final call = AgendaActivity(
      type: 'llamada',
      title: 'LLAMADA',
      prospect: 'Ana',
      description: '',
      date: DateTime(2026, 11, 18, 12),
      status: AgendaStatus.pending,
    );
    expect(AgendaFilters(selectedTypes: {'Seguimiento'}).matches(call), isTrue);
  });

  testWidgets('abrir filtros libera la selección oculta de un atajo', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final controller = AgendaController();
    addTearDown(controller.dispose);
    final activities = [
      for (final id in [1, 2])
        AgendaActivity(
          id: id,
          type: 'tarea',
          title: 'TAREA',
          prospect: 'Prospecto $id',
          description: '',
          date: DateTime(today.year, today.month, today.day, 9 + id),
          status: AgendaStatus.pending,
        ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaScreen(
            controller: controller,
            loadActivities: () async => activities,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.showFromHome(today, {1}, 'Atajo');
    await tester.pumpAndSettle();
    expect(find.text('MOSTRANDO 1 ACTIVIDAD'), findsOneWidget);

    await tester.tap(find.byTooltip('Filtrar actividades'));
    await tester.pumpAndSettle();
    expect(find.text('VER 2 RESULTADOS'), findsOneWidget);
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('Filters apply, cancel and clear at $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgendaScreen(
              loadActivities: () async =>
                  demoAgendaActivities(DateUtils.dateOnly(DateTime.now())),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Filtrar actividades'));
      await tester.pumpAndSettle();
      expect(find.text('VER 3 RESULTADOS'), findsOneWidget);
      await tester.tap(find.text('Todos los prospectos'));
      await tester.pumpAndSettle();
      final prospectSearch = find.byKey(
        const ValueKey('agenda-prospect-search'),
      );
      expect(prospectSearch, findsOneWidget);
      await tester.enterText(prospectSearch, 'prospecto inexistente');
      await tester.pumpAndSettle();
      expect(find.text('No se encontraron prospectos'), findsOneWidget);
      await tester.tap(find.byTooltip('Limpiar búsqueda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todos los prospectos').last);
      await tester.pumpAndSettle();
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
