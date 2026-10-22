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
  List<Map<String, dynamic>> developments = [
    {'id': 3, 'nombre': 'Residencial Hada', 'ubicacion': 'Cancún'},
  ];
  final lotsRequests = <int>[];
  List<Map<String, dynamic>> closers = [
    {'id': 4, 'nombre_completo': 'Cerradora Uno', 'rol': 'cerrador'},
    {'id': 8, 'nombre_completo': 'Cerrador Dos', 'rol': 'cerrador'},
  ];

  @override
  Future<Map<String, dynamic>?> discovery(int prospectId) async => null;

  @override
  Future<List<Map<String, dynamic>>> availableDevelopments() async =>
      developments;

  @override
  Future<List<Map<String, dynamic>>> availableLots([int? developmentId]) async {
    expect(developmentId, isNotNull);
    lotsRequests.add(developmentId!);
    return lots;
  }

  @override
  Future<List<Map<String, dynamic>>> availableClosers() async => closers;

  @override
  Future<void> saveDiscoverySection(
    int prospectId,
    Map<String, dynamic> fields, {
    String? operationKey,
  }) async {
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

    final developmentDropdown = tester
        .widgetList<DropdownButtonFormField<int>>(
          find.byType(DropdownButtonFormField<int>),
        )
        .firstWhere((widget) => widget.initialValue == 3);
    expect(developmentDropdown.onChanged, isNull);
    expect(service.lotsRequests, contains(3));

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

    final lotDropdown = find.byType(DropdownButtonFormField<int>).last;
    await tester.ensureVisible(lotDropdown);
    await tester.tap(lotDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lote 12').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Desarrollo'), findsWidgets);
    expect(find.text('Residencial Hada'), findsWidgets);
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

  testWidgets('asignación muestra cerradores reales y guarda su id', (
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

    expect(find.text('Nombre del cerrador'), findsNothing);
    final toggle = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == '¿Enviar a cerrador?',
    );
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('Nombre del cerrador'), findsOneWidget);
    expect(find.text('Seleccionar cerrador'), findsOneWidget);

    final save = find.widgetWithText(FilledButton, 'GUARDAR').last;
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Seleccione un cerrador.'), findsOneWidget);
    expect(service.fields, isNull);

    final dropdown = find.byType(DropdownButtonFormField<int>).last;
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrador Dos').last);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(service.fields, {
      'seccion': 'asignacion_cerrador',
      'cerrador_id': 8,
    });
  });
}
