import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_filters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/home_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospects_screen.dart';

void main() {
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
          body: ProspectsScreen(loadProspects: () async => demoProspects),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Filtros activos'), findsNothing);
    if (clearDefault) {
      await tester.tap(find.byTooltip('Filtrar prospectos'));
      await tester.pumpAndSettle();
      for (final priority in ['Frío', 'Sin calificar']) {
        final field = find.widgetWithText(CheckboxListTile, priority);
        await tester.ensureVisible(field);
        await tester.tap(field);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('VER 6 RESULTADOS'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'Seller preset is visible and uses the same predicate as the list',
    (tester) async {
      await openProspects(tester, clearDefault: false);
      final filters = ProspectFilters.forSeller();
      final count = demoProspects
          .where((p) => filters.matches(p, DateTime.now()))
          .length;
      expect(find.text('MOSTRANDO $count PROSPECTOS'), findsOneWidget);
      await tester.tap(find.byTooltip('Filtrar prospectos'));
      await tester.pumpAndSettle();
      expect(find.text('Por atender'), findsNothing);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Caliente'),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Tibio'),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Frío'),
            )
            .value,
        isFalse,
      );
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
    expect(find.text('MOSTRANDO 1 PROSPECTOS'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '9980000001');
    await tester.pumpAndSettle();
    expect(find.text('BETSUA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Status filters and empty state can be reset', (tester) async {
    await openProspects(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Venta realizada'));
    await tester.pumpAndSettle();
    expect(find.text('No se encontraron prospectos'), findsOneWidget);
    await tester.tap(find.text('Limpiar filtros'));
    await tester.pumpAndSettle();
    final defaultCount = demoProspects
        .where((p) => ProspectFilters.forSeller().matches(p, DateTime.now()))
        .length;
    expect(find.text('MOSTRANDO $defaultCount PROSPECTOS'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Nuevo'));
    await tester.pumpAndSettle();
    expect(find.text('JUAN UCH'), findsOneWidget);
    expect(find.text('BETSUA'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Navbar opens prospects and preserves its filters', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Iconsax.profile_2user_copy));
    await tester.pumpAndSettle();
    expect(find.text('MIS PROSPECTOS'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Nuevo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Iconsax.home_2_copy));
    await tester.pumpAndSettle();
    expect(find.text('BIENVENIDO'), findsOneWidget);
    await tester.tap(find.byIcon(Iconsax.profile_2user_copy));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Nuevo'))
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
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
    expect(find.text('MOSTRANDO 1 PROSPECTOS'), findsOneWidget);
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
    expect(find.text('9980000006'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
