import 'package:callerapp_frontend/presentation/models/contact_medium.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProspectRecord prospect({String phone = '', String email = ''}) =>
      ProspectRecord(
        name: 'Ana',
        phone: phone,
        email: email,
        status: 'Nuevo',
        temperature: 'Tibio',
        avatarColor: Colors.teal,
        statusColor: Colors.blue,
      );

  test('parsea y normaliza los medios soportados', () {
    expect(ContactMedium.parse(' telefono '), ContactMedium.llamada);
    expect(ContactMedium.parse('LLAMADA'), ContactMedium.llamada);
    expect(ContactMedium.parse(' Whats App '), ContactMedium.whatsapp);
    expect(ContactMedium.parse('FACEBOOK'), ContactMedium.facebook);
    expect(ContactMedium.parse('Correo'), ContactMedium.correo);
    expect(ContactMedium.parse('sms'), isNull);
    expect(ContactMedium.parse(null), isNull);
  });

  test('serializa telefono según el contrato de contactos y actividades', () {
    expect(ContactMedium.llamada.backendValue, 'telefono');
    expect(ContactMedium.llamada.activityValue, 'llamada');
  });

  test('valida disponibilidad con los datos reales del prospecto', () {
    final complete = prospect(
      phone: '+52 (998) 123-4567',
      email: 'ana@example.com',
    );
    expect(ContactMedium.llamada.isAvailable(complete), isTrue);
    expect(ContactMedium.whatsapp.isAvailable(complete), isTrue);
    expect(ContactMedium.correo.isAvailable(complete), isTrue);
    expect(ContactMedium.facebook.isAvailable(complete), isFalse);

    final invalid = prospect(phone: '123', email: 'correo-invalido');
    expect(ContactMedium.llamada.isAvailable(invalid), isFalse);
    expect(ContactMedium.whatsapp.isAvailable(invalid), isFalse);
    expect(ContactMedium.correo.isAvailable(invalid), isFalse);
  });
}
