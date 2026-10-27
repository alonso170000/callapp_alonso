import 'dart:async';

import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_call_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exposes call completion and copy actions', (tester) async {
    var copied = false;
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectCallSheet(
            name: 'María Pérez',
            phone: '9981234567',
            email: 'maria@example.com',
            onCopyPhone: () => copied = true,
            onFinish: (_) => completed = true,
          ),
        ),
      ),
    );

    expect(find.text('María Pérez'), findsOneWidget);
    expect(find.text('9981234567'), findsOneWidget);
    await tester.tap(find.text('COPIAR TELÉFONO'));
    await tester.tap(
      find.byType(Checkbox),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('finish-prospect-call')));

    expect(copied, isTrue);
    expect(completed, isTrue);
  });

  testWidgets('renders retry errors inline and clears them after success', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectCallSheet(
            name: 'María Pérez',
            phone: '9981234567',
            email: 'maria@example.com',
            onCopyPhone: () {},
            errorMessage: 'No se pudo abrir el marcador del teléfono.',
            onCallAgain: () async => ++attempts == 1
                ? 'El marcador sigue sin estar disponible.'
                : null,
          ),
        ),
      ),
    );

    expect(
      find.text('No se pudo abrir el marcador del teléfono.'),
      findsOneWidget,
    );
    await tester.tap(find.text('VOLVER A MARCAR'));
    await tester.pumpAndSettle();
    expect(
      find.text('El marcador sigue sin estar disponible.'),
      findsOneWidget,
    );
    await tester.tap(find.text('VOLVER A MARCAR'));
    await tester.pumpAndSettle();
    expect(find.text('El marcador sigue sin estar disponible.'), findsNothing);
  });

  testWidgets(
    'disables retry while it is running and closes without finishing',
    (tester) async {
      final retry = Completer<String?>();
      var completed = false;
      var closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProspectCallSheet(
              name: 'María Pérez',
              phone: '9981234567',
              email: 'maria@example.com',
              onCopyPhone: () {},
              onCallAgain: () => retry.future,
              onFinish: (_) => completed = true,
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('VOLVER A MARCAR'));
      await tester.pump();
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'VOLVER A MARCAR'),
            )
            .onPressed,
        isNull,
      );
      retry.complete(null);
      await tester.pumpAndSettle();
      await tester.tap(find.text('CERRAR'));

      expect(closed, isTrue);
      expect(completed, isFalse);
    },
  );
}
