import 'package:flutter/material.dart';

class ProspectRecord {
  final String name;
  final String phone;
  final String email;
  final String status;
  final String temperature;
  final Color avatarColor;
  final Color statusColor;
  final DateTime appointment;
  final int daysSinceContact;
  final DateTime? assignedAt;
  final DateTime? nextContact;
  final String lastContactResult;

  const ProspectRecord({
    required this.name,
    required this.phone,
    required this.email,
    required this.status,
    required this.temperature,
    required this.avatarColor,
    required this.statusColor,
    required this.appointment,
    this.daysSinceContact = 1,
    this.assignedAt,
    this.nextContact,
    this.lastContactResult = 'Sin contacto',
  });

  String get note =>
      'Llamada de seguimiento agendada para el lunes que no fue atendida. Llamada de seguimiento agendada para el lunes que no fue atendida. Pendiente de confirmar una nueva cita.';
}

// Datos de muestra hasta conectar el servicio de prospectos.
final _demoToday = DateUtils.dateOnly(DateTime.now());
final demoProspects = <ProspectRecord>[
  ProspectRecord(
    name: 'Betsua',
    phone: '9980000001',
    email: 'betsua@example.com',
    status: 'Atrasados',
    temperature: 'Caliente',
    avatarColor: const Color(0xFFBF4242),
    statusColor: const Color(0xFFFFA3A6),
    appointment: DateTime(2026, 9, 14, 10, 30),
    assignedAt: DateTime(_demoToday.year, _demoToday.month, _demoToday.day - 0),
    lastContactResult: 'Contestó',
    nextContact: DateTime(
      _demoToday.year,
      _demoToday.month,
      _demoToday.day + 0,
      10,
    ),
  ),
  ProspectRecord(
    name: 'Alan Dorantes',
    phone: '9980000002',
    email: 'alan@example.com',
    status: 'Contactado y validado',
    temperature: 'Caliente',
    avatarColor: const Color(0xFF88F6A2),
    statusColor: const Color(0xFFE49CEE),
    appointment: DateTime(2026, 9, 14, 11, 30),
    assignedAt: DateTime(_demoToday.year, _demoToday.month, _demoToday.day - 1),
    lastContactResult: 'Cita programada',
    nextContact: DateTime(
      _demoToday.year,
      _demoToday.month,
      _demoToday.day + 1,
      11,
    ),
  ),
  ProspectRecord(
    name: 'Juan Uch',
    phone: '9980000003',
    email: 'juan@example.com',
    status: 'Nuevo',
    temperature: 'Tibio',
    avatarColor: const Color(0xFF27BBC1),
    statusColor: const Color(0xFF67D9EC),
    appointment: DateTime(2026, 9, 14, 12),
    assignedAt: DateTime(_demoToday.year, _demoToday.month, _demoToday.day - 2),
    lastContactResult: 'Sin contacto',
  ),
  ProspectRecord(
    name: 'Joshua',
    phone: '9980000004',
    email: 'joshua@example.com',
    status: 'Negociación',
    temperature: 'Tibio',
    avatarColor: const Color(0xFF94E5EF),
    statusColor: const Color(0xFFFFCA86),
    appointment: DateTime(2026, 9, 14, 13, 30),
    assignedAt: DateTime(_demoToday.year, _demoToday.month, _demoToday.day - 3),
    lastContactResult: 'No contestó',
    nextContact: DateTime(
      _demoToday.year,
      _demoToday.month,
      _demoToday.day + 0,
      13,
    ),
  ),
  ProspectRecord(
    name: 'Luis Antonio',
    phone: '9980000005',
    email: 'luis@example.com',
    status: 'Cotización',
    temperature: 'Caliente',
    avatarColor: const Color(0xFFBF4242),
    statusColor: const Color(0xFFB69BF5),
    appointment: DateTime(2026, 9, 14, 14, 30),
    assignedAt: DateTime(_demoToday.year, _demoToday.month, _demoToday.day - 4),
    lastContactResult: 'Contestó',
    nextContact: DateTime(
      _demoToday.year,
      _demoToday.month,
      _demoToday.day + 1,
      14,
    ),
    daysSinceContact: 2,
  ),
  ProspectRecord(
    name: 'María José Sánchez',
    phone: '9980000006',
    email: 'maria@example.com',
    status: 'Seguimiento',
    temperature: 'Frío',
    avatarColor: const Color(0xFF27BBC1),
    statusColor: const Color(0xFFFFEA88),
    appointment: DateTime(2026, 9, 14, 15, 30),
    assignedAt: DateTime(_demoToday.year, _demoToday.month, _demoToday.day - 5),
    lastContactResult: 'No contestó',
    nextContact: DateTime(
      _demoToday.year,
      _demoToday.month,
      _demoToday.day + 2,
      15,
    ),
    daysSinceContact: 2,
  ),
];
