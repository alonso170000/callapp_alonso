enum AgendaPeriod { day, week, month }

enum AgendaStatus {
  completed('COMPLETADA'),
  overdue('ATRASADO'),
  pending('PENDIENTE');

  const AgendaStatus(this.label);
  final String label;
}

class AgendaActivity {
  final String title;
  final String prospect;
  final String description;
  final DateTime date;
  final AgendaStatus status;
  final List<String> tags;

  const AgendaActivity({
    required this.title,
    required this.prospect,
    required this.description,
    required this.date,
    required this.status,
    this.tags = const [],
  });
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
    description: 'Visita de Alan al lote 23.',
    date: DateTime(day.year, day.month, day.day, 15),
    status: AgendaStatus.pending,
    tags: ['LOTE'],
  ),
];
