class ProspectValidators {
  static String? requiredText(String? value) =>
      value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio'
      : null;

  static String? email(String? value) =>
      requiredText(value) ??
      (RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())
          ? null
          : 'Ingresa un email válido');

  static String? phone(String? value) {
    if (requiredText(value) != null) return requiredText(value);
    final digits = value!.replaceAll(RegExp(r'\D'), '');
    return RegExp(r'^\+?[\d\s()-]+$').hasMatch(value.trim()) &&
            digits.length >= 10 &&
            digits.length <= 15
        ? null
        : 'Ingresa un teléfono válido';
  }

  static String? number(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    return number != null &&
            number.isFinite &&
            number >= 0 &&
            !value!.contains(',')
        ? null
        : 'Usa un número positivo o cero, sin comas';
  }
}
