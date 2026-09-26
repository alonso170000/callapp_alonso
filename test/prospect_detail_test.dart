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
      expect(find.text('Información de la llamada'), findsOneWidget);
      expect(find.text('10min 12s'), findsOneWidget);
      expect(find.text('Contestada'), findsOneWidget);
      final save = find.widgetWithText(FilledButton, 'GUARDAR');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Seguimiento guardado en esta vista.'), findsOneWidget);
      await tester.ensureVisible(find.text('Registrar discovery'));
      await tester.tap(find.text('Registrar discovery'));
      await tester.pumpAndSettle();
      expect(find.text('Necesidad y objetivo'), findsOneWidget);
      expect(find.text('Capacidad y forma de pago'), findsOneWidget);
      expect(find.text('Motivadores de compra'), findsOneWidget);
      expect(find.text('Experiencia previa'), findsOneWidget);
      expect(find.text('Proceso y seguimiento'), findsOneWidget);
      expect(find.text('Resultado del Discovery'), findsOneWidget);
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Guiones'));
      await tester.tap(find.widgetWithText(FilterChip, 'Guiones'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Guiones de llamadas'));
      await tester.tap(find.text('Guiones de llamadas'));
      await tester.pumpAndSettle();
      expect(find.text('Llamada 1'), findsOneWidget);
      expect(find.text('Saludo Inicial'), findsOneWidget);
      expect(
        find.textContaining('Hola buen día Alan Dorantes'),
        findsOneWidget,
      );
      expect(find.text('Llamada 2'), findsOneWidget);
      expect(find.text('Llamada de Seguimiento (Día 2)'), findsOneWidget);
      expect(find.text('CONTINUAR AL CIERRE'), findsOneWidget);
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Prospecto'));
      await tester.tap(find.widgetWithText(FilterChip, 'Prospecto'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Datos del prospecto'));
      await tester.tap(find.text('Datos del prospecto'));
      await tester.pumpAndSettle();
      expect(find.text('Ciudad'), findsOneWidget);
      expect(find.text('Empresa'), findsOneWidget);
      expect(find.text('Ocupación'), findsOneWidget);
      final historyPanelTitle = find.text('Historial').last;
      await tester.ensureVisible(historyPanelTitle);
      await tester.tap(historyPanelTitle);
      await tester.pumpAndSettle();
      expect(find.text('Historial de comentarios'), findsOneWidget);
      expect(find.text('Resumen de discovery'), findsOneWidget);
      expect(
        find.text('Me comentó que no está interesado en el lote'),
        findsOneWidget,
      );
      expect(find.text('Discovery Completo'), findsOneWidget);
      expect(find.text('Historial de correos'), findsOneWidget);
      expect(find.text('RUNASecondEmail'), findsOneWidget);
      expect(find.text('Correo de Bienvenida enviado'), findsOneWidget);
      expect(find.text('Historial de llamadas por horario'), findsOneWidget);
      expect(find.text('Semana 12 - 18'), findsOneWidget);
      expect(find.text('Atendida'), findsOneWidget);
      expect(find.text('Rechazada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
