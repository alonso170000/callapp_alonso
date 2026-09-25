class LoginValidators {
  LoginValidators._();

  static String? field(String? value, {required bool password}) {
    final text = value ?? '';
    if (password) {
      if (text.isEmpty) return 'La contraseña es obligatoria.';
      if (text.length < 6) return 'Debe tener al menos 6 caracteres.';
    } else {
      if (text.trim().isEmpty) return 'El correo es obligatorio.';
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text.trim())) {
        return 'Ingresa un correo válido.';
      }
    }
    return null;
  }
}
