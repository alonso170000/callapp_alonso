import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/contact_medium.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';

class ProspectAction {
  const ProspectAction({required this.medium, this.activity});

  final ContactMedium medium;
  final AgendaActivity? activity;

  bool get hasActivity => activity != null;
  bool get isOverdue => activity?.status == AgendaStatus.overdue;

  static ProspectAction resolve({
    required ProspectRecord prospect,
    required List<AgendaActivity> activities,
  }) {
    final candidates =
        activities
            .where(
              (activity) =>
                  activity.prospectId == prospect.id &&
                  activity.isFollowUp &&
                  (activity.status == AgendaStatus.pending ||
                      activity.status == AgendaStatus.overdue) &&
                  ContactMedium.parse(activity.medium) != null,
            )
            .toList()
          ..sort((first, second) {
            final firstOrder = first.status == AgendaStatus.overdue ? 0 : 1;
            final secondOrder = second.status == AgendaStatus.overdue ? 0 : 1;
            final statusOrder = firstOrder.compareTo(secondOrder);
            return statusOrder != 0
                ? statusOrder
                : first.date.compareTo(second.date);
          });
    if (candidates.isNotEmpty) {
      final activity = candidates.first;
      return ProspectAction(
        medium: ContactMedium.parse(activity.medium)!,
        activity: activity,
      );
    }
    return ProspectAction(
      medium: ContactMedium.llamada.isAvailable(prospect)
          ? ContactMedium.llamada
          : ContactMedium.correo,
    );
  }
}
