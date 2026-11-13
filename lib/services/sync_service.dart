import 'dart:async';
import 'dart:convert';

import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;

class SyncException implements Exception {
  const SyncException(this.message);
  final String message;
}

class SyncService {
  SyncService({http.Client? client, AuthService? auth})
    : _client = client ?? http.Client(),
      _auth = auth ?? AuthService.instance;

  final http.Client _client;
  final AuthService _auth;

  Future<String> fetchVersion() async {
    final token = _auth.token;
    if (token == null) {
      throw const SyncException('No hay una sesión activa.');
    }
    try {
      final response = await _client
          .get(
            Uri.parse('${_auth.baseUrl}/api/v1/sync/version'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 401 || response.statusCode == 403) {
        await _auth.expireSession();
        throw const SyncException('Tu sesión expiró. Vuelve a iniciar sesión.');
      }
      if (response.statusCode >= 500) {
        throw const SyncException('No se pudo comprobar la sincronización.');
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final data = body is Map ? body['data'] : null;
      final version = data is Map ? data['version'] : null;
      if (response.statusCode != 200 ||
          body is! Map ||
          body['success'] != true ||
          version is! String ||
          version.isEmpty) {
        throw const SyncException(
          'El servidor devolvió una respuesta inválida.',
        );
      }
      return version;
    } on TimeoutException {
      throw const SyncException('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw const SyncException('No se pudo conectar para comprobar cambios.');
    } on FormatException {
      throw const SyncException('El servidor devolvió una respuesta inválida.');
    }
  }

  void dispose() => _client.close();
}
