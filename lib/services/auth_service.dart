import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class AuthService extends ChangeNotifier {
  AuthService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'https://api-crm-mx9l.onrender.com',
          );

  static final instance = AuthService();
  final http.Client _client;
  final String _baseUrl;
  String? _token;
  String? _userName;
  String? _email;
  String? _phone;
  String? get email => _email;
  String? get phone => _phone;
  String get userName => _userName ?? 'Usuario';
  Map<String, dynamic>? activeDevelopment;
  String? get token => _token;
  String get baseUrl => _baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  bool get isAuthenticated => _token != null;

  Future<void> login(String username, String password) async {
    final base = Uri.tryParse(_baseUrl.trim());
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        base.userInfo.isNotEmpty) {
      throw const AuthException(
        'Configura API_BASE_URL con la URL HTTPS de tu backend en Render.',
      );
    }
    final url = Uri.parse(
      '${base.toString().replaceFirst(RegExp(r'/+$'), '')}/api/v1/auth/login',
    );
    try {
      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 60));
      dynamic data;
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw const AuthException(
          'El servidor no devolvió una respuesta válida. Revisa la URL del backend.',
        );
      }
      if (response.statusCode != 200) {
        throw AuthException(
          response.statusCode >= 500
              ? 'El servidor no pudo iniciar sesión. Revisa los registros de Render y la conexión con Aiven.'
              : data is Map && data['message'] is String
              ? data['message'] as String
              : 'No se pudo iniciar sesión (${response.statusCode}).',
        );
      }
      if (data is! Map<String, dynamic> ||
          data['status'] != 'success' ||
          data['token'] is! String ||
          (data['token'] as String).isEmpty) {
        throw const AuthException(
          'La respuesta del servidor no contiene una sesión válida.',
        );
      }
      _token = data['token'] as String;
      // El backend incluye nombre_completo en el JWT. Esta lectura sirve
      // para presentación; la autorización sigue validándose en el servidor.
      final user = data['usuario'];
      _userName = user is Map ? _text(user['nombre_completo']) : null;
      _userName ??= _readUserName(_token!) ?? username.trim();
      _email = user is Map ? _text(user['email']) : null;
      _phone = user is Map ? _text(user['telefono']) : null;
      activeDevelopment = data['desarrollo_activo'] is Map<String, dynamic>
          ? data['desarrollo_activo'] as Map<String, dynamic>
          : null;
      notifyListeners();
    } on TimeoutException {
      throw const AuthException(
        'El servidor tardó demasiado en responder. Render puede estar iniciando; intenta nuevamente.',
      );
    } on http.ClientException {
      throw const AuthException(
        'No se pudo conectar con el servidor. Revisa tu conexión y la URL de Render.',
      );
    }
  }

  void logout() {
    _token = null;
    _userName = null;
    _email = null;
    _phone = null;
    activeDevelopment = null;
    notifyListeners();
  }

  static String? _readUserName(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return null;
      final name = payload['nombre_completo'];
      if (name is String && name.trim().isNotEmpty) return name.trim();
    } on FormatException {
      return null;
    }
    return null;
  }

  static String? _text(dynamic value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}
