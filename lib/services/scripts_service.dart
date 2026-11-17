import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:callerapp_frontend/presentation/models/guion_models.dart';
import 'package:callerapp_frontend/services/auth_service.dart';

class ScriptsException implements Exception {
  const ScriptsException(this.message);
  final String message;
}

class ScriptsSessionException extends ScriptsException {
  const ScriptsSessionException(super.message);
}

class ScriptsOfflineException extends ScriptsException {
  const ScriptsOfflineException(super.message);
}

class ScriptsRecoverableException extends ScriptsException {
  const ScriptsRecoverableException(super.message);
}

class ScriptsService {
  ScriptsService({http.Client? client, AuthService? auth})
    : _client = client ?? http.Client(),
      _auth = auth ?? AuthService.instance;
  final http.Client _client;
  final AuthService _auth;
  int? get userId => _auth.userId;
  int? get developmentId => _auth.developmentId;

  Future<GuionesBundle> fetch({String? tipoProspecto}) async {
    final token = _auth.token;
    if (token == null) {
      throw const ScriptsSessionException('Inicia sesión nuevamente.');
    }
    final query = tipoProspecto == null || tipoProspecto.isEmpty
        ? ''
        : '?tipo_prospecto=${Uri.encodeQueryComponent(tipoProspecto)}';
    try {
      final response = await _client
          .get(
            Uri.parse('${_auth.baseUrl}/api/v1/guiones$query'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 60));
      dynamic decoded;
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw const ScriptsException('La respuesta de guiones no es válida.');
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        await _auth.expireSession();
        throw const ScriptsSessionException(
          'Tu sesión expiró. Vuelve a iniciar sesión.',
        );
      }
      if (response.statusCode >= 500) {
        throw const ScriptsRecoverableException(
          'El servidor no pudo cargar los guiones. Intenta nuevamente.',
        );
      }
      if (decoded is! Map ||
          decoded['success'] != true ||
          decoded['data'] is! Map) {
        throw ScriptsException(
          decoded is Map && decoded['message'] is String
              ? decoded['message'] as String
              : 'No se pudieron cargar los guiones.',
        );
      }
      try {
        return GuionesBundle.fromJson(
          Map<String, dynamic>.from(decoded['data'] as Map),
          fetchedAt: DateTime.now(),
        );
      } on FormatException {
        throw const ScriptsException('El guion recibido no es válido.');
      }
    } on TimeoutException {
      throw const ScriptsOfflineException(
        'No se pudo conectar para cargar los guiones.',
      );
    } on http.ClientException {
      throw const ScriptsOfflineException(
        'No hay conexión con el servidor de guiones.',
      );
    }
  }

  void dispose() => _client.close();
}
