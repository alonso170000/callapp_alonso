import 'package:callerapp_frontend/resources/colors/prospect_tag_colors.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_history_models.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class ProspectsException implements Exception {
  const ProspectsException(this.message);
  final String message;
}

class ProspectsService {
  ProspectsService({http.Client? client, AuthService? auth})
    : _client = client ?? http.Client(),
      _auth = auth ?? AuthService.instance;
  final http.Client _client;
  final AuthService _auth;
  Map<String, dynamic>? get activeDevelopment => _auth.activeDevelopment;

  Future<Map<String, dynamic>> _request(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = _auth.token;
    if (token == null) {
      throw const ProspectsException('Inicia sesión nuevamente.');
    }
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    try {
      final uri = Uri.parse('${_auth.baseUrl}/api/v1/$path');
      final response =
          await (body == null
                  ? _client.get(uri, headers: headers)
                  : _client.post(uri, headers: headers, body: jsonEncode(body)))
              .timeout(const Duration(seconds: 60));
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const ProspectsException(
          'Tu sesión expiró. Vuelve a iniciar sesión.',
        );
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) throw const FormatException();
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data['success'] != true) {
        throw ProspectsException(
          response.statusCode < 500 && data['message'] is String
              ? data['message'] as String
              : 'No se pudo completar la solicitud. Intenta nuevamente.',
        );
      }
      return data;
    } on TimeoutException {
      throw const ProspectsException(
        'El servidor tardó demasiado. Actualiza la lista antes de volver a guardar para comprobar si se creó.',
      );
    } on http.ClientException {
      throw const ProspectsException(
        'No se pudo conectar. Revisa tu conexión.',
      );
    } on FormatException {
      throw const ProspectsException(
        'El servidor devolvió una respuesta inválida.',
      );
    }
  }

  Future<List<ProspectHistoryComment>> contactHistory(int id) async {
    final data = await _request('leads/$id/contact-history');
    try {
      return (data['data'] as List).map((raw) {
        final row = raw as Map;
        return ProspectHistoryComment(
          comment: row['nota'] as String? ?? 'Sin comentario',
          createdAt: DateTime.parse(row['fecha_hora'] as String).toLocal(),
          medium: row['medio'] as String,
          results: [
            if (row['hubo_exito'] == true || row['hubo_exito'] == 1)
              ProspectContactResult.answered
            else if (row['hubo_exito'] == false || row['hubo_exito'] == 0)
              ProspectContactResult.unanswered,
            if (row['siguiente_actividad_id'] != null)
              ProspectContactResult.appointment,
          ],
        );
      }).toList();
    } catch (_) {
      throw const ProspectsException('El historial recibido no es válido.');
    }
  }

  Future<void> createFollowUp(
    int prospectId,
    Map<String, dynamic> fields,
  ) async {
    final data = await _request('leads/$prospectId/follow-ups', body: fields);
    if (data['data'] is! Map || data['data']['contact_id'] is! int) {
      throw const ProspectsException(
        'No se pudo confirmar el seguimiento. Actualiza el historial antes de volver a guardar.',
      );
    }
  }

  Future<Map<String, dynamic>?> discovery(int prospectId) async {
    final data = await _request('leads/$prospectId/discovery');
    final discovery = data['data'];
    if (discovery == null) return null;
    if (discovery is! Map) {
      throw const ProspectsException('El discovery recibido no es válido.');
    }
    return Map<String, dynamic>.from(discovery);
  }

  Future<void> saveDiscoverySection(
    int prospectId,
    Map<String, dynamic> fields,
  ) async {
    final data = await _request('leads/$prospectId/discovery', body: fields);
    if (data['data'] is! Map || data['data']['id'] is! int) {
      throw const ProspectsException(
        'No se pudo confirmar el guardado del discovery.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> availableClosers() async {
    final data = await _request('agents/closers');
    final rows = data['data'];
    if (rows is! List ||
        rows.any(
          (row) =>
              row is! Map ||
              row['id'] is! int ||
              row['nombre_completo'] is! String,
        )) {
      throw const ProspectsException(
        'El listado de cerradores recibido no es válido.',
      );
    }
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> catalog(String name) async {
    final data = await _request('catalogs/$name');
    final rows = data['data'];
    if (rows is! List ||
        rows.any(
          (row) => row is! Map || row['id'] is! int || row['nombre'] is! String,
        )) {
      throw const ProspectsException('El catálogo recibido no es válido.');
    }
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> availableDevelopments() async {
    final data = await _request('catalogs/desarrollos');
    final rows = data['data'];
    if (rows is! List ||
        rows.any(
          (row) => row is! Map || row['id'] is! int || row['nombre'] is! String,
        )) {
      throw const ProspectsException(
        'El listado de desarrollos recibido no es válido.',
      );
    }
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> availableLots([int? developmentId]) async {
    final query = developmentId == null
        ? ''
        : '?desarrollo_id=${Uri.encodeQueryComponent('$developmentId')}';
    final data = await _request('catalogs/lotes$query');
    final rows = data['data'];
    if (rows is! List ||
        rows.any(
          (row) =>
              row is! Map || row['id'] is! int || row['numero_lote'] is! int,
        )) {
      throw const ProspectsException('El catálogo de lotes no es válido.');
    }
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<void> create(Map<String, dynamic> fields) async {
    final data = await _request('leads', body: fields);
    if (data['data'] is! Map || data['data']['id'] is! int) {
      throw const ProspectsException(
        'No se pudo confirmar la creación. Actualiza la lista antes de volver a guardar.',
      );
    }
  }

  Future<void> update(int prospectId, Map<String, dynamic> fields) async {
    final token = _auth.token;
    if (token == null) {
      throw const ProspectsException('Inicia sesión nuevamente.');
    }
    try {
      final response = await _client
          .put(
            Uri.parse('${_auth.baseUrl}/api/v1/leads/$prospectId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(fields),
          )
          .timeout(const Duration(seconds: 60));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data is! Map ||
          data['success'] != true) {
        throw ProspectsException(
          data is Map && data['message'] is String
              ? data['message'] as String
              : 'No se pudieron actualizar los datos del prospecto.',
        );
      }
    } on TimeoutException {
      throw const ProspectsException('El servidor tardó demasiado en guardar.');
    } on http.ClientException {
      throw const ProspectsException('No se pudo conectar con el servidor.');
    } on FormatException {
      throw const ProspectsException(
        'El servidor devolvió una respuesta inválida.',
      );
    }
  }

  Future<List<ProspectRecord>> fetch() async {
    final token = _auth.token;
    if (token == null) {
      throw const ProspectsException('Inicia sesión para ver tus prospectos.');
    }
    try {
      final response = await _client
          .get(
            Uri.parse('${_auth.baseUrl}/api/v1/leads'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const ProspectsException(
          'Tu sesión expiró. Vuelve a iniciar sesión.',
        );
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200 ||
          data is! Map ||
          data['success'] != true ||
          data['data'] is! List) {
        throw ProspectsException(
          response.statusCode == 400 && data is Map && data['message'] is String
              ? data['message'] as String
              : 'No se pudieron cargar los prospectos. Intenta nuevamente.',
        );
      }
      return (data['data'] as List)
          .map((row) => _record(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on TimeoutException {
      throw const ProspectsException(
        'El servidor tardó demasiado. Intenta nuevamente.',
      );
    } on http.ClientException {
      throw const ProspectsException(
        'No se pudo conectar. Revisa tu conexión.',
      );
    } on FormatException {
      throw const ProspectsException(
        'El servidor devolvió una respuesta inválida.',
      );
    } on TypeError {
      throw const ProspectsException(
        'El servidor devolvió datos de prospectos inválidos.',
      );
    }
  }

  ProspectRecord _record(Map<String, dynamic> row) {
    final id = int.tryParse('${row['id']}');
    if (id == null || row['nombre'] is! String) throw const FormatException();
    final rawAvatar = row['avatar_url'];
    final lastCall = DateTime.tryParse('${row['ultima_llamada_at']}')
        ?.toLocal();
    final priority = row['prioridad']?.toString().toLowerCase();
    final status = row['estatus'] as String? ?? 'Sin estatus';
    final avatar = rawAvatar is String && rawAvatar.isNotEmpty
        ? Uri.parse('${_auth.baseUrl}/').resolve(rawAvatar)
        : null;
    return ProspectRecord(
      id: id,
      avatarUrl: avatar != null && avatar.scheme == 'https'
          ? avatar.toString()
          : null,
      name: row['nombre'] as String,
      phone: row['telefono_normalizado']?.toString().trim().isNotEmpty == true
          ? row['telefono_normalizado'].toString()
          : (row['telefono'] ?? '').toString(),
      email: row['correo'] as String? ?? '',
      status: status,
      temperature: switch (priority) {
        'caliente' => 'Caliente',
        'tibio' => 'Tibio',
        'frio' => 'Frío',
        _ => 'Sin calificar',
      },
      avatarColor: AppColors.homeDeepTeal,
      statusColor: ProspectTagColors.status(status),
      city: row['ciudad'] as String? ?? 'Sin registro de ciudad',
      origin: row['canal'] as String? ?? 'Sin canal',
      channelId: int.tryParse('${row['canal_id']}'),
      statusId: int.tryParse('${row['estatus_id']}'),
      campaignId: int.tryParse('${row['campania_id']}'),
      company: row['nombre_compania'] as String? ?? 'Sin registro de Empresa',
      occupation: row['ocupacion'] as String? ?? 'Sin registro de ocupación',
      interestDevelopmentId: int.tryParse('${row['desarrollo_interes_id']}'),
      interestDevelopment:
          row['desarrollo_interes'] as String? ?? 'Sin desarrollo seleccionado',
      interestLotId: int.tryParse('${row['terreno_interes_id']}'),
      interestLot: row['lote_interes'] == null
          ? 'Sin lote seleccionado'
          : 'Lote ${row['lote_interes']}',
      qualification: row['calificacion']?.toString().split(',') ?? const [],
      assignedAt: switch (DateTime.tryParse('${row['fecha_asignacion']}')) {
        final value? => businessTimeFromInstant(value),
        null => null,
      },
      lastCallAt: lastCall,
      lastContactResult:
          row['ultimo_contacto_resultado'] as String? ??
          (lastCall == null ? 'Sin contacto' : 'Sin información'),
      nextContact: switch (DateTime.tryParse('${row['proximo_contacto_at']}')) {
        final value? => businessTimeFromInstant(value),
        null => null,
      },
      daysSinceContact: lastCall == null
          ? 0
          : DateUtils.dateOnly(DateTime.now())
                .difference(DateUtils.dateOnly(lastCall))
                .inDays
                .clamp(0, 100000),
      comments: row['comentario'] as String? ?? 'Sin comentarios registrados.',
    );
  }

  void dispose() => _client.close();
}
