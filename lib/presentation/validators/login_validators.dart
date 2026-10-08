class LoginValidators {
  LoginValidators._();

  static String? field(String? value, {required bool password}) {
    if (password) {
      if ((value ?? '').isEmpty) return 'La contraseña es obligatoria.';
    } else if ((value ?? '').trim().isEmpty) {
      return 'El usuario es obligatorio.';
    }
    return null;
  }
}
