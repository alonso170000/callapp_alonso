import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:callerapp_frontend/presentation/widgets/home/home_card_components.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:callerapp_frontend/resources/styles/app_themes.dart';

Widget _app(Widget child, Brightness brightness) => MaterialApp(
  theme: AppThemes.build(brightness),
  home: Scaffold(body: child),
);

BoxDecoration _arrowDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(HomeCardArrow),
          matching: find.byType(Container),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  test('la paleta conserva la flecha de Inicio y la invierte en oscuro', () {
    expect(AppPalette.light.cardArrowFill, AppColors.textDarkColor);
    expect(AppPalette.light.cardArrowForeground, AppColors.whiteColor);

    expect(AppPalette.dark.cardArrowForeground, AppColors.darkSurface);
    expect(AppPalette.dark.cardArrowFill, AppColors.whiteColor);
  });

  testWidgets('en modo claro la flecha de Inicio no cambia', (tester) async {
    await tester.pumpWidget(_app(const HomeCardArrow(), Brightness.light));
    expect(_arrowDecoration(tester).color, AppColors.textDarkColor);
    expect(tester.widget<Icon>(find.byType(Icon)).color, AppColors.whiteColor);
  });

  testWidgets('en modo oscuro la flecha de Inicio muestra cuadro oscuro', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const HomeCardArrow(), Brightness.dark));
    expect(_arrowDecoration(tester).color, AppColors.whiteColor);
    expect(tester.widget<Icon>(find.byType(Icon)).color, AppColors.darkSurface);
  });
}
