import 'package:callerapp_frontend/presentation/models/prospect_catalog_models.dart';
import 'package:flutter/material.dart';

class SelectedLotCard extends StatelessWidget {
  const SelectedLotCard({
    super.key,
    required this.lot,
    required this.backgroundColor,
    required this.foregroundColor,
    this.developmentFallback,
  });

  final Map<String, dynamic> lot;
  final Color backgroundColor;
  final Color foregroundColor;
  final String? developmentFallback;

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: TextStyle(color: foregroundColor)),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final development = lot['desarrollo_nombre'] ?? developmentFallback;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _row('Desarrollo', LotCatalog.text(development)),
          _row('Etapa', LotCatalog.stageLabel(lot)),
          _row('Número de lote', LotCatalog.text(lot['numero_lote'])),
          _row(
            'Dimensiones',
            LotCatalog.formatDimensions(lot['dimensiones_m2']),
          ),
          _row('Tipo de lote', LotCatalog.text(lot['tipo'])),
          _row(
            'Precio actual',
            LotCatalog.formatPrice(lot['precio'] ?? lot['precio_venta']),
          ),
          _row('Estado', LotCatalog.text(lot['estado'])),
          _row('Municipio', LotCatalog.text(lot['municipio'])),
          _row('Ubicación', LotCatalog.text(lot['ubicacion'])),
        ],
      ),
    );
  }
}
