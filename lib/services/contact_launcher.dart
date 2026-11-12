import 'package:callerapp_frontend/presentation/models/contact_medium.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/services/phone_number.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactLauncher {
  const ContactLauncher();

  Future<bool> openWhatsApp(ProspectRecord prospect) async {
    if (!PhoneNumber.isDialable(prospect.phone)) return false;
    final digits = PhoneNumber.digits(prospect.phone);
    try {
      return await launchUrl(
        Uri.parse('https://wa.me/$digits'),
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      return false;
    }
  }

  Future<bool> openEmail(ProspectRecord prospect) async {
    if (!ContactMedium.correo.isAvailable(prospect)) return false;
    try {
      return await launchUrl(
        Uri(scheme: 'mailto', path: prospect.email),
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      return false;
    }
  }
}
