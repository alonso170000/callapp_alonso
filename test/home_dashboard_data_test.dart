import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/home_dashboard_data.dart';
import 'package:callerapp_frontend/presentation/models/home_models.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';

void main() {
  test(
    'todayEntries groups prospects and prioritizes their nearest open activity',
    () {
      ProspectRecord prospect(int id) => ProspectRecord(
        id: id,
        name: 'Persona $id',
        phone: '',
        email: '',
        status: 'Seguimiento',
        temperature: '',
        avatarColor: Colors.teal,
        statusColor: Colors.orange,
      );
      AgendaActivity activity(
        int id,
        int prospectId,
        int hour,
        AgendaStatus status,
      ) => AgendaActivity(
        id: id,
        prospectId: prospectId,
        title: 'Actividad $id',
        prospect: 'Persona $prospectId',
        description: '',
        date: DateTime(2026, 10, 13, hour),
        status: status,
      );
      final data = HomeDashboardData(
        [prospect(1), prospect(2), prospect(3), prospect(4)],
        [
          activity(1, 1, 9, AgendaStatus.overdue),
          activity(2, 3, 10, AgendaStatus.completed),
          activity(3, 2, 11, AgendaStatus.pending),
          activity(4, 2, 8, AgendaStatus.completed),
        ],
        DateTime(2026, 10, 13, 12),
      );

      expect(data.todayEntries.map((entry) => entry.prospect.id), [1, 2, 3]);
      expect(data.todayEntries.map((entry) => entry.marker), [
        ProspectActivityMarker.overdue,
        ProspectActivityMarker.pending,
        null,
      ]);
      expect(
        data.todayEntries.where((entry) => entry.prospect.id == 2),
        hasLength(1),
      );
      expect(
        data.todayEntries
            .firstWhere((entry) => entry.prospect.id == 2)
            .activity
            .id,
        3,
      );
    },
  );

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
  test(
    'Dashboard counts multichannel follow-ups and keeps call-only metrics',
    () {
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
          activity(8, AgendaStatus.completed, medium: 'whatsapp'),
          activity(7, AgendaStatus.overdue, medium: 'whatsapp'),
          activity(14, AgendaStatus.pending, medium: 'facebook'),
          activity(11, AgendaStatus.overdue, medium: 'correo'),
          activity(12, AgendaStatus.pending, medium: 'visita'),
        ],
        now,
      );
      expect(data.completed, 2);
      expect(data.pending, 7);
      expect(data.followUpsToday.length, 10);
      expect(data.overdueFollowUps.map((activity) => activity.medium), [
        'whatsapp',
        'llamada',
        'correo',
      ]);
      expect(data.todayProspects.length, 1);
      expect(data.newProspects.single.id, 7);
      expect(data.week[1].calls, 4);
      expect(data.week[1].isSelected, isTrue);
      expect(data.week.first.calls, 0);
    },
  );
}
