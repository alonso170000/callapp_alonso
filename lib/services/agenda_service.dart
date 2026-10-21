import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/services/notification_service.dart';

class AgendaException implements Exception {
  const AgendaException(this.message);
  final String message;
}

class AgendaRecoverableException extends AgendaException {
  const AgendaRecoverableException(super.message);
}

class AgendaIndeterminateException extends AgendaRecoverableException {
  const AgendaIndeterminateException(super.message);
}

class AgendaSessionException extends AgendaException {
  const AgendaSessionException(super.message);
}

class AgendaBusinessException extends AgendaException {
  const AgendaBusinessException(super.message);
}

class AgendaService {
  AgendaService({http.Client? client, AuthService? auth})
    : _client = client ?? http.Client(),
      _auth = auth ?? AuthService.instance;
  final http.Client _client;
  final AuthService _auth;

  Future<void> complete(int id, {String? operationKey}) =>
      _changeStatus(id, 'completada', operationKey: operationKey);

  Future<void> cancel(int id, {String? operationKey}) =>
      _changeStatus(id, 'cancelada', operationKey: operationKey);

  Future<void> _changeStatus(
    int id,
    String status, {
    String? operationKey,
  }) async {
    final token = _auth.token;
    if (token == null) throw const AgendaException('Inicia sesión nuevamente.');
    try {
      final response = await _client
          .patch(
            Uri.parse('${_auth.baseUrl}/api/v1/activities/$id/status'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Idempotency-Key': ?operationKey,
            },
            body: jsonEncode({'estado': status}),
          )
          .timeout(const Duration(seconds: 60));
      final data = _decode(response);
      await _ensureSession(response, data);
      if (response.statusCode >= 500) {
        throw const AgendaRecoverableException(
          'El servidor no pudo actualizar la actividad. Se reintentará.',
        );
      }
      if (response.statusCode != 200 ||
          data is! Map ||
          data['success'] != true) {
        throw AgendaBusinessException(
          data is Map && data['message'] is String
              ? data['message'] as String
              : 'No se pudo actualizar la actividad.',
        );
      }
    } on TimeoutException {
      throw const AgendaIndeterminateException(
        'El servidor tardó demasiado. Actualiza la agenda para comprobar el estado de la actividad.',
      );
    } on http.ClientException {
      throw const AgendaRecoverableException(
        'No se pudo conectar. El cambio se sincronizará después.',
      );
    } on FormatException {
      throw const AgendaIndeterminateException(
        'No se pudo confirmar el cambio. Actualiza la agenda.',
      );
    }
  }

  Future<void> delete(int id, {String? operationKey}) async {
    final token = _auth.token;
    if (token == null) throw const AgendaException('Inicia sesión nuevamente.');
    try {
      final response = await _client
          .delete(
            Uri.parse('${_auth.baseUrl}/api/v1/activities/$id'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Idempotency-Key': ?operationKey,
            },
          )
          .timeout(const Duration(seconds: 60));
      final data = _decode(response);
      await _ensureSession(response, data);
      if (response.statusCode >= 500) {
        throw const AgendaRecoverableException(
          'El servidor no pudo eliminar la actividad. Se reintentará.',
        );
      }
      if (response.statusCode != 200 ||
          data is! Map ||
          data['success'] != true) {
        throw AgendaBusinessException(
          response.statusCode == 409 && data is Map && data['message'] is String
              ? data['message'] as String
              : 'No se pudo eliminar la actividad. Actualiza la agenda e intenta nuevamente.',
        );
      }
    } on TimeoutException {
      throw const AgendaIndeterminateException(
        'El servidor tardó demasiado. Actualiza la agenda para comprobar si se eliminó.',
      );
    } on http.ClientException {
      throw const AgendaRecoverableException(
        'No se pudo conectar. La eliminación se sincronizará después.',
      );
    } on FormatException {
      throw const AgendaIndeterminateException(
        'No se pudo confirmar la eliminación. Actualiza la agenda.',
      );
    }
  }

  Future<AgendaActivity> create(
    Map<String, dynamic> fields, {
    String? operationKey,
  }) async {
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
              'Idempotency-Key': ?operationKey,
            },
            body: jsonEncode(fields),
          )
          .timeout(const Duration(seconds: 60));
      final data = _decode(response);
      await _ensureSession(response, data);
      if (response.statusCode >= 500) {
        throw const AgendaRecoverableException(
          'No se pudo guardar la actividad. Intenta nuevamente.',
        );
      }
      if (response.statusCode != 201 ||
          data is! Map ||
          data['success'] != true) {
        throw AgendaBusinessException(
          data is Map && data['message'] is String
              ? data['message'] as String
              : 'No se pudo guardar la actividad.',
        );
      }
      if (data['data'] is! Map || data['data']['id'] is! int) {
        throw const FormatException();
      }
      final created = Map<String, dynamic>.from(data['data'] as Map);
      try {
        return fromJson(created, now: businessNow(), baseUrl: _auth.baseUrl);
      } on FormatException {
        final instant = DateTime.tryParse('${fields['programada_at']}');
        if (instant == null) rethrow;
        final type = '${fields['tipo']}'.replaceAll('_', ' ');
        return AgendaActivity(
          id: created['id'] as int,
          prospectId: fields['prospecto_id'] as int?,
          type: type,
          medium: fields['medio'] as String?,
          title: type.toUpperCase(),
          prospect: fields['prospecto_id'] == null ? 'Actividad personal' : 'Prospecto',
          description: fields['descripcion'] as String? ?? 'Sin descripción',
          date: businessTimeFromInstant(instant),
          status: AgendaStatus.pending,
          location: fields['ubicacion'] as String? ?? 'Sin ubicación',
        );
      }
    } on TimeoutException {
      throw const AgendaIndeterminateException(
        'El servidor tardó demasiado. Actualiza la agenda antes de volver a guardar para comprobar si se creó.',
      );
    } on http.ClientException {
      throw const AgendaRecoverableException(
        'No se pudo conectar. La actividad se sincronizará después.',
      );
    } on FormatException {
      throw const AgendaIndeterminateException(
        'No se pudo confirmar la creación. Actualiza la agenda antes de volver a guardar.',
      );
    }
  }

  Future<void> update(
    int id,
    Map<String, dynamic> fields, {
    String? operationKey,
  }) async {
    final token = _auth.token;
    if (token == null) throw const AgendaException('Inicia sesión nuevamente.');
    try {
      final response = await _client
          .put(
            Uri.parse('${_auth.baseUrl}/api/v1/activities/$id'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Idempotency-Key': ?operationKey,
            },
            body: jsonEncode(fields),
          )
          .timeout(const Duration(seconds: 60));
      final data = _decode(response);
      await _ensureSession(response, data);
      if (response.statusCode >= 500) {
        throw const AgendaRecoverableException(
          'El servidor no pudo editar la actividad. Se reintentará.',
        );
      }
      if (response.statusCode != 200 ||
          data is! Map ||
          data['success'] != true) {
        throw AgendaBusinessException(
          data is Map && data['message'] is String
              ? data['message'] as String
              : 'No se pudo editar la actividad.',
        );
      }
    } on TimeoutException {
      throw const AgendaIndeterminateException(
        'El servidor tardó demasiado. Actualiza la agenda para comprobar si se guardaron los cambios.',
      );
    } on http.ClientException {
      throw const AgendaRecoverableException(
        'No se pudo conectar. Los cambios se sincronizarán después.',
      );
    } on FormatException {
      throw const AgendaIndeterminateException(
        'No se pudo confirmar la edición. Actualiza la agenda.',
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
      final decoded = _decode(response);
      await _ensureSession(response, decoded);
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
      final data = decoded;
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
      final activities = (data['data'] as List)
          .map(
            (row) => fromJson(
              Map<String, dynamic>.from(row as Map),
              now: now,
              baseUrl: _auth.baseUrl,
            ),
          )
          .toList();
      await NotificationService.instance.syncActivities(
        activities,
        userId: _auth.userId,
        developmentId: _auth.developmentId,
      );
      return activities;
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

  static dynamic _decode(http.Response response) =>
      jsonDecode(utf8.decode(response.bodyBytes));

  Future<void> _ensureSession(http.Response response, dynamic data) async {
    final sessionFailure =
        data is Map &&
        (data['status'] == 'error' || data['code'] == 'TOKEN_EXPIRED');
    if (!sessionFailure) return;
    await _auth.expireSession();
    throw const AgendaSessionException(
      'Tu sesión expiró. Vuelve a iniciar sesión.',
    );
  }

  static AgendaActivity fromJson(
    Map<String, dynamic> row, {
    required DateTime now,
    String? baseUrl,
  }) {
    final rawDate = DateTime.tryParse('${row['programada_at']}');
    final date = rawDate == null ? null : businessTimeFromInstant(rawDate);
    final id = int.tryParse('${row['id']}');
    if (date == null || id == null) throw const FormatException();
    final serverNow = DateTime.tryParse('${row['server_now']}');
    final statusReference = serverNow == null
        ? (now.isUtc ? businessTimeFromInstant(now) : now)
        : businessTimeFromInstant(serverNow);
    final status = switch (row['estado']) {
      'completada' => AgendaStatus.completed,
      'cancelada' => AgendaStatus.cancelled,
      'pendiente' =>
        date.isBefore(statusReference)
            ? AgendaStatus.overdue
            : AgendaStatus.pending,
      _ => throw const FormatException(),
    };
    final type = (row['tipo'] as String).replaceAll('_', ' ');
    final rawReminder = DateTime.tryParse('${row['recordatorio_at']}');
    final reminder = rawReminder == null
        ? null
        : businessTimeFromInstant(rawReminder);
    final rawCompleted = DateTime.tryParse('${row['completada_at']}');
    final completedAt = rawCompleted == null
        ? null
        : businessTimeFromInstant(rawCompleted);
    final created = DateTime.tryParse('${row['created_at']}');
    final rawAvatar = row['prospecto_avatar_url'] ?? row['avatar_url'];
    final avatar = rawAvatar is String && rawAvatar.trim().isNotEmpty
        ? (baseUrl == null
              ? Uri.tryParse(rawAvatar)
              : Uri.parse('$baseUrl/').resolve(rawAvatar))
        : null;
    return AgendaActivity(
      prospectAvatarUrl: avatar?.scheme == 'https' ? avatar.toString() : null,
      deleteUntil:
          (row['puede_eliminar'] == 1 || row['puede_eliminar'] == true) &&
              created != null &&
              serverNow != null
          ? now.add(
              created.add(const Duration(minutes: 5)).difference(serverNow),
            )
          : null,
      completedAt: completedAt,
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
