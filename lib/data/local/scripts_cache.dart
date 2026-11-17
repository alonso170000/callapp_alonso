import 'dart:convert';

import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/presentation/models/guion_models.dart';

class ScriptsCache {
  ScriptsCache({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;
  final AppDatabase _database;
  String key(LocalScope scope) =>
      'scripts:v1:${scope.userId}:${scope.developmentId}';
  Future<GuionesBundle?> read(LocalScope scope) async {
    try {
      final raw = await _database.readMetadata(key(scope));
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

  Future<void> write(LocalScope scope, GuionesBundle bundle) async {
    try {
      await _database.writeMetadata(
        key(scope),
        jsonEncode({
          ...bundle.toJson(),
          'fetched_at_ms':
              (bundle.fetchedAt ?? DateTime.now()).millisecondsSinceEpoch,
        }),
      );
      await _database.touchMetadata(scope, AppDatabase.scriptsResource);
    } on Object {
      /* La caché nunca bloquea la app. */
    }
  }
}
