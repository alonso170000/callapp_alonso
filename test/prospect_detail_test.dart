import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_call_scripts.dart';
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
      expect(find.text('Acerca del seguimiento'), findsOneWidget);
      expect(find.text('Información de la llamada'), findsOneWidget);
      expect(find.text('Necesidad y objetivo'), findsNothing);
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
      expect(find.text('Llamada 1'), findsOneWidget);
      expect(find.text('Saludo Inicial'), findsOneWidget);
      expect(
        find.textContaining('Hola buen día Alan Dorantes'),
        findsOneWidget,
      );
      expect(find.text('Llamada 2'), findsOneWidget);
      expect(find.text('Llamada de Seguimiento (Día 2)'), findsOneWidget);
      expect(find.text('CONTINUAR AL CIERRE'), findsOneWidget);
      final next = find.widgetWithText(FilledButton, 'SIGUIENTE');
      final previous = find.byTooltip('Volver al paso anterior');
      expect(find.text('ANTERIOR'), findsNothing);
      expect(previous, findsNothing);
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('Pregunta'), findsOneWidget);
      expect(
        find.textContaining('Sr(a) ${demoProspects[1].name.toUpperCase()}'),
        findsOneWidget,
      );
      expect(find.textContaining('¿Qué le llamó la atención'), findsOneWidget);
      final yes = find.widgetWithText(OutlinedButton, 'SI HA VIAJADO');
      final no = find.widgetWithText(OutlinedButton, 'NO HA VIAJADO');
      expect(next, findsNothing);
      await tester.ensureVisible(yes);
      await tester.tap(yes);
      await tester.pumpAndSettle();
      expect(find.text('Sí ha viajado'), findsOneWidget);
      expect(
        find.textContaining('Perfecto ¿y qué es lo que más'),
        findsOneWidget,
      );
      final continueReading = find.widgetWithText(
        FilledButton,
        'SEGUIR LEYENDO',
      );
      expect(continueReading, findsOneWidget);
      await tester.ensureVisible(continueReading);
      await tester.tap(continueReading);
      await tester.pumpAndSettle();
      expect(find.text('¿Cuándo fue la última vez que vino?'), findsOneWidget);
      expect(find.textContaining('Le platico RUNA YUCATÁN'), findsOneWidget);
      expect(find.textContaining('SABRÁS CUÁNDO VINO'), findsOneWidget);
      await tester.ensureVisible(continueReading);
      await tester.tap(continueReading);
      await tester.pumpAndSettle();
      expect(find.text('¿Su terreno le interesa cómo?'), findsOneWidget);
      expect(find.text('Plan de negocio'), findsOneWidget);
      final investment = find.widgetWithText(OutlinedButton, 'INVERSIÓN');
      await tester.ensureVisible(investment);
      await tester.tap(investment);
      await tester.pumpAndSettle();
      expect(find.text('Inversión'), findsOneWidget);
      expect(
        find.textContaining(
          'Esa es una muy buena opción sr(a) ${demoProspects[1].name.toUpperCase()}',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('600 m² y hasta más de 1000 m²'),
        findsOneWidget,
      );
      await tester.ensureVisible(continueReading);
      await tester.tap(continueReading);
      await tester.pumpAndSettle();
      expect(find.text('Ubicación y plusvalía'), findsOneWidget);
      expect(
        find.textContaining('Runa Residencial tiene excelente ubicación'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Carretera Federal 172 Motul – Telchac Puerto'),
        findsOneWidget,
      );
      await tester.ensureVisible(continueReading);
      await tester.tap(continueReading);
      await tester.pumpAndSettle();
      expect(find.text('Telchac'), findsOneWidget);
      expect(
        find.textContaining('Pertenece al municipio de Telchac'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'las zonas con mayor crecimiento y plusvalía en México.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(continueReading);
      await tester.tap(continueReading);
      await tester.pumpAndSettle();
      expect(
        find.text('El siguiente texto del guion aún no está disponible.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(find.text('Ubicación y plusvalía'), findsOneWidget);
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(find.text('Inversión'), findsOneWidget);
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(find.text('¿Su terreno le interesa cómo?'), findsOneWidget);
      final housing = find.widgetWithText(OutlinedButton, 'VIVIENDA');
      await tester.ensureVisible(housing);
      await tester.tap(housing);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(ProspectCallScripts),
          matching: find.text('Vivienda'),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('sr(a) ${demoProspects[1].name.toUpperCase()}'),
        findsOneWidget,
      );
      expect(
        find.textContaining('cada Clúster es privado y con acceso controlado'),
        findsOneWidget,
      );
      expect(continueReading, findsOneWidget);
      await tester.ensureVisible(continueReading);
      await tester.tap(continueReading);
      await tester.pumpAndSettle();
      expect(find.text('Ubicación y playa'), findsOneWidget);
      expect(
        find.textContaining(
          'una playa cálida con aguas cristalinas y arena fina,',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Runa Residencial tiene excelente ubicación'),
        findsOneWidget,
      );
      await tester.ensureVisible(continueReading);
      await tester.tap(continueReading);
      await tester.pumpAndSettle();
      expect(
        find.text('El siguiente texto del guion aún no está disponible.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(ProspectCallScripts),
          matching: find.text('Vivienda'),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(find.text('¿Su terreno le interesa cómo?'), findsOneWidget);
      final rental = find.widgetWithText(OutlinedButton, 'RENTA');
      await tester.ensureVisible(rental);
      await tester.tap(rental);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(ProspectCallScripts),
          matching: find.text('Renta'),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('sr(a) ${demoProspects[1].name.toUpperCase()}'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Carretera Federal 172 Motul – Telchac Puerto'),
        findsOneWidget,
      );
      expect(
        find.textContaining('crecimiento y plusvalía en México.'),
        findsOneWidget,
      );
      await tester.ensureVisible(continueReading);
      await tester.tap(continueReading);
      await tester.pumpAndSettle();
      expect(find.text('Inversión y atractivos de la zona'), findsOneWidget);
      expect(
        find.textContaining('el 98 % de los inversionistas'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Sr(a) ${demoProspects[1].name.toUpperCase()} con nosotros',
        ),
        findsOneWidget,
      );
      for (final benefit in [
        'CENOTES',
        'TIROLESAS',
        'SELVA',
        'PLAYA',
        'SNORKELING',
        'ZONAS ARQUEOLÓGICAS',
        'RESERVAS ECOLÓGICAS',
      ]) {
        expect(find.text(benefit), findsOneWidget);
      }
      await tester.ensureVisible(continueReading);
      await tester.tap(continueReading);
      await tester.pumpAndSettle();
      expect(
        find.text('El siguiente texto del guion aún no está disponible.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(ProspectCallScripts),
          matching: find.text('Renta'),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(find.text('¿Su terreno le interesa cómo?'), findsOneWidget);
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(find.text('¿Cuándo fue la última vez que vino?'), findsOneWidget);
      expect(yes, findsNothing);
      expect(no, findsNothing);
      expect(next, findsNothing);
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(find.text('Sí ha viajado'), findsOneWidget);
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(find.text('Pregunta'), findsOneWidget);
      await tester.ensureVisible(no);
      await tester.tap(no);
      await tester.pumpAndSettle();
      expect(find.text('No ha viajado'), findsOneWidget);
      expect(
        find.textContaining('Bueno sería una buena oportunidad'),
        findsOneWidget,
      );
      expect(
        find.text('(Si te dice no, nunca ha viajado a esta parte de México).'),
        findsOneWidget,
      );
      expect(continueReading, findsOneWidget);
      expect(find.text('Sí ha viajado'), findsNothing);
      await tester.ensureVisible(continueReading);
      await tester.tap(continueReading);
      await tester.pumpAndSettle();
      expect(find.text('¿Cuándo fue la última vez que vino?'), findsOneWidget);
      expect(find.textContaining('Le platico RUNA YUCATÁN'), findsOneWidget);
      expect(
        find.textContaining('¿Sr. ${demoProspects[1].name.toUpperCase()}'),
        findsOneWidget,
      );
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(find.text('No ha viajado'), findsOneWidget);
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(find.text('Pregunta'), findsOneWidget);
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(find.text('Saludo Inicial'), findsOneWidget);
      expect(previous, findsNothing);
      expect(next, findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Prospecto'));
      await tester.tap(find.widgetWithText(FilterChip, 'Prospecto'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Datos del prospecto'));
      expect(find.text('Ciudad'), findsOneWidget);
      expect(find.text('Empresa'), findsOneWidget);
      expect(find.text('Ocupación'), findsOneWidget);
      expect(find.text('Origen del prospecto'), findsOneWidget);
      expect(find.text('Campaña FB'), findsOneWidget);
      final historyPanelTitle = find.text('Historial').last;
      await tester.ensureVisible(historyPanelTitle);
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
