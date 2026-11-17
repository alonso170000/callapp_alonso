import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:callerapp_frontend/presentation/models/guion_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/scripts_panel.dart';

const bundle = GuionesBundle(
  guiones: [
    Guion(
      id: 1,
      codigo: 'llamada_1',
      titulo: 'Llamada 1',
      subtitulo: 'Gaia',
      orden: 1,
      pasos: [
        GuionPaso(
          id: 10,
          codigo: 'inicio',
          titulo: 'Inicio',
          contenido: 'Hola {nombre}, soy {asesor}. Usa {cluster}.',
          notaAsesor: 'No leer esto.',
          esInicial: true,
          siguientePasoId: 11,
        ),
        GuionPaso(
          id: 11,
          codigo: 'fin',
          titulo: 'Fin',
          contenido: 'Terminamos',
        ),
      ],
    ),
  ],
);

Widget app({
  GuionesBundle? data = bundle,
  bool loading = false,
  String? error,
  bool offline = false,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: ProspectScriptsPanel(
        guiones: data,
        loading: loading,
        error: error,
        offline: offline,
        onRetry: () {},
        prospectName: 'Ana',
        asesorName: 'Luis',
        desarrolloName: 'Gaia Hábitat',
      ),
    ),
  ),
);

void main() {
  testWidgets('renderiza variables, notas, avanza, vuelve y finaliza', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.textContaining('Hola Ana, soy Luis'), findsOneWidget);
    expect(find.text('No leer esto.'), findsOneWidget);
    expect(
      find.text('Sustituye las variables entre llaves antes de leer.'),
      findsOneWidget,
    );
    await tester.tap(find.text('SEGUIR LEYENDO'));
    await tester.pumpAndSettle();
    expect(find.text('Fin del guion'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver al paso anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('muestra estados vacío, error y offline', (tester) async {
    await tester.pumpWidget(app(data: const GuionesBundle(guiones: [])));
    expect(
      find.text('Este desarrollo aún no tiene guiones publicados.'),
      findsOneWidget,
    );
    await tester.pumpWidget(app(data: null, error: 'Falló'));
    expect(find.text('Reintentar'), findsOneWidget);
    await tester.pumpWidget(app(offline: true));
    expect(find.text('Sin conexión · guion guardado'), findsOneWidget);
  });

  testWidgets('muestra estado vacío cuando el prospecto no tiene desarrollo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectScriptsPanel(
          guiones: const GuionesBundle(guiones: []),
          loading: false,
          error: null,
          offline: false,
          onRetry: () {},
          prospectName: 'Ana',
          asesorName: 'Luis',
          emptyMessage: 'Este prospecto no tiene un desarrollo asignado.',
        ),
      ),
    );

    expect(
      find.text('Este prospecto no tiene un desarrollo asignado.'),
      findsOneWidget,
    );
    expect(find.textContaining('Runa'), findsNothing);
  });
}
