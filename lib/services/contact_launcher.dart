import 'package:callerapp_frontend/presentation/models/contact_medium.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/services/notification_service.dart';
import 'package:callerapp_frontend/services/phone_number.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactLauncher {
  const ContactLauncher();

  Future<bool> openFacebook() async {
    for (final url in const ['fb://', 'https://www.facebook.com']) {
      try {
        final opened = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (opened) return true;
      } on Object {
        // Se intenta la siguiente alternativa (app o sitio web).
      }
    }
    return false;
  }

  Future<bool> openWhatsApp(
    ProspectRecord prospect, {
    AgendaActivity? activity,
  }) async {
    if (!PhoneNumber.isDialable(prospect.phone)) return false;
    final digits = PhoneNumber.digits(prospect.phone);
    try {
      final opened = await launchUrl(
        Uri.parse('https://wa.me/$digits'),
        mode: LaunchMode.externalApplication,
      );
      if (opened) {
        await NotificationService.instance.showFollowUpReminder(
          prospect,
          activity,
        );
      }
      return opened;
    } on Object {
      return false;
    }
  }

  Future<bool> openEmail(
    ProspectRecord prospect, {
    AgendaActivity? activity,
  }) async {
    if (!ContactMedium.correo.isAvailable(prospect)) return false;
    try {
      final opened = await launchUrl(
        Uri(scheme: 'mailto', path: prospect.email),
        mode: LaunchMode.externalApplication,
      );
      if (opened) {
        await NotificationService.instance.showFollowUpReminder(
          prospect,
          activity,
        );
      }
      return opened;
    } on Object {
      return false;
    }
  }
}
