enum AgendaPeriod { day, week, month }

enum AgendaStatus {
  completed('COMPLETADA'),
  overdue('ATRASADO'),
  pending('PENDIENTE'),
  cancelled('CANCELADA');

  const AgendaStatus(this.label);
  final String label;
}

class AgendaActivity {
  final String? prospectAvatarUrl;
  final DateTime? deleteUntil;
  bool get isFollowUp => (type ?? title).trim().toLowerCase() == 'seguimiento';
  final int? id;
  final int? prospectId;
  final String? type;
  final String? medium;
  final String title;
  final String prospect;
  final String description;
  final DateTime date;
  final AgendaStatus status;
  final List<String> tags;
  final String location;
  final int reminderMinutes;
  final bool hasReminder;
  final String lastContact;

  const AgendaActivity({
    this.prospectAvatarUrl,
    this.deleteUntil,
    this.id,
    this.prospectId,
    this.type,
    this.medium,
    required this.title,
    required this.prospect,
    required this.description,
    required this.date,
    required this.status,
    this.tags = const [],
    this.location = 'Sin ubicación',
    this.reminderMinutes = 15,
    this.hasReminder = true,
    this.lastContact = 'Llamada · Hace 1 día',
  });

  AgendaActivity copyWith({AgendaStatus? status}) => AgendaActivity(
    prospectAvatarUrl: prospectAvatarUrl,
    deleteUntil: deleteUntil,
    id: id,
    prospectId: prospectId,
    type: type,
    medium: medium,
    title: title,
    prospect: prospect,
    description: description,
    date: date,
    status: status ?? this.status,
    tags: tags,
    location: location,
    reminderMinutes: reminderMinutes,
    hasReminder: hasReminder,
    lastContact: lastContact,
  );
}

List<AgendaActivity> demoAgendaActivities(DateTime day) => [
  AgendaActivity(
    title: 'SEGUIMIENTO',
    prospect: 'ALAN DORANTES',
    description: 'Llamada de seguimiento agendada para revisar la propuesta y confirmar la próxima cita.',
    date: DateTime(day.year, day.month, day.day, 9, 30),
    status: AgendaStatus.completed,
    tags: ['CONTACTADO Y VALIDADO', 'CALIENTE'],
  ),
  AgendaActivity(
    title: 'TAREA',
    prospect: 'ALAN DORANTES',
    description: 'Enviar corrida financiera.',
    date: DateTime(day.year, day.month, day.day, 11),
    status: AgendaStatus.overdue,
  ),
  AgendaActivity(
    title: 'VISITA PRESENCIAL',
    prospect: 'ALAN DORANTES',
    description: 'Visita presencial agendada para recorrer el lote 23 con Alan Dorantes. Revisar detalles de la corrida financiera y responder preguntas sobre la delimitación física del terreno.',
    date: DateTime(day.year, day.month, day.day, 15),
    status: AgendaStatus.pending,
    tags: ['CONTACTADO Y VALIDADO'],
    location: 'LOTE',
  ),
];
