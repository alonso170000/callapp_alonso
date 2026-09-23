class AuthValidators {
  AuthValidators._();

  static final RegExp _nombreCorrecto = RegExp(
    r'^[A-ZÁÉÍÓÚÑÜ][a-záéíóúñü]+$',
  );

  static final RegExp _parteLocalEmail = RegExp(
    r'^[a-zA-Z0-9](?:[a-zA-Z0-9._%+-]{0,62}[a-zA-Z0-9])?$',
  );

  static final RegExp _etiquetaDominio = RegExp(
    r'^[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$',
  );

  static const Set<String> _extensionesGenericas = {
    'app',
    'biz',
    'co',
    'com',
    'dev',
    'edu',
    'gov',
    'info',
    'io',
    'me',
    'mil',
    'net',
    'org',
    'tech',
    'tv',
  };

  static String? nombre(String value, String campo) {
    final texto = value.trim();
    final etiqueta = campo == 'nombre' ? 'El nombre' : 'El apellido';

    if (texto.isEmpty) return '$etiqueta es obligatorio.';
    if (texto.length < 2) return '$etiqueta debe tener al menos 2 letras.';
    if (!_nombreCorrecto.hasMatch(texto)) {
      return '$etiqueta debe iniciar con mayúscula y continuar con minúsculas, sin espacios ni caracteres especiales.';
    }
    return null;
  }

  static String? email(String value) {
    final email = value.trim();
    if (email.isEmpty) return 'El correo es obligatorio.';
    if (email.length > 254 || email.contains('..')) return _errorEmail;

    final partes = email.split('@');
    if (partes.length != 2 || !_parteLocalEmail.hasMatch(partes.first)) {
      return _errorEmail;
    }

    final dominio = partes.last.toLowerCase().split('.');
    if (dominio.length < 2 ||
        dominio.any((parte) => !_etiquetaDominio.hasMatch(parte))) {
      return _errorEmail;
    }

    final extension = dominio.last;
    final esExtensionDePais = extension.length == 2;
    if (!esExtensionDePais && !_extensionesGenericas.contains(extension)) {
      return 'Usa una extensión de correo válida, por ejemplo: .com o .mx.';
    }

    return null;
  }

  static const String _errorEmail =
      'Usa un correo válido, por ejemplo: nombre@correo.com.';
}