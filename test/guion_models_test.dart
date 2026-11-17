import 'package:flutter_test/flutter_test.dart';
import 'package:callerapp_frontend/presentation/models/guion_models.dart';

void main() {
  test('parsea guiones, paso inicial, viñetas y opciones', () {
    final bundle = GuionesBundle.fromJson({'version': 'v1', 'guiones': [{'id': '1', 'codigo': 'llamada_1', 'titulo': 'Llamada 1', 'orden': 1, 'pasos': [{'id': 10, 'codigo': 'inicio', 'titulo': 'Inicio', 'contenido': 'Hola', 'es_inicial': 1, 'vinetas': ['Uno'], 'opciones': [{'id': 2, 'etiqueta': 'Continuar', 'siguiente_paso_id': '11', 'orden': 1}]}]}]});
    expect(bundle.version, 'v1');
    expect(bundle.guiones.single.pasoInicial?.id, 10);
    expect(bundle.guiones.single.pasos.single.vinetas, ['Uno']);
    expect(bundle.guiones.single.pasos.single.opciones.single.siguientePasoId, 11);
  });

  test('usa el primer paso si ninguno está marcado inicial', () {
    final guion = Guion.fromJson({'id': 1, 'codigo': 'uno', 'titulo': 'Uno', 'pasos': [{'id': 4, 'codigo': 'p', 'titulo': 'Paso', 'contenido': 'Texto'}]});
    expect(guion.pasoInicial?.id, 4);
    expect(guion.pasoPorId(4)?.titulo, 'Paso');
  });

  test('rechaza campos críticos ausentes', () {
    expect(() => GuionPaso.fromJson({'id': 1, 'titulo': 'Paso'}), throwsFormatException);
    expect(() => GuionOpcion.fromJson({'id': 1, 'etiqueta': 'Sí'}), throwsFormatException);
  });
}
