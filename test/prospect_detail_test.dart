import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospect_detail_screen.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('Multiple sections and follow-up at $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(home: ProspectDetailScreen(prospect: demoProspects[1])),
      );
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Seguimiento'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Discovery'))
            .selected,
        isTrue,
      );
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Historial'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Historial'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Seguimiento'))
            .selected,
        isTrue,
      );
      await tester.tap(find.text('Registrar seguimiento'));
      await tester.pumpAndSettle();
      expect(find.text('Acerca del seguimiento'), findsOneWidget);
      final save = find.widgetWithText(FilledButton, 'GUARDAR');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Seguimiento guardado en esta vista.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
