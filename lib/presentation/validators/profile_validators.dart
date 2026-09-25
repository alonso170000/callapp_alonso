class ProfileValidators {
  ProfileValidators._();

  static String? field(String? value, {required String field}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Este campo es obligatorio';
    if (field == 'Correo' &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return 'Ingresa un correo válido';
    }
    if (field == 'Teléfono' &&
        (!RegExp(r'^\+?[\d\s()-]+$').hasMatch(text) ||
            text.replaceAll(RegExp(r'\D'), '').length < 10 ||
            text.replaceAll(RegExp(r'\D'), '').length > 15)) {
      return 'Ingresa un teléfono válido';
    }
    return null;
  }
}
