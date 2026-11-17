import 'dart:convert';

import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/presentation/models/guion_models.dart';
import 'package:callerapp_frontend/services/business_clock.dart';

class ScriptsCache {
  ScriptsCache({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;
  final AppDatabase _database;
  String key(LocalScope scope, String? tipoProspecto) =>
      'scripts:v2:${scope.userId}:${scope.developmentId}:${tipoProspecto ?? 'regular'}';
  Future<GuionesBundle?> read(LocalScope scope, {String? tipoProspecto}) async {
    try {
      final raw = await _database.readMetadata(key(scope, tipoProspecto));
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return GuionesBundle.fromJson(
        Map<String, dynamic>.from(decoded),
        fetchedAt: decoded['fetched_at_ms'] is int
            ? DateTime.fromMillisecondsSinceEpoch(
                decoded['fetched_at_ms'] as int,
              )
            : null,
      );
    } on Object {
      return null;
    }
  }

  Future<void> write(
    LocalScope scope,
    GuionesBundle bundle, {
    String? tipoProspecto,
  }) async {
    try {
      await _database.writeMetadata(
        key(scope, tipoProspecto),
        jsonEncode({
          ...bundle.toJson(),
          'fetched_at_ms':
              (bundle.fetchedAt ?? businessNow()).millisecondsSinceEpoch,
        }),
      );
      await _database.touchMetadata(scope, AppDatabase.scriptsResource);
    } on Object {
      /* La caché nunca bloquea la app. */
    }
  }
}
