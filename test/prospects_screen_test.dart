import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_filters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospects_screen.dart';

void main() {
  final now = DateTime(2026, 11, 2, 12);

  Future<void> openProspects(
    WidgetTester tester, {
    bool clearDefault = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectsScreen(
            loadProspects: () async => demoProspects,
            now: () => now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Filtros activos'), findsNothing);
    if (clearDefault) {
      await tester.tap(find.byTooltip('Filtrar prospectos'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Todos').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('VER 6 RESULTADOS'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'Seller preset is visible and uses the same predicate as the list',
    (tester) async {
      await openProspects(tester, clearDefault: false);
      final filters = ProspectFilters.forSeller();
      final count = demoProspects.where((p) => filters.matches(p, now)).length;
      expect(find.text('MOSTRANDO $count PROSPECTOS'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Por atender'), findsOneWidget);
      final activeFiltersScroller = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('prospect-active-filters')),
      );
      expect(activeFiltersScroller.scrollDirection, Axis.horizontal);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('prospect-active-filters')),
          matching: find.byType(Wrap),
        ),
        findsNothing,
      );
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(InputChip, 'Por atender'),
          matching: find.byIcon(Icons.close_rounded),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 6 PROSPECTOS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Search handles names without accents and phone numbers', (
    tester,
  ) async {
    await openProspects(tester);
    expect(find.text('MOSTRANDO 6 PROSPECTOS'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'maria');
    await tester.pumpAndSettle();
    expect(find.text('MARÍA JOSÉ SÁNCHEZ'), findsOneWidget);
    expect(find.text('MOSTRANDO 1 PROSPECTO'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '9980000001');
    await tester.pumpAndSettle();
    expect(find.text('BETSUA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Status filters and empty state can be reset', (tester) async {
    await openProspects(tester);
    final statusScroller = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('prospect-status-filters')),
    );
    expect(statusScroller.scrollDirection, Axis.horizontal);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('prospect-status-filters')),
        matching: find.byType(Wrap),
      ),
      findsNothing,
    );
    await tester.enterText(find.byType(TextField), 'sin coincidencias');
    await tester.pumpAndSettle();
    expect(find.text('No hay prospectos con estos filtros'), findsOneWidget);
    expect(find.text('Limpiar búsqueda'), findsOneWidget);
    await tester.tap(find.text('Ver todos'));
    await tester.pumpAndSettle();
    final defaultCount = demoProspects
        .where((p) => ProspectFilters.all().matches(p, now))
        .length;
    expect(find.text('MOSTRANDO $defaultCount PROSPECTOS'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Nuevo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Nuevo'));
    await tester.pumpAndSettle();
    expect(find.text('JUAN UCH'), findsOneWidget);
    expect(find.text('BETSUA'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty assignment state offers refresh', (tester) async {
    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectsScreen(
            loadProspects: () async {
              loads++;
              return const [];
            },
            now: () => now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aún no tienes prospectos asignados'), findsOneWidget);
    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();
    expect(loads, 2);
  });

  testWidgets('Deleting one group chip preserves the other group', (
    tester,
  ) async {
    await openProspects(tester);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Nuevo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Nuevo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filtrar prospectos'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Últimos 7 días'));
    await tester.tap(find.text('Últimos 7 días'));
    await tester.pump();
    await tester.tap(find.textContaining('VER ').last);
    await tester.pumpAndSettle();
    expect(find.text('Estatus: Nuevo'), findsOneWidget);
    expect(find.text('Asignación: Últimos 7 días'), findsOneWidget);
    final activeFiltersScroller = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('prospect-active-filters')),
    );
    expect(activeFiltersScroller.scrollDirection, Axis.horizontal);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('prospect-active-filters')),
        matching: find.byType(Wrap),
      ),
      findsNothing,
    );
    await tester.ensureVisible(
      find.widgetWithText(InputChip, 'Asignación: Últimos 7 días'),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(InputChip, 'Asignación: Últimos 7 días'),
        matching: find.byIcon(Icons.close_rounded),
      ),
    );
    await tester.pump();
    expect(find.text('Asignación: Últimos 7 días'), findsNothing);
    expect(find.text('Estatus: Nuevo'), findsOneWidget);
  });

  testWidgets('Small screen supports temperature filters and contact actions', (
    tester,
  ) async {
    await openProspects(tester);
    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filtrar prospectos'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(CheckboxListTile, 'Caliente'),
    );
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Caliente'));
    await tester.ensureVisible(find.widgetWithText(CheckboxListTile, 'Tibio'));
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Tibio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VER 1 RESULTADOS'));
    await tester.pumpAndSettle();
    expect(find.text('MOSTRANDO 1 PROSPECTO'), findsOneWidget);
    final call = find.byTooltip('Llamar a María José Sánchez');
    await tester.scrollUntilVisible(
      call,
      150,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await Scrollable.ensureVisible(tester.element(call), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(call);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No se pudo verificar la agenda'),
      findsOneWidget,
    );
    expect(find.text('SÍ, LLAMAR'), findsOneWidget);
    expect(find.text('NO LLAMAR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
