import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_deletion_request_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const ProspectDeletionRequestSheet(),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('permite seleccionar un solo motivo', (tester) async {
    await openSheet(tester);

    expect(find.text('Lead duplicado'), findsOneWidget);
    expect(
      find.text('Producto no cumple con sus expectativas'),
      findsOneWidget,
    );
    final submit = find.byKey(const ValueKey('submit-deletion-request'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.tap(find.text('Lead duplicado'));
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    expect(
      tester
          .widget<RadioListTile<ProspectDeletionReason>>(
            find.widgetWithText(
              RadioListTile<ProspectDeletionReason>,
              'Lead duplicado',
            ),
          )
          .checked,
      isTrue,
    );

    await tester.tap(find.text('Teléfono incorrecto'));
    await tester.pump();
    expect(
      tester
          .widget<RadioListTile<ProspectDeletionReason>>(
            find.widgetWithText(
              RadioListTile<ProspectDeletionReason>,
              'Lead duplicado',
            ),
          )
          .checked,
      isFalse,
    );
  });

  testWidgets('Otro exige un motivo escrito', (tester) async {
    await openSheet(tester);

    await tester.ensureVisible(find.text('Otro'));
    await tester.tap(find.text('Otro'));
    await tester.pumpAndSettle();
    final submit = find.byKey(const ValueKey('submit-deletion-request'));
    expect(find.byKey(const ValueKey('other-deletion-reason')), findsOneWidget);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('other-deletion-reason')),
      'Cambio solicitado por el cliente',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
  });
}
