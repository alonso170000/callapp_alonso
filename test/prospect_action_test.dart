import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/contact_medium.dart';
import 'package:callerapp_frontend/presentation/models/prospect_action.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const prospect = ProspectRecord(
    id: 7,
    name: 'Ana',
    phone: '9991234567',
    email: 'ana@example.com',
    status: 'Nuevo',
    temperature: 'Caliente',
    avatarColor: Colors.teal,
    statusColor: Colors.cyan,
  );

  AgendaActivity activity({
    String type = 'seguimiento',
    String? medium = 'whatsapp',
    AgendaStatus status = AgendaStatus.pending,
    int day = 2,
  }) => AgendaActivity(
    id: day,
    prospectId: 7,
    type: type,
    medium: medium,
    title: type.toUpperCase(),
    prospect: 'ANA',
    description: '',
    date: DateTime(2026, 11, day),
    status: status,
  );

  test('elige WhatsApp para un seguimiento pendiente', () {
    final value = ProspectAction.resolve(
      prospect: prospect,
      activities: [activity()],
    );
    expect(value.medium, ContactMedium.whatsapp);
    expect(value.activity, isNotNull);
  });

  test('elige llamada para un seguimiento atrasado', () {
    final value = ProspectAction.resolve(
      prospect: prospect,
      activities: [activity(medium: 'telefono', status: AgendaStatus.overdue)],
    );
    expect(value.medium, ContactMedium.llamada);
  });

  test('ignora seguimientos completados y cancelados', () {
    final value = ProspectAction.resolve(
      prospect: prospect,
      activities: [
        activity(status: AgendaStatus.completed),
        activity(status: AgendaStatus.cancelled),
      ],
    );
    expect(value.medium, ContactMedium.llamada);
    expect(value.activity, isNull);
  });

  test('ignora visitas y tareas', () {
    final value = ProspectAction.resolve(
      prospect: prospect,
      activities: [
        activity(type: 'visita'),
        activity(type: 'tarea'),
      ],
    );
    expect(value.medium, ContactMedium.llamada);
  });

  test('sin actividades usa llamada cuando hay teléfono', () {
    expect(
      ProspectAction.resolve(prospect: prospect, activities: const []).medium,
      ContactMedium.llamada,
    );
  });

  test('sin teléfono usa correo', () {
    final value = ProspectAction.resolve(
      prospect: prospect.copyWith(phone: ''),
      activities: const [],
    );
    expect(value.medium, ContactMedium.correo);
  });

  test('un atrasado gana a un pendiente futuro', () {
    final value = ProspectAction.resolve(
      prospect: prospect,
      activities: [
        activity(medium: 'correo', day: 1),
        activity(medium: 'telefono', status: AgendaStatus.overdue, day: 3),
      ],
    );
    expect(value.medium, ContactMedium.llamada);
    expect(value.isOverdue, isTrue);
  });
}
