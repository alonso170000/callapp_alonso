String normalizeProspectType(Object? value) {
  final normalized = (value ?? '')
      .toString()
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[áàäâ]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöô]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u');
  return normalized.startsWith('reactiv') ? 'reactivacion' : 'regular';
}

bool isReactivationType(Object? value) =>
    normalizeProspectType(value) == 'reactivacion';

String prospectTypeLabel(Object? value) =>
    isReactivationType(value) ? 'Reactivación' : 'Regular';
