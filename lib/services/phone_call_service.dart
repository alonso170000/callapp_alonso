import 'package:url_launcher/url_launcher.dart';
import 'package:callerapp_frontend/services/phone_number.dart';

typedef PhoneUriChecker = Future<bool> Function(Uri uri);
typedef PhoneUriLauncher = Future<bool> Function(Uri uri);

class PhoneCallException implements Exception {
  const PhoneCallException(this.message);

  final String message;
}

class PhoneCallService {
  PhoneCallService({PhoneUriChecker? canLaunch, PhoneUriLauncher? launch})
    : _canLaunch = canLaunch ?? canLaunchUrl,
      _launch = launch ?? _launchExternally;

  final PhoneUriChecker _canLaunch;
  final PhoneUriLauncher _launch;

  static Future<bool> _launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  static String normalizeNumber(String raw) => PhoneNumber.normalize(raw);

  Future<void> call(String rawNumber) async {
    final number = normalizeNumber(rawNumber);
    if (!PhoneNumber.isDialable(rawNumber)) {
      throw const PhoneCallException(
        'El prospecto no tiene un teléfono válido para llamar.',
      );
    }

    final uri = PhoneNumber.telUri(number);
    try {
      if (await _canLaunch(uri) && await _launch(uri)) return;
    } catch (_) {
      // El plugin puede no estar registrado aún tras un hot reload. La UI solo
      // recibe un error de dominio, nunca una excepción de plataforma cruda.
    }
    throw const PhoneCallException(
      'No se pudo abrir el marcador del teléfono.',
    );
  }
}
