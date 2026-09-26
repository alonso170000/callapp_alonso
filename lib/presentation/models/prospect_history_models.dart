enum ProspectContactResult { answered, unanswered, appointment }

class ProspectHistoryComment {
  final String comment;
  final DateTime createdAt;
  final List<ProspectContactResult> results;

  const ProspectHistoryComment({
    required this.comment,
    required this.createdAt,
    required this.results,
  });
}

class ProspectDiscoverySummary {
  final String decision;
  final String disposition;
  final String money;
  final String transferredTo;
  final String completed;

  const ProspectDiscoverySummary({
    required this.decision,
    required this.disposition,
    required this.money,
    required this.transferredTo,
    required this.completed,
  });
}

class ProspectEmailHistoryEntry {
  final String templateName;
  final String description;
  final DateTime sentAt;

  const ProspectEmailHistoryEntry({
    required this.templateName,
    required this.description,
    required this.sentAt,
  });
}

enum ProspectCallHourStatus { answered, rejected }

class ProspectCallHourEntry {
  final int weekday;
  final int hour;
  final ProspectCallHourStatus status;

  const ProspectCallHourEntry({
    required this.weekday,
    required this.hour,
    required this.status,
  });
}

final demoProspectHistoryComments = <ProspectHistoryComment>[
  ProspectHistoryComment(
    comment: 'Me comentó que no está interesado en el lote',
    createdAt: DateTime(2026, 9, 12, 10, 23),
    results: [ProspectContactResult.answered],
  ),
  ProspectHistoryComment(
    comment: 'No dijo nada porque no contestó; se programa cita',
    createdAt: DateTime(2026, 9, 11, 14, 46),
    results: [
      ProspectContactResult.unanswered,
      ProspectContactResult.appointment,
    ],
  ),
];

const demoProspectDiscoverySummary = ProspectDiscoverySummary(
  decision: 'No',
  disposition: 'No',
  money: 'No',
  transferredTo: 'No',
  completed: 'No',
);

final demoProspectEmailHistory = <ProspectEmailHistoryEntry>[
  ProspectEmailHistoryEntry(
    templateName: 'RUNASecondEmail',
    description: 'Segundo Correo Runa Yucatán enviado',
    sentAt: DateTime(2026, 9, 15, 17, 25),
  ),
  ProspectEmailHistoryEntry(
    templateName: 'WelcomeEmail',
    description: 'Correo de Bienvenida enviado',
    sentAt: DateTime(2026, 9, 15, 17, 24),
  ),
];

const demoProspectCallHours = <ProspectCallHourEntry>[
  ProspectCallHourEntry(
    weekday: DateTime.monday,
    hour: 10,
    status: ProspectCallHourStatus.answered,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.monday,
    hour: 14,
    status: ProspectCallHourStatus.answered,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.tuesday,
    hour: 11,
    status: ProspectCallHourStatus.answered,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.tuesday,
    hour: 13,
    status: ProspectCallHourStatus.rejected,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.tuesday,
    hour: 17,
    status: ProspectCallHourStatus.answered,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.wednesday,
    hour: 12,
    status: ProspectCallHourStatus.answered,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.wednesday,
    hour: 13,
    status: ProspectCallHourStatus.answered,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.wednesday,
    hour: 16,
    status: ProspectCallHourStatus.rejected,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.thursday,
    hour: 14,
    status: ProspectCallHourStatus.rejected,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.thursday,
    hour: 15,
    status: ProspectCallHourStatus.answered,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.friday,
    hour: 11,
    status: ProspectCallHourStatus.answered,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.friday,
    hour: 15,
    status: ProspectCallHourStatus.answered,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.friday,
    hour: 18,
    status: ProspectCallHourStatus.answered,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.saturday,
    hour: 10,
    status: ProspectCallHourStatus.rejected,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.saturday,
    hour: 12,
    status: ProspectCallHourStatus.answered,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.saturday,
    hour: 13,
    status: ProspectCallHourStatus.answered,
  ),
  ProspectCallHourEntry(
    weekday: DateTime.saturday,
    hour: 16,
    status: ProspectCallHourStatus.answered,
  ),
];
