import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
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

  Future<void> create(Map<String, dynamic> fields) async {
    final data = await _request('leads', body: fields);
    if (data['data'] is! Map || data['data']['id'] is! int) {
      throw const ProspectsException(
        'No se pudo confirmar la creación. Actualiza la lista antes de volver a guardar.',
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
      statusColor: switch (status.toLowerCase()) {
        'cotización' => const Color(0xFFB69BF5),
        'nuevo' => AppColors.homeBlueSection,
        'negociación' => AppColors.homeOrangeSection,
        'venta realizada' => AppColors.homeGreenCard,
        _ => AppColors.homeWarmText,
      },
      city: row['ciudad'] as String? ?? 'Sin registro de ciudad',
      origin: row['canal'] as String? ?? 'Sin canal',
      assignedAt: DateTime.tryParse('${row['fecha_asignacion']}')?.toLocal(),
      lastCallAt: lastCall,
      nextContact: DateTime.tryParse('${row['proximo_contacto_at']}')
          ?.toLocal(),
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
