import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/home_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospects_screen.dart';

void main() {
  Future<void> openProspects(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProspectsScreen())),
    );
    await tester.pumpAndSettle();
  }

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
    expect(find.text('MOSTRANDO 6 PROSPECTOS'), findsOneWidget);
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
    expect(find.text('TUS PROSPECTOS'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Nuevo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Iconsax.home_2_copy));
    await tester.pumpAndSettle();
    expect(find.text('BIENVENIDO'), findsOneWidget);
    await tester.tap(find.byIcon(Iconsax.profile_2user_copy));
    await tester.pumpAndSettle();
    expect(find.text('MOSTRANDO 1 PROSPECTOS'), findsOneWidget);
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
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Caliente'));
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
    await tester.tap(call);
    await tester.pumpAndSettle();
    expect(find.text('9980000006'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
