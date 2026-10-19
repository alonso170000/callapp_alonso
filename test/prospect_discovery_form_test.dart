import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_discovery_form.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingProspectsService extends ProspectsService {
  Map<String, dynamic>? fields;
  List<Map<String, dynamic>> lots = [
    {
      'id': 12,
      'numero_lote': 12,
      'dimensiones_m2': 120,
      'precio': 950000,
      'estatus': 'disponible',
      'desarrollo_nombre': 'Residencial Hada',
    },
  ];

  @override
  Future<Map<String, dynamic>?> discovery(int prospectId) async => null;

  @override
  Future<List<Map<String, dynamic>>> availableLots() async => lots;

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

    final otherChip = find.widgetWithText(FilterChip, 'Otro').first;
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

  testWidgets('experiencia previa oculta los detalles cuando no ha comprado', (
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

    expect(find.text('¿Dónde?'), findsNothing);
    expect(find.text('¿Qué experiencia tuvo? *'), findsNothing);
    expect(find.text('¿Por qué?'), findsNothing);

    final boughtBefore = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == '¿Ha comprado inmuebles antes?',
    );
    await tester.ensureVisible(boughtBefore);
    await tester.tap(boughtBefore);
    await tester.pump();
    expect(find.text('¿Dónde?'), findsOneWidget);
    expect(find.text('¿Qué experiencia tuvo? *'), findsOneWidget);
    expect(find.text('¿Por qué?'), findsNothing);

    final save = find.widgetWithText(FilledButton, 'GUARDAR').at(3);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Seleccione la experiencia que tuvo.'), findsOneWidget);
    expect(service.fields, isNull);
  });

  testWidgets('proceso pide lote solo si hay interés y muestra sus datos', (
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

    expect(find.text('Seleccionar lote *'), findsNothing);
    expect(find.text('M² (Tamaño)'), findsNothing);
    expect(find.text('Precio web'), findsNothing);

    final specificLot = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == '¿Tiene interés en un lote específico?',
    );
    await tester.ensureVisible(specificLot);
    await tester.tap(specificLot);
    await tester.pumpAndSettle();

    expect(find.text('Seleccionar lote *'), findsOneWidget);
    expect(find.text('Seleccione un lote'), findsOneWidget);

    final lotDropdown = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(lotDropdown);
    await tester.tap(lotDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lote 12').last);
    await tester.pumpAndSettle();

    expect(find.text('Desarrollo'), findsOneWidget);
    expect(find.text('Residencial Hada'), findsOneWidget);
    expect(find.text('Dimensiones'), findsOneWidget);
    expect(find.text('120 m²'), findsOneWidget);
    expect(find.text(r'$ 950,000.00'), findsOneWidget);
  });

  testWidgets('proceso guarda participantes múltiples y el lote elegido', (
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

    final couple = find.widgetWithText(FilterChip, 'Pareja');
    final advisor = find.widgetWithText(FilterChip, 'Asesor');
    await tester.ensureVisible(couple);
    await tester.tap(couple);
    await tester.tap(advisor);
    await tester.pump();

    expect(tester.widget<FilterChip>(couple).selected, isTrue);
    expect(tester.widget<FilterChip>(advisor).selected, isTrue);

    final other = find.widgetWithText(FilterChip, 'Otro').last;
    await tester.tap(other);
    await tester.pump();
    expect(find.text('Especificar *'), findsOneWidget);

    final save = find.widgetWithText(FilledButton, 'GUARDAR').at(4);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Especifique quién más interviene.'), findsOneWidget);
    expect(service.fields, isNull);
  });
}
