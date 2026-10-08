import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:callerapp_frontend/presentation/widgets/home/home_header.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('Notification inbox opens and closes at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeArea(child: HomeHeader(userName: 'Ana')),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();
      expect(find.text('NOTIFICACIONES'), findsOneWidget);
      expect(find.text('No tienes notificaciones'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Cerrar notificaciones'));
      await tester.pumpAndSettle();
      expect(find.text('No tienes notificaciones'), findsNothing);
    });
  }
}
