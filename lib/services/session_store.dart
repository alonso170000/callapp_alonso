import 'dart:convert';

import 'package:callerapp_frontend/services/platform_support.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sesión serializada para sobrevivir al cierre de la app.
class StoredSession {
  const StoredSession({
    required this.token,
    this.userId,
    this.userName,
    this.email,
    this.phone,
    this.activeDevelopment,
  });

  final String token;
  final int? userId;
  final String? userName;
  final String? email;
  final String? phone;
  final Map<String, dynamic>? activeDevelopment;

  Map<String, Object?> toJson() => {
    'token': token,
    'user_id': userId,
    'user_name': userName,
    'email': email,
    'phone': phone,
    'active_development': activeDevelopment,
  };

  static StoredSession? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final token = raw['token'];
    if (token is! String || token.isEmpty) return null;
    final development = raw['active_development'];
    return StoredSession(
      token: token,
      userId: switch (raw['user_id']) {
        final int value => value,
        _ => int.tryParse('${raw['user_id']}'),
      },
      userName: raw['user_name'] is String ? raw['user_name'] as String : null,
      email: raw['email'] is String ? raw['email'] as String : null,
      phone: raw['phone'] is String ? raw['phone'] as String : null,
      activeDevelopment: development is Map
          ? Map<String, dynamic>.from(development)
          : null,
    );
  }
}

/// Almacén de la sesión. Las credenciales nunca se guardan en SQLite.
abstract interface class SessionStore {
  Future<StoredSession?> read();
  Future<void> write(StoredSession session);
  Future<void> clear();
}

/// Implementación para Android con Keystore. En otras plataformas no hace nada.
class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'callerapp.session.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<StoredSession?> read() async {
    if (!PlatformSupport.isAndroid) return null;
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      return StoredSession.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(StoredSession session) async {
    if (!PlatformSupport.isAndroid) return;
    try {
      await _storage.write(key: _key, value: jsonEncode(session.toJson()));
    } catch (_) {
      // Si el Keystore falla, la app sigue funcionando con la sesión en memoria.
    }
  }

  @override
  Future<void> clear() async {
    if (!PlatformSupport.isAndroid) return;
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // El siguiente login sobrescribe la sesión anterior.
    }
  }
}

/// Implementación en memoria para pruebas y plataformas sin soporte.
class MemorySessionStore implements SessionStore {
  StoredSession? session;

  @override
  Future<StoredSession?> read() async => session;

  @override
  Future<void> write(StoredSession value) async => session = value;

  @override
  Future<void> clear() async => session = null;
}
