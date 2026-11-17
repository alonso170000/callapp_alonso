import 'package:callerapp_frontend/presentation/models/prospect_status.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/colors/prospect_tag_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normaliza Validado al nombre visible del flujo', () {
    expect(ProspectStatus.canonical('Validado'), 'Contactado y validado');
    expect(
      ProspectTagColors.status('Validado'),
      AppColors.prospectStatusContacted,
    );
    expect(ProspectStatus.databaseValue('Contactado y validado'), 'Validado');
  });

  test('solo permite conservar o avanzar el estatus actual', () {
    expect(ProspectStatus.availableFrom('Validado'), [
      'Contactado y validado',
      'Seguimiento',
      'Cotización',
      'Negociación',
      'Venta realizada',
    ]);
    expect(
      ProspectStatus.availableFrom('Seguimiento'),
      isNot(contains('Nuevo')),
    );
    expect(
      ProspectStatus.availableFrom('Seguimiento'),
      isNot(contains('Contactado y validado')),
    );
    expect(ProspectStatus.availableFrom('Venta realizada'), [
      'Venta realizada',
    ]);
  });
}
