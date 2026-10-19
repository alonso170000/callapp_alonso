import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_discovery_form.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingProspectsService extends ProspectsService {
  Map<String, dynamic>? fields;

  @override
  Future<Map<String, dynamic>?> discovery(int prospectId) async => null;

  @override
  Future<void> saveDiscoverySection(
    int prospectId,
    Map<String, dynamic> fields,
  ) async {
    expect(prospectId, 17);
    this.fields = fields;
  }
}

void main() {
  Widget buildSubject() => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ProspectDiscoveryForm(onSaved: (_) {}),
      ),
    ),
  );

  testWidgets('muestra los campos condicionales únicamente cuando aplican', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('¿Qué conoce de la zona?'), findsNothing);
    expect(find.text('Otro factor *'), findsNothing);

    final knowsAreaToggle = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == '¿Usted conoce la zona?',
    );
    await tester.tap(knowsAreaToggle);
    await tester.pump();
    expect(find.text('¿Qué conoce de la zona?'), findsOneWidget);

    final otherChip = find.widgetWithText(FilterChip, 'Otro');
    await tester.ensureVisible(otherChip);
    await tester.tap(otherChip);
    await tester.pump();
    expect(find.text('Otro factor *'), findsOneWidget);

    await tester.tap(otherChip);
    await tester.pump();
    expect(find.text('Otro factor *'), findsNothing);
  });

  testWidgets('ubicaciones y motivadores permiten selección múltiple', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    final quintanaRoo = find.widgetWithText(FilterChip, 'Quintana Roo');
    final yucatan = find.widgetWithText(FilterChip, 'Yucatán');
    await tester.tap(quintanaRoo);
    await tester.tap(yucatan);
    await tester.pump();

    expect(tester.widget<FilterChip>(quintanaRoo).selected, isTrue);
    expect(tester.widget<FilterChip>(yucatan).selected, isTrue);

    final plusvalia = find.widgetWithText(FilterChip, 'Plusvalía');
    final precio = find.widgetWithText(FilterChip, 'Precio');
    await tester.ensureVisible(plusvalia);
    await tester.tap(plusvalia);
    await tester.tap(precio);
    await tester.pump();

    expect(tester.widget<FilterChip>(plusvalia).selected, isTrue);
    expect(tester.widget<FilterChip>(precio).selected, isTrue);
  });

  testWidgets('impide guardar las secciones sin datos obligatorios', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.widgetWithText(FilledButton, 'GUARDAR').first);
    await tester.pump();

    expect(find.text('Seleccione un tipo de propiedad.'), findsOneWidget);
    expect(find.text('Seleccione al menos una ubicación.'), findsOneWidget);
    expect(find.text('Seleccione el objetivo de compra.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('guarda motivadores múltiples mediante el servicio', (
    tester,
  ) async {
    final service = _RecordingProspectsService();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProspectDiscoveryForm(
              prospectId: 17,
              prospectsService: service,
              onSaved: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final price = find.widgetWithText(FilterChip, 'Precio');
    final security = find.widgetWithText(FilterChip, 'Seguridad');
    await tester.ensureVisible(price);
    await tester.tap(price);
    await tester.tap(security);
    final save = find.widgetWithText(FilledButton, 'GUARDAR').at(2);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(service.fields, {
      'seccion': 'motivadores_compra',
      'motivo_compra': ['precio', 'seguridad'],
      'otro_motivo_compra': null,
    });
  });
}
