import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:callerapp_frontend/services/notification_service.dart';

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
  int? _userId;
  String? get email => _email;
  String? get phone => _phone;
  int? get userId => _userId;
  int? get developmentId => _int(activeDevelopment?['id']);
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
      // Report HTTP failures even when a proxy returns HTML rather than JSON.
      final httpError = switch (response.statusCode) {
        404 => 'No existe POST /api/v1/auth/login en este servidor. Revisa API_BASE_URL y el despliegue.',
        408 => 'El servidor agotó el tiempo para procesar el login.',
        429 => 'Se alcanzó el límite de intentos de inicio de sesión. Espera antes de volver a intentar.',
        500 => 'El backend falló al procesar el login. Consulta los logs del servidor para conocer la causa.',
        502 =>
          'La puerta de enlace no recibió una respuesta válida del backend.',
        503 => 'El servicio de autenticación no está disponible temporalmente.',
        504 => 'La puerta de enlace agotó el tiempo esperando al backend.',
        >= 500 => 'El servidor falló al procesar el inicio de sesión.',
        _ => null,
      };
      if (httpError != null) {
        throw AuthException('[HTTP ${response.statusCode}] $httpError');
      }
      dynamic data;
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw AuthException(
          response.statusCode == 401
              ? '[HTTP 401] Usuario o contraseña incorrectos.'
              : response.statusCode == 403
              ? '[HTTP 403] El servidor denegó el acceso a esta cuenta.'
              : '[AUTH_INVALID_RESPONSE · HTTP ${response.statusCode}] El servidor devolvió una respuesta que no es JSON válido.',
        );
      }
      if (response.statusCode != 200) {
        throw AuthException(
          data is Map && data['message'] is String
              ? data['message'] as String
              : switch (response.statusCode) {
                  400 => '[HTTP 400] El servidor rechazó los datos enviados. Revisa usuario y contraseña.',
                  401 => '[HTTP 401] Usuario o contraseña incorrectos.',
                  403 =>
                    '[HTTP 403] El servidor denegó el acceso a esta cuenta.',
                  _ =>
                    '[HTTP ${response.statusCode}] El servidor rechazó el inicio de sesión.',
                },
        );
      }
      if (data is! Map<String, dynamic> ||
          data['status'] != 'success' ||
          data['token'] is! String ||
          (data['token'] as String).isEmpty) {
        throw const AuthException(
          '[AUTH_INVALID_SESSION] El servidor respondió HTTP 200, pero no incluyó una sesión válida.',
        );
      }
      _token = data['token'] as String;
      // El backend incluye nombre_completo en el JWT. Esta lectura sirve
      // para presentación; la autorización sigue validándose en el servidor.
      final user = data['usuario'];
      _userId = user is Map
          ? _int(user['id'])
          : _readIntClaim(_token!, 'usuario_id');
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
        '[AUTH_TIMEOUT] No se completó la respuesta de POST /api/v1/auth/login en 60 segundos. Comprueba la conexión y los logs del backend; la app no recibió un resultado del login.',
      );
    } on http.ClientException catch (error) {
      final detail = error.message.toLowerCase();
      if (detail.contains('failed host lookup') ||
          detail.contains('name resolution') ||
          detail.contains('getaddrinfo')) {
        throw const AuthException(
          '[AUTH_DNS] No se pudo resolver el dominio del backend. Revisa tu conexión y API_BASE_URL.',
        );
      }
      if (detail.contains('certificate') ||
          detail.contains('handshake') ||
          detail.contains('ssl') ||
          detail.contains('tls')) {
        throw const AuthException(
          '[AUTH_TLS] Falló la conexión HTTPS con el backend. Revisa el certificado y la fecha del dispositivo.',
        );
      }
      if (detail.contains('connection refused')) {
        throw const AuthException(
          '[AUTH_CONNECTION_REFUSED] El servidor rechazó la conexión. Comprueba que el servicio esté disponible.',
        );
      }
      throw const AuthException(
        '[AUTH_CONNECTION] No se pudo completar la conexión con el backend. Revisa la red y la disponibilidad del servicio.',
      );
    }
  }

  void logout() {
    unawaited(NotificationService.instance.clearActivityReminders());
    _token = null;
    _userName = null;
    _email = null;
    _phone = null;
    _userId = null;
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

  static int? _readIntClaim(String token, String claim) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload is Map ? _int(payload[claim]) : null;
    } on FormatException {
      return null;
    }
  }

  static int? _int(dynamic value) => switch (value) {
    final int number => number,
    final String text => int.tryParse(text),
    _ => null,
  };

  static String? _text(dynamic value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}
