import 'package:flutter/material.dart';

import 'colors.dart';

class ProspectTagColors {
  static Color get client => AppColors.prospectTagClient;
  static Color get clientForeground => AppColors.prospectTagClientInk;
  static String _key(String value) =>
      value.trim().toLowerCase().replaceAll('ó', 'o').replaceAll('í', 'i');

  static bool isPriority(String value) =>
      {'caliente', 'tibio', 'frio', 'sin calificar'}.contains(_key(value));

  static Color priority(String value) => switch (_key(value)) {
    'caliente' => const Color(0xFFFF535C),
    'tibio' => const Color(0xFFE5B120),
    _ => const Color(0xFF25C3E0),
  };

  static Color status(String value) => switch (_key(value)) {
    'nuevo' => AppColors.prospectStatusNew,
    'negociacion' => AppColors.prospectStatusNegotiation,
    'cotizacion' => AppColors.prospectStatusQuote,
    'seguimiento' => AppColors.prospectStatusFollowUp,
    'contactado y validado' => AppColors.prospectStatusContacted,
    'venta realizada' => AppColors.prospectStatusSale,
    'atrasados' => AppColors.prospectStatusOverdue,
    _ => AppColors.homeWarmText,
  };

  static Color background(String value) =>
      isPriority(value) ? priority(value) : status(value);
  static Color foreground(String value) =>
      isPriority(value) ? Colors.white : Colors.black;
}
