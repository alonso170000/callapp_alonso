import 'package:flutter/material.dart';

import 'colors.dart';

class ProspectTagColors {
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
    'cotizacion' => const Color(0xFFB69BF5),
    'nuevo' => AppColors.homeBlueSection,
    'negociacion' => AppColors.homeOrangeSection,
    'venta realizada' => AppColors.homeGreenCard,
    _ => AppColors.homeWarmText,
  };

  static Color background(String value) =>
      isPriority(value) ? priority(value) : status(value);
  static Color foreground(String value) =>
      isPriority(value) ? Colors.white : Colors.black;
}
