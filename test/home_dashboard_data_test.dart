import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/home_dashboard_data.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';

void main() {
  test('New prospects include every assignment date, newest first and missing dates last', () {
    ProspectRecord record(int id, DateTime? date, {String status = 'Nuevo'}) =>
        ProspectRecord(
          id: id,
          name: 'Persona $id',
          phone: '',
          email: '',
          status: status,
          temperature: '',
          avatarColor: Colors.teal,
          statusColor: Colors.orange,
          assignedAt: date,
        );
    final records = [
      record(1, DateTime(2026, 9, 1)),
      record(2, null),
      record(3, DateTime(2026, 10, 12)),
      record(4, DateTime(2026, 10, 13), status: 'Seguimiento'),
    ];
    final data = HomeDashboardData(
      records,
      [],
      DateTime(2026, 10, 13),
      selectedDate: DateTime(2026, 1, 1),
    );
    expect(data.newProspects.map((p) => p.id), [3, 1, 2]);
  });
  test('Dashboard excludes other media and cancellations and deduplicates prospects', () {
    final now = DateTime(2026, 10, 13, 12);
    AgendaActivity activity(
      int hour,
      AgendaStatus status, {
      String medium = 'llamada',
      int? prospect = 7,
    }) => AgendaActivity(
      type: 'seguimiento',
      medium: medium,
      title: 'Seguimiento',
      prospect: 'Ana',
      prospectId: prospect,
      description: '',
      date: DateTime(2026, 10, 13, hour),
      status: status,
    );
    final data = HomeDashboardData(
      [
        ProspectRecord(
          id: 7,
          name: 'Ana',
          phone: '',
          email: '',
          status: 'Nuevo',
          assignedAt: now,
          temperature: '',
          avatarColor: Colors.teal,
          statusColor: Colors.orange,
        ),
      ],
      [
        activity(9, AgendaStatus.completed),
        activity(10, AgendaStatus.overdue),
        activity(15, AgendaStatus.pending),
        activity(11, AgendaStatus.cancelled),
        activity(16, AgendaStatus.pending, medium: 'whatsapp'),
        activity(17, AgendaStatus.pending, prospect: null),
      ],
      now,
    );
    expect(data.completed, 1);
    expect(data.pending, 3);
    expect(data.overdueCalls.length, 1);
    expect(data.todayProspects.length, 1);
    expect(data.newProspects.single.id, 7);
    expect(data.week[1].calls, 4);
    expect(data.week[1].isSelected, isTrue);
    expect(data.week.first.calls, 0);
  });
}
