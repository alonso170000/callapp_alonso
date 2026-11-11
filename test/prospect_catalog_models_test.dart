import 'package:callerapp_frontend/presentation/models/prospect_catalog_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final lots = <Map<String, dynamic>>[
    {'id': 20, 'cluster_id': 2, 'numero_etapa': 2, 'numero_lote': 'B-2'},
    {'id': 10, 'cluster_id': 1, 'numero_etapa': 1, 'numero_lote': 'A-1'},
    {'id': 11, 'cluster_id': 1, 'numero_etapa': 1, 'numero_lote': 'A-2'},
  ];

  test('agrupa etapas y las ordena por número', () {
    final stages = LotCatalog.stageOptions(lots);

    expect(stages.map((stage) => stage.id), [1, 2]);
    expect(stages.first.label, 'Etapa 1');
    expect(stages.first.lots.map((lot) => lot['id']), [10, 11]);
  });

  test('filtra por etapa y cero conserva todos los lotes', () {
    expect(LotCatalog.filterByStage(lots, 2).map((lot) => lot['id']), [20]);
    expect(LotCatalog.filterByStage(lots, 0), lots);
  });

  test('compone etiquetas de etapa y lote', () {
    expect(LotCatalog.lotLabel(lots.first), 'Etapa 2 · Lote B-2');
    expect(LotCatalog.stageNumber(lots.first), 2);
  });

  test('mantiene compatibilidad con lotes sin etapa', () {
    final legacy = <String, dynamic>{'id': 30, 'numero_lote': 'C-1'};

    expect(LotCatalog.stageIdOf(legacy), isNull);
    expect(LotCatalog.stageOptions([legacy]), isEmpty);
    expect(LotCatalog.stageLabel(legacy), 'No disponible');
    expect(LotCatalog.lotLabel(legacy), 'Lote C-1');
  });

  test('acepta etapa_id y valores numéricos recibidos como texto', () {
    final lot = <String, dynamic>{
      'id': 40,
      'etapa_id': '4',
      'numero_etapa': '3',
      'numero_lote': 8,
    };

    expect(LotCatalog.stageIdOf(lot), 4);
    expect(LotCatalog.stageNumber(lot), 3);
    expect(LotCatalog.lotLabel(lot), 'Etapa 3 · Lote 8');
  });

  test('reconoce disponibilidad y conserva compatibilidad sin estatus', () {
    expect(LotCatalog.isAvailable({'estatus': 'disponible'}), isTrue);
    expect(LotCatalog.isAvailable({'estatus': 'vendido'}), isFalse);
    expect(LotCatalog.isAvailable({'estatus': 'apartado'}), isFalse);
    expect(
      LotCatalog.isAvailable({
        'estatus': 'disponible',
        'deleted_at': '2026-11-11',
      }),
      isFalse,
    );
    expect(LotCatalog.isAvailable({'id': 1}), isTrue);
  });

  test('filtra y encuentra únicamente lotes disponibles', () {
    final catalog = [
      {'id': 1, 'estatus': 'disponible'},
      {'id': 2, 'estatus': 'vendido'},
      {'id': 3, 'deleted_at': '2026-11-11'},
    ];

    expect(LotCatalog.availableLots(catalog).map((lot) => lot['id']), [1]);
    expect(LotCatalog.findById(catalog, 1)?['id'], 1);
    expect(LotCatalog.findById(catalog, 2), isNull);
    expect(LotCatalog.findById(catalog, 3), isNull);
    expect(LotCatalog.findById(catalog, null), isNull);
  });

  test('formatea precio, dimensiones y texto de la ficha', () {
    expect(LotCatalog.formatPrice('950000'), r'$ 950,000.00');
    expect(LotCatalog.formatPrice(null), 'No disponible');
    expect(LotCatalog.formatDimensions('120.00'), '120 m²');
    expect(LotCatalog.formatDimensions(null), 'No disponible');
    expect(LotCatalog.text('  Cancún  '), 'Cancún');
    expect(LotCatalog.text(''), 'No disponible');
    expect(LotCatalog.text(null), 'No disponible');
  });

  test('etapas y filtro excluyen lotes no disponibles', () {
    final catalog = [
      {'id': 1, 'cluster_id': 1, 'numero_etapa': 1, 'estatus': 'disponible'},
      {'id': 2, 'cluster_id': 2, 'numero_etapa': 2, 'estatus': 'apartado'},
    ];

    expect(LotCatalog.stageOptions(catalog).map((stage) => stage.id), [1]);
    expect(LotCatalog.filterByStage(catalog, 0).map((lot) => lot['id']), [1]);
    expect(LotCatalog.filterByStage(catalog, 2), isEmpty);
  });
}
