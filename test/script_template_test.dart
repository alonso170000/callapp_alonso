import 'package:flutter_test/flutter_test.dart';
import 'package:callerapp_frontend/services/script_template.dart';

void main() {
  test('sustituye variables conocidas y el alias sin cambiar mayúsculas', () {
    expect(
      renderScriptText(
        'Hola {nombre}/{prospectName}, soy {asesor} de {desarrollo}.',
        nombre: 'Ana Pérez',
        asesor: 'Luis',
        desarrollo: 'Gaia Hábitat',
      ),
      'Hola Ana Pérez/Ana Pérez, soy Luis de Gaia Hábitat.',
    );
  });

  test('conserva y detecta variables desconocidas', () {
    final result = renderScriptText(
      'Cluster {cluster}',
      nombre: 'Ana',
      asesor: 'Luis',
    );
    expect(result, 'Cluster {cluster}');
    expect(hasUnresolvedVariables(result), isTrue);
    expect(hasUnresolvedVariables('Sin variables'), isFalse);
  });
}
