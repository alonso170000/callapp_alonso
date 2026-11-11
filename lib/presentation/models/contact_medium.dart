import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/validators/prospect_validators.dart';
import 'package:callerapp_frontend/services/phone_number.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

enum ContactMedium {
  llamada,
  whatsapp,
  facebook,
  correo;

  static ContactMedium? parse(String? value) =>
      switch (value?.trim().toLowerCase().replaceAll(' ', '')) {
        'telefono' || 'llamada' => llamada,
        'whatsapp' => whatsapp,
        'facebook' => facebook,
        'correo' => correo,
        _ => null,
      };

  String get label => switch (this) {
    llamada => 'Llamar',
    whatsapp => 'WhatsApp',
    facebook => 'Facebook',
    correo => 'Correo',
  };

  String get actionLabel => switch (this) {
    llamada => 'Llamar',
    whatsapp => 'Enviar WhatsApp',
    facebook => 'Abrir Facebook',
    correo => 'Enviar correo',
  };

  String get backendValue => switch (this) {
    llamada => 'telefono',
    whatsapp => 'whatsapp',
    facebook => 'facebook',
    correo => 'correo',
  };

  IconData get icon => switch (this) {
    llamada => Iconsax.call_calling_copy,
    whatsapp || facebook => Iconsax.message_copy,
    correo => Iconsax.send_2_copy,
  };

  bool isAvailable(ProspectRecord prospect) => switch (this) {
    llamada || whatsapp => PhoneNumber.isDialable(prospect.phone),
    correo => ProspectValidators.email(prospect.email) == null,
    facebook => false,
  };
}
