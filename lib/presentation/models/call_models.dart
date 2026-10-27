import 'package:callerapp_frontend/services/business_clock.dart';

enum ProspectCallOutcome {
  answered,
  unanswered,
  voicemail,
  invalidNumber,
  other,
}

extension ProspectCallOutcomeValue on ProspectCallOutcome {
  String get value => switch (this) {
    ProspectCallOutcome.answered => 'contestada',
    ProspectCallOutcome.unanswered => 'no_contestada',
    ProspectCallOutcome.voicemail => 'buzon',
    ProspectCallOutcome.invalidNumber => 'numero_invalido',
    ProspectCallOutcome.other => 'otro',
  };

  String get label => switch (this) {
    ProspectCallOutcome.answered => 'Sí, contestó',
    ProspectCallOutcome.unanswered => 'No contestó',
    ProspectCallOutcome.voicemail => 'Buzón de voz',
    ProspectCallOutcome.invalidNumber => 'Número inválido',
    ProspectCallOutcome.other => 'Otro resultado',
  };

  bool get successful => this == ProspectCallOutcome.answered;
}

class ProspectCallSession {
  const ProspectCallSession({
    required this.startedAt,
    required this.endedAt,
    required this.outcome,
    required this.phone,
    required this.origin,
    this.sourceActivityId,
    this.realDurationSeconds,
    this.callLogId,
    this.deviceId,
    this.audioPath,
    this.audioName,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final ProspectCallOutcome outcome;
  final String phone;
  final String origin;
  final int? sourceActivityId;
  final int? realDurationSeconds;
  final String? callLogId;
  final String? deviceId;
  final String? audioPath;
  final String? audioName;

  int get durationSeconds =>
      realDurationSeconds ??
      endedAt.difference(startedAt).inSeconds.clamp(0, 86400);
  bool get durationEstimated => realDurationSeconds == null;

  Map<String, dynamic> toPayload({
    String? summary,
    List<String> topics = const [],
  }) => {
    'iniciada_at': businessTimeToUtcIso8601(startedAt),
    'fin_at': businessTimeToUtcIso8601(endedAt),
    'duracion_estimada': durationEstimated,
    'resultado': outcome.value,
    'telefono_marcado': phone,
    'origen': origin,
    if (sourceActivityId != null) 'actividad_id': sourceActivityId,
    if (realDurationSeconds != null) 'duracion_segundos': realDurationSeconds,
    if (callLogId != null) 'call_log_id': callLogId,
    if (deviceId != null) 'dispositivo_id': deviceId,
    if (summary != null && summary.trim().isNotEmpty) 'resumen': summary.trim(),
    if (topics.isNotEmpty) 'resumen_temas': topics,
    'consentimiento_grabacion': true,
  };
}

class ProspectCallRecord {
  const ProspectCallRecord({
    required this.id,
    required this.startedAt,
    required this.durationSeconds,
    required this.durationEstimated,
    required this.outcome,
    required this.phone,
    required this.audioState,
    this.summary,
    this.audioUrl,
  });

  final int id;
  final DateTime startedAt;
  final int? durationSeconds;
  final bool durationEstimated;
  final String outcome;
  final String phone;
  final String audioState;
  final String? summary;
  final String? audioUrl;
}
