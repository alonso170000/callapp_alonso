class ProspectCatalogs {
  const ProspectCatalogs({
    this.origins = const [],
    this.statuses = const [],
    this.lots = const [],
  });

  final List<Map<String, dynamic>> origins;
  final List<Map<String, dynamic>> statuses;
  final List<Map<String, dynamic>> lots;

  bool get canCreate => origins.isNotEmpty;
}

class LotStage {
  const LotStage({
    required this.id,
    required this.number,
    required this.label,
    required this.lots,
  });

  final int id;
  final int? number;
  final String label;
  final List<Map<String, dynamic>> lots;
}

class LotCatalog {
  const LotCatalog._();

  static bool isAvailable(Map<String, dynamic> lot) {
    final status = lot['estatus']?.toString().trim().toLowerCase();
    if (status != null && status.isNotEmpty && status != 'disponible') {
      return false;
    }
    return lot['deleted_at'] == null;
  }

  static List<Map<String, dynamic>> availableLots(
    List<Map<String, dynamic>> lots,
  ) => List.unmodifiable(lots.where(isAvailable));

  static Map<String, dynamic>? findById(
    List<Map<String, dynamic>> lots,
    int? id,
  ) {
    if (id == null) return null;
    for (final lot in lots) {
      if (lot['id'] == id && isAvailable(lot)) return lot;
    }
    return null;
  }

  static String formatPrice(Object? value) {
    final amount = double.tryParse(value?.toString() ?? '');
    if (amount == null) return 'No disponible';
    final parts = amount.toStringAsFixed(2).split('.');
    final digits = parts.first;
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return '\$ $buffer.${parts.last}';
  }

  static String formatDimensions(Object? value) {
    final dimensions = double.tryParse(value?.toString() ?? '');
    if (dimensions == null) return 'No disponible';
    final formatted = dimensions == dimensions.roundToDouble()
        ? dimensions.toStringAsFixed(0)
        : dimensions.toStringAsFixed(2);
    return '$formatted m²';
  }

  static String text(Object? value) {
    final result = value?.toString().trim();
    return result == null || result.isEmpty ? 'No disponible' : result;
  }

  static int? _intValue(Object? value) => value is int
      ? value
      : value == null
      ? null
      : int.tryParse(value.toString());

  static int? stageIdOf(Map<String, dynamic> lot) =>
      _intValue(lot['cluster_id'] ?? lot['etapa_id']);

  static int? stageNumber(Map<String, dynamic> lot) =>
      _intValue(lot['numero_etapa']);

  static String stageLabel(Map<String, dynamic> lot) {
    final number = stageNumber(lot);
    if (number != null) return 'Etapa $number';
    final received = (lot['cluster_nombre'] ?? lot['etapa_nombre'])
        ?.toString()
        .trim();
    return received == null || received.isEmpty ? 'No disponible' : received;
  }

  static String lotLabel(Map<String, dynamic> lot) {
    final number = lot['numero_lote']?.toString().trim();
    final lotText = 'Lote ${number == null || number.isEmpty ? '' : number}'
        .trim();
    return stageIdOf(lot) == null ? lotText : '${stageLabel(lot)} · $lotText';
  }

  static List<LotStage> stageOptions(List<Map<String, dynamic>> lots) {
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final lot in availableLots(lots)) {
      final id = stageIdOf(lot);
      if (id != null) (grouped[id] ??= []).add(lot);
    }
    final stages = grouped.entries.map((entry) {
      final sample = entry.value.first;
      return LotStage(
        id: entry.key,
        number: stageNumber(sample),
        label: stageLabel(sample),
        lots: List.unmodifiable(entry.value),
      );
    }).toList();
    stages.sort((a, b) {
      final byNumber = (a.number ?? 1 << 30).compareTo(b.number ?? 1 << 30);
      return byNumber != 0 ? byNumber : a.id.compareTo(b.id);
    });
    return List.unmodifiable(stages);
  }

  static List<Map<String, dynamic>> filterByStage(
    List<Map<String, dynamic>> lots,
    int stageId,
  ) {
    final available = availableLots(lots);
    return stageId <= 0
        ? available
        : List.unmodifiable(
            available.where((lot) => stageIdOf(lot) == stageId),
          );
  }
}
