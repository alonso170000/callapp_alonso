import 'package:callerapp_frontend/resources/styles/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('todos los botones de texto usan BebasNeue y radio 8', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.build(Brightness.light),
        home: Scaffold(
          body: Column(
            children: [
              FilledButton(onPressed: () {}, child: const Text('LLENO')),
              OutlinedButton(onPressed: () {}, child: const Text('BORDE')),
              TextButton(onPressed: () {}, child: const Text('TEXTO')),
            ],
          ),
        ),
      ),
    );

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    final styles = [
      theme.filledButtonTheme.style!,
      theme.outlinedButtonTheme.style!,
      theme.textButtonTheme.style!,
    ];

    for (final style in styles) {
      final textStyle = style.textStyle!.resolve(const <WidgetState>{})!;
      final shape = style.shape!.resolve(const <WidgetState>{});
      final minimumSize = style.minimumSize!.resolve(const <WidgetState>{})!;
      expect(textStyle.fontFamily, 'BebasNeue');
      expect(textStyle.fontSize, 18);
      expect(minimumSize.height, 44);
      expect(shape, isA<RoundedRectangleBorder>());
      expect(
        (shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(8),
      );
    }
  });
}
