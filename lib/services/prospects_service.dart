import 'dart:async';
import 'dart:convert';

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
    final avatar = rawAvatar is String && rawAvatar.isNotEmpty
        ? Uri.parse('${_auth.baseUrl}/').resolve(rawAvatar)
        : null;
    return ProspectRecord(
      id: id,
      avatarUrl: avatar != null && avatar.scheme == 'https'
          ? avatar.toString()
          : null,
      name: row['nombre'] as String,
      phone: '',
      email: '',
      status: row['estatus'] as String? ?? 'Sin estatus',
      temperature: 'Sin calificar',
      avatarColor: AppColors.homeDeepTeal,
      statusColor: AppColors.homeWarmText,
      city: row['ciudad'] as String? ?? 'Sin registro de ciudad',
      origin: row['canal'] as String? ?? 'Sin canal',
      assignedAt: DateTime.tryParse('${row['fecha_asignacion']}')?.toLocal(),
      daysSinceContact: 0,
      comments: 'Información de contacto y seguimiento no disponible.',
    );
  }

  void dispose() => _client.close();
}
