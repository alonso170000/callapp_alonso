import 'package:flutter/foundation.dart';

import 'platform_support_web.dart'
    if (dart.library.io) 'platform_support_io.dart';

/// Capacidades de la plataforma donde corre la app.
///
/// El almacenamiento local con SQLite y la sesión persistida solo se habilitan
/// en Android. En el resto de plataformas la app sigue funcionando únicamente
/// contra la API, sin lanzar errores por dependencias nativas ausentes.
class PlatformSupport {
  const PlatformSupport._();

  static bool get isAndroid => !kIsWeb && platformIsAndroid;
}
