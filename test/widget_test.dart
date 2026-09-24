import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:callerapp_frontend/main.dart';

void main() {
  testWidgets('navigates from login to home', (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    expect(find.text('Inicia\nsesión'), findsOneWidget);

    await tester.enterText(
      find.byType(EditableText).at(0),
      'leonardo@example.com',
    );
    await tester.enterText(find.byType(EditableText).at(1), '123456');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('BIENVENIDO'), findsOneWidget);
    expect(find.text('LEONARDO PÉREZ'), findsOneWidget);
    expect(find.text('Llamadas\nRealizadas'), findsOneWidget);
    expect(find.text('Prospectos del día'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
