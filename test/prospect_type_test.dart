import 'package:callerapp_frontend/presentation/models/prospect_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normaliza variantes de reactivación', () {
    for (final value in const [
      'reactivacion',
      'Reactivación',
      ' reactivados ',
    ]) {
      expect(normalizeProspectType(value), 'reactivacion');
      expect(isReactivationType(value), isTrue);
      expect(prospectTypeLabel(value), 'Reactivación');
    }
  });

  test('valores vacíos o desconocidos se consideran regulares', () {
    for (final value in [null, '', 'nuevo']) {
      expect(normalizeProspectType(value), 'regular');
      expect(isReactivationType(value), isFalse);
      expect(prospectTypeLabel(value), 'Regular');
    }
  });
}
