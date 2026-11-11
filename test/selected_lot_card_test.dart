import 'package:callerapp_frontend/presentation/widgets/prospects/selected_lot_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra las nueve filas con los datos completos', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SelectedLotCard(
            lot: {
              'desarrollo_nombre': 'Residencial Hada',
              'numero_etapa': 2,
              'numero_lote': 'A-12',
              'dimensiones_m2': 120,
              'tipo': 'Residencial',
              'precio': 950000,
              'estado': 'Quintana Roo',
              'municipio': 'Benito Juárez',
              'ubicacion': 'Cancún',
            },
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );

    for (final label in [
      'Desarrollo',
      'Etapa',
      'Número de lote',
      'Dimensiones',
      'Tipo de lote',
      'Precio actual',
      'Estado',
      'Municipio',
      'Ubicación',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    for (final value in [
      'Residencial Hada',
      'Etapa 2',
      'A-12',
      '120 m²',
      'Residencial',
      r'$ 950,000.00',
      'Quintana Roo',
      'Benito Juárez',
      'Cancún',
    ]) {
      expect(find.text(value), findsOneWidget);
    }
  });

  testWidgets('usa fallback y No disponible cuando faltan campos', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SelectedLotCard(
            lot: {},
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            developmentFallback: 'Runa',
          ),
        ),
      ),
    );

    expect(find.text('Runa'), findsOneWidget);
    expect(find.text('Etapa'), findsOneWidget);
    expect(find.text('No disponible'), findsNWidgets(8));
  });
}
