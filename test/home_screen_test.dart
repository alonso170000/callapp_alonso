import 'package:callerapp_frontend/presentation/screens/main_screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('Inicio scrolls without overflow at $width px', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(find.text('Llamadas atrasadas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
