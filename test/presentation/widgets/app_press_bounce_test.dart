import 'package:callerapp_frontend/presentation/widgets/app_press_bounce.dart';
import 'package:callerapp_frontend/resources/styles/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    required VoidCallback onPressed,
    bool enabled = true,
    bool disableAnimations = false,
  }) => MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData().copyWith(
        disableAnimations: disableAnimations,
      ),
      child: Scaffold(
        body: AppPressBounce(
          enabled: enabled,
          child: FilledButton(
            onPressed: onPressed,
            child: const Text('Guardar'),
          ),
        ),
      ),
    ),
  );

  testWidgets('el tap llega una sola vez al botón', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(onPressed: () => taps++));

    await tester.tap(find.text('Guardar'));

    expect(taps, 1);
  });

  testWidgets('reduce la escala al presionar y la recupera al soltar', (
    tester,
  ) async {
    await tester.pumpWidget(host(onPressed: () {}));

    final gesture = await tester.press(find.text('Guardar'));
    await tester.pump(AppMotion.pressIn);
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      0.96,
    );

    await gesture.up();
    await tester.pump(AppMotion.pressOut);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });

  testWidgets('enabled false no crea una escala animada', (tester) async {
    await tester.pumpWidget(host(onPressed: () {}, enabled: false));

    expect(find.byType(AnimatedScale), findsNothing);
    await tester.press(find.text('Guardar'));
    expect(find.byType(AnimatedScale), findsNothing);
  });

  testWidgets('quitar animaciones conserva el tap sin animar', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(onPressed: () => taps++, disableAnimations: true),
    );

    await tester.tap(find.text('Guardar'));

    expect(taps, 1);
    expect(find.byType(AnimatedScale), findsNothing);
  });
}
