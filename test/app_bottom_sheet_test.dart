import 'package:callerapp_frontend/presentation/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    required Widget Function(BuildContext) child,
    Size size = const Size(390, 800),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Builder(builder: child)));
  }

  testWidgets('abre un BottomSheet con drag handle', (tester) async {
    await pumpHost(
      tester,
      child: (context) => TextButton(
        onPressed: () => showAppBottomSheet<void>(
          context: context,
          builder: (_) => const AppBottomSheet(child: Text('Contenido')),
        ),
        child: const Text('Abrir'),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle,
      isTrue,
    );
  });

  testWidgets('muestra título, cierre y devuelve el valor esperado', (
    tester,
  ) async {
    int? result;
    await pumpHost(
      tester,
      child: (context) => TextButton(
        onPressed: () async {
          result = await showAppBottomSheet<int>(
            context: context,
            builder: (sheetContext) => AppBottomSheet(
              title: 'Título',
              child: TextButton(
                onPressed: () => Navigator.pop(sheetContext, 7),
                child: const Text('Elegir'),
              ),
            ),
          );
        },
        child: const Text('Abrir'),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Título'), findsOneWidget);
    expect(find.byTooltip('Cerrar'), findsOneWidget);
    await tester.tap(find.text('Elegir'));
    await tester.pumpAndSettle();
    expect(result, 7);
  });

  testWidgets('AppSheetActions ejecuta ambas acciones', (tester) async {
    var secondary = 0;
    var primary = 0;
    const secondaryKey = ValueKey('secundaria');
    const primaryKey = ValueKey('primaria');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSheetActions(
            secondaryLabel: 'SECUNDARIA',
            secondaryKey: secondaryKey,
            onSecondary: () => secondary++,
            primaryLabel: 'PRIMARIA',
            primaryKey: primaryKey,
            onPrimary: () => primary++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('SECUNDARIA'));
    await tester.tap(find.text('PRIMARIA'));
    expect(secondary, 1);
    expect(primary, 1);
    expect(find.byKey(secondaryKey), findsOneWidget);
    expect(find.byKey(primaryKey), findsOneWidget);
  });

  testWidgets('título y etiquetas largas no desbordan a 320 px', (
    tester,
  ) async {
    await pumpHost(
      tester,
      size: const Size(320, 640),
      child: (context) => TextButton(
        onPressed: () => showAppBottomSheet<void>(
          context: context,
          builder: (_) => AppBottomSheet(
            title: 'Este es un título deliberadamente largo para validar dos líneas',
            footer: AppSheetActions(
              secondaryLabel: 'ACCIÓN SECUNDARIA MUY LARGA',
              onSecondary: () {},
              primaryLabel: 'ACCIÓN PRINCIPAL MUY LARGA',
              onPrimary: () {},
            ),
            child: const Text('Contenido'),
          ),
        ),
        child: const Text('Abrir'),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
