import 'dart:convert';

import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';

/// Caché del discovery de un prospecto.
///
/// El discovery no vive en la caché de prospectos: se guarda por secciones y se
/// consulta aparte. Para que el módulo siga funcionando sin conexión se guarda
/// el JSON recibido del servidor y se fusionan encima los campos que el usuario
/// acaba de guardar, incluso si la operación todavía está pendiente.
class DiscoveryCache {
  DiscoveryCache({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  // La clave termina en `:<userId>:<developmentId>` para que la limpieza de 30
  // días del ámbito la alcance junto al resto de sus datos.
  String _key(LocalScope scope, int prospectId) =>
      'discovery:$prospectId:${scope.userId}:${scope.developmentId}';

  Future<Map<String, dynamic>?> read(LocalScope scope, int prospectId) async {
    try {
      final raw = await _database.readMetadata(_key(scope, prospectId));
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } on Object {
      return null;
    }
  }

  Future<void> write(
    LocalScope scope,
    int prospectId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _database.writeMetadata(_key(scope, prospectId), jsonEncode(data));
    } on Object {
      // Sin SQLite el discovery sigue funcionando contra la red.
    }
  }

  /// Fusiona [fields] sobre lo ya cacheado. Útil al guardar una sección.
  Future<void> merge(
    LocalScope scope,
    int prospectId,
    Map<String, dynamic> fields,
  ) async {
    if (fields.isEmpty) return;
    try {
      final current = await read(scope, prospectId) ?? <String, dynamic>{};
      await write(scope, prospectId, {...current, ...fields});
    } on Object {
      // La caché es una optimización y nunca debe bloquear el guardado.
    }
  }
}
