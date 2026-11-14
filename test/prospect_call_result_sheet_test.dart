import 'package:callerapp_frontend/presentation/models/call_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_call_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<ProspectCallClosure?> openSheet(WidgetTester tester) async {
    ProspectCallClosure? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showModalBottomSheet<ProspectCallClosure>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => ProspectCallResultSheet(
                    name: 'Ana Pérez',
                    duration: const Duration(minutes: 2, seconds: 3),
                    phone: '9980000000',
                    startedAt: DateTime(2026, 10, 29, 10),
                    endedAt: DateTime(2026, 10, 29, 10, 2, 3),
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('solo exige consentimiento cuando el prospecto contestó', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text('Duración estimada · 02:03'), findsOneWidget);
    await tester.tap(find.text('GUARDAR RESULTADO'));
    await tester.pump();
    expect(find.text('Selecciona el resultado de la llamada.'), findsOneWidget);

    await tester.tap(find.text('No contestó'));
    await tester.pump();
    expect(
      find.text('¿El prospecto aceptó que se grabe la llamada?'),
      findsNothing,
    );
    expect(find.text('VINCULAR CARPETA DE CUBE ACR'), findsNothing);
    expect(find.text('CAMBIAR CARPETA DE CUBE ACR'), findsNothing);
    expect(find.text('SELECCIONAR GRABACIÓN MANUALMENTE'), findsNothing);
    expect(find.text('SEGUIR EN LA LLAMADA'), findsNothing);

    await tester.tap(find.text('GUARDAR RESULTADO'));
    await tester.pumpAndSettle();
    expect(find.text('Resultado de la llamada'), findsNothing);
  });

  testWidgets('pide consentimiento con "Sí, contestó" y lo devuelve', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(find.text('Sí, contestó'));
    await tester.pump();
    expect(
      find.text('¿El prospecto aceptó que se grabe la llamada?'),
      findsOneWidget,
    );

    await tester.tap(find.text('GUARDAR RESULTADO'));
    await tester.pump();
    expect(
      find.text('Indica si el prospecto aceptó que se grabe la llamada.'),
      findsOneWidget,
    );

    await tester.tap(find.text('No aceptó'));
    await tester.pump();
    await tester.tap(find.text('GUARDAR RESULTADO'));
    await tester.pumpAndSettle();
    expect(find.text('Resultado de la llamada'), findsNothing);
  });

  testWidgets('oculta el consentimiento al cambiar a un resultado negativo', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(find.text('Sí, contestó'));
    await tester.pump();
    expect(
      find.text('¿El prospecto aceptó que se grabe la llamada?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Buzón de voz'));
    await tester.pump();
    expect(
      find.text('¿El prospecto aceptó que se grabe la llamada?'),
      findsNothing,
    );
    expect(find.text(ProspectCallOutcome.answered.label), findsOneWidget);
  });
}
