import 'dart:convert';

import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/services/business_clock.dart';

class CatalogCache {
  CatalogCache({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  /// Espera mínima entre intentos de precarga de catálogos.
  static const warmInterval = Duration(hours: 12);

  final AppDatabase _database;

  String _key(LocalScope scope, String name) =>
      'catalog:$name:${scope.userId}:${scope.developmentId}';

  String _warmKey(LocalScope scope) =>
      'catalog_warm:${scope.userId}:${scope.developmentId}';

  /// `true` si nunca se intentó precargar o si ya pasó el intervalo.
  Future<bool> isWarmDue(LocalScope scope) async {
    try {
      final raw = await _database.readMetadata(_warmKey(scope));
      final attemptedAt = int.tryParse(raw ?? '');
      if (attemptedAt == null) return true;
      return businessNow().difference(
            DateTime.fromMillisecondsSinceEpoch(attemptedAt),
          ) >=
          warmInterval;
    } on Object {
      return true;
    }
  }

  Future<void> markWarmAttempt(LocalScope scope) async {
    try {
      await _database.writeMetadata(
        _warmKey(scope),
        '${businessNow().millisecondsSinceEpoch}',
      );
    } on Object {
      // La precarga es oportunista y nunca debe bloquear la app.
    }
  }

  Future<List<Map<String, dynamic>>?> read(
    LocalScope scope,
    String name,
  ) async {
    try {
      final raw = await _database.readMetadata(_key(scope, name));
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } on Object {
      return null;
    }
  }

  Future<void> write(
    LocalScope scope,
    String name,
    List<Map<String, dynamic>> rows,
  ) async {
    try {
      await _database.writeMetadata(_key(scope, name), jsonEncode(rows));
    } on Object {
      // La ausencia de SQLite no debe impedir el uso remoto de catálogos.
    }
  }

  Future<void> remove(LocalScope scope, String name) async {
    try {
      final database = await _database.databaseOrNull;
      if (database == null) return;
      await database.delete(
        'app_metadata',
        where: 'key = ?',
        whereArgs: [_key(scope, name)],
      );
    } on Object {
      // La caché es una optimización y su limpieza nunca debe bloquear la app.
    }
  }
}
