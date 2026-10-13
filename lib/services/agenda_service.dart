import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';

class AgendaException implements Exception {
  const AgendaException(this.message);
  final String message;
}

class AgendaService {
  AgendaService({http.Client? client, AuthService? auth})
    : _client = client ?? http.Client(),
      _auth = auth ?? AuthService.instance;
  final http.Client _client;
  final AuthService _auth;

  Future<void> create(Map<String, dynamic> fields) async {
    final token = _auth.token;
    if (token == null) throw const AgendaException('Inicia sesión nuevamente.');
    try {
      final response = await _client
          .post(
            Uri.parse('${_auth.baseUrl}/api/v1/activities'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(fields),
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 401) {
        throw const AgendaException(
          'Tu sesión expiró. Vuelve a iniciar sesión.',
        );
      }
      if (response.statusCode >= 500) {
        throw const AgendaException(
          'No se pudo guardar la actividad. Intenta nuevamente.',
        );
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 201 ||
          data is! Map ||
          data['success'] != true) {
        throw AgendaException(
          data is Map && data['message'] is String
              ? data['message'] as String
              : 'No se pudo guardar la actividad.',
        );
      }
      if (data['data'] is! Map || data['data']['id'] is! int) {
        throw const FormatException();
      }
    } on TimeoutException {
      throw const AgendaException(
        'El servidor tardó demasiado. Actualiza la agenda antes de volver a guardar para comprobar si se creó.',
      );
    } on http.ClientException {
      throw const AgendaException('No se pudo conectar. Revisa tu conexión.');
    } on FormatException {
      throw const AgendaException(
        'No se pudo confirmar la creación. Actualiza la agenda antes de volver a guardar.',
      );
    }
  }

  Future<List<AgendaActivity>> fetch() async {
    final token = _auth.token;
    if (token == null) {
      throw const AgendaException('Inicia sesión para ver tu agenda.');
    }
    try {
      final response = await _client
          .get(
            Uri.parse('${_auth.baseUrl}/api/v1/activities'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AgendaException(
          'Tu sesión expiró. Vuelve a iniciar sesión.',
        );
      }
      if (response.statusCode == 404) {
        throw const AgendaException(
          'El servidor aún no tiene disponible la agenda. Actualiza el despliegue del backend.',
        );
      }
      if (response.statusCode >= 500) {
        throw AgendaException(
          'El servidor no pudo consultar las actividades (HTTP ${response.statusCode}). Revisa el error en los logs de Render.',
        );
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200 ||
          data is! Map ||
          data['success'] != true ||
          data['data'] is! List) {
        throw AgendaException(
          response.statusCode == 400 && data is Map && data['message'] is String
              ? data['message'] as String
              : 'No se pudieron cargar las actividades (HTTP ${response.statusCode}). Intenta nuevamente.',
        );
      }
      final now = DateTime.now();
      return (data['data'] as List)
          .map(
            (row) => fromJson(Map<String, dynamic>.from(row as Map), now: now),
          )
          .toList();
    } on TimeoutException {
      throw const AgendaException(
        'El servidor tardó demasiado. Intenta nuevamente.',
      );
    } on http.ClientException {
      throw const AgendaException('No se pudo conectar. Revisa tu conexión.');
    } on FormatException {
      throw const AgendaException(
        'El servidor devolvió una respuesta inválida.',
      );
    } on TypeError {
      throw const AgendaException(
        'El servidor devolvió actividades inválidas.',
      );
    }
  }

  static AgendaActivity fromJson(
    Map<String, dynamic> row, {
    required DateTime now,
  }) {
    final date = DateTime.tryParse('${row['programada_at']}')?.toLocal();
    final id = int.tryParse('${row['id']}');
    if (date == null || id == null) throw const FormatException();
    final status = switch (row['estado']) {
      'completada' => AgendaStatus.completed,
      'cancelada' => AgendaStatus.cancelled,
      'pendiente' =>
        date.isBefore(now) ? AgendaStatus.overdue : AgendaStatus.pending,
      _ => throw const FormatException(),
    };
    final type = (row['tipo'] as String).replaceAll('_', ' ');
    final reminder = DateTime.tryParse('${row['recordatorio_at']}')?.toLocal();
    return AgendaActivity(
      id: id,
      prospectId: int.tryParse('${row['prospecto_id']}'),
      type: type,
      medium: row['medio'] as String?,
      title: row['titulo'] as String? ?? type,
      prospect: row['prospecto_nombre'] as String? ?? 'Actividad personal',
      description: row['descripcion'] as String? ?? 'Sin descripción',
      date: date,
      status: status,
      location: row['ubicacion'] as String? ?? 'Sin ubicación',
      reminderMinutes: reminder == null
          ? 0
          : date.difference(reminder).inMinutes.clamp(0, 100000),
      hasReminder: reminder != null,
      lastContact: 'Sin información de último contacto',
      tags: [
        if (row['prospecto_estatus'] is String)
          row['prospecto_estatus'] as String,
        if (row['prioridad'] is String)
          (row['prioridad'] as String).replaceAll('frio', 'frío'),
      ],
    );
  }

  void dispose() => _client.close();
}
