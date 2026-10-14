import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

enum AppAppearance {
  light('claro', 'Claro', ThemeMode.light),
  dark('oscuro', 'Oscuro', ThemeMode.dark),
  system('sistema', 'Sistema', ThemeMode.system);

  const AppAppearance(this.value, this.label, this.mode);
  final String value, label;
  final ThemeMode mode;
}

class AppearanceException implements Exception {
  const AppearanceException(this.message);
  final String message;
}

class AppearanceController extends ChangeNotifier {
  AppearanceController({AuthService? auth, http.Client? client})
    : _auth = auth ?? AuthService.instance,
      _client = client ?? http.Client() {
    _auth.addListener(_sessionChanged);
    _sessionChanged();
  }
  static final instance = AppearanceController();
  final AuthService _auth;
  final http.Client _client;
  AppAppearance appearance = AppAppearance.system;
  bool loading = false, saving = false;
  String? error;
  String? _token;
  int _revision = 0;
  void _sessionChanged() {
    if (_token == _auth.token) return;
    _token = _auth.token;
    ++_revision;
    appearance = AppAppearance.system;
    error = null;
    loading = false;
    saving = false;
    notifyListeners();
    if (_token != null) reload();
  }

  Future<AppAppearance> _request(
    String token, {
    AppAppearance? selected,
  }) async {
    try {
      final uri = Uri.parse('${_auth.baseUrl}/api/v1/preferences');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final response =
          await (selected == null
                  ? _client.get(uri, headers: headers)
                  : _client.put(
                      uri,
                      headers: headers,
                      body: jsonEncode({'tema': selected.value}),
                    ))
              .timeout(const Duration(seconds: 30));
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AppearanceException(
          'Tu sesión expiró. Vuelve a iniciar sesión.',
        );
      }
      if (response.statusCode == 404) {
        throw const AppearanceException(
          'Actualiza el backend para habilitar las preferencias de apariencia.',
        );
      }
      if (response.statusCode != 200) {
        throw const AppearanceException(
          'No se pudo guardar o consultar la apariencia. Intenta nuevamente.',
        );
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map || data['success'] != true || data['data'] is! Map) {
        throw const FormatException();
      }
      return AppAppearance.values.firstWhere(
        (value) => value.value == data['data']['tema'],
      );
    } on TimeoutException {
      throw const AppearanceException(
        'El servidor tardó demasiado. Reintenta para comprobar la preferencia guardada.',
      );
    } on http.ClientException {
      throw const AppearanceException(
        'No se pudo conectar para guardar la apariencia.',
      );
    } on FormatException {
      throw const AppearanceException(
        'El servidor devolvió una apariencia inválida.',
      );
    } on StateError {
      throw const AppearanceException(
        'El servidor devolvió una apariencia inválida.',
      );
    }
  }

  Future<void> reload() async {
    final token = _token;
    if (token == null || saving) return;
    final revision = ++_revision;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final value = await _request(token);
      if (revision == _revision) appearance = value;
    } on AppearanceException catch (e) {
      if (revision == _revision) error = e.message;
    } finally {
      if (revision == _revision) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> select(AppAppearance value) async {
    final token = _token;
    if (token == null) {
      throw const AppearanceException(
        'Inicia sesión para guardar tu apariencia.',
      );
    }
    if (saving) return;
    final revision = ++_revision;
    final previous = appearance;
    appearance = value;
    saving = true;
    loading = false;
    error = null;
    notifyListeners();
    try {
      final saved = await _request(token, selected: value);
      if (revision == _revision) appearance = saved;
    } on AppearanceException catch (e) {
      if (revision == _revision) {
        appearance = previous;
        error = e.message;
        rethrow;
      }
    } finally {
      if (revision == _revision) {
        saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    ++_revision;
    _auth.removeListener(_sessionChanged);
    _client.close();
    super.dispose();
  }
}
