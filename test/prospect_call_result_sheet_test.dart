import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_call_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exige resultado y consentimiento y oculta audio al rechazar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectCallResultSheet(
            name: 'Ana Pérez',
            duration: Duration(minutes: 2, seconds: 3),
            phone: '9980000000',
            startedAt: DateTime(2026, 10, 29),
          ),
        ),
      ),
    );

    expect(find.text('Duración estimada · 02:03'), findsOneWidget);
    await tester.tap(find.text('REGISTRAR LLAMADA'));
    await tester.pump();
    expect(
      find.text('Selecciona el resultado y el consentimiento.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Sí, contestó'));
    await tester.tap(find.text('No aceptó'));
    await tester.pump();
    expect(find.text('VINCULAR CARPETA DE CUBE ACR'), findsNothing);
  });
}
