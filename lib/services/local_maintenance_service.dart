import 'dart:async';

import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';

/// Mantenimiento de los datos locales: expira cachés viejas y avisos leídos.
class LocalMaintenanceService {
  LocalMaintenanceService({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  static final instance = LocalMaintenanceService();

  /// La caché de prospectos y actividades se conserva 30 días.
  static const cacheRetention = Duration(days: 30);

  /// Los avisos leídos se conservan 7 días, igual que la bandeja.
  static const notificationRetention = Duration(days: 7);

  static const _interval = Duration(hours: 24);

  final AppDatabase _database;

  /// Ejecuta la limpieza como máximo una vez al día.
  Future<void> runIfDue() async {
    try {
      final lastRun = await _database.readMetadataInt(
        AppDatabase.maintenanceKey,
      );
      final now = DateTime.now();
      if (lastRun != null) {
        final elapsed = now.difference(
          DateTime.fromMillisecondsSinceEpoch(lastRun),
        );
        if (elapsed < _interval) return;
      }
      await run(now: now);
    } catch (_) {
      // La limpieza nunca debe impedir que la app arranque.
    }
  }

  /// Elimina ámbitos vencidos y avisos leídos antiguos.
  Future<int> run({DateTime? now}) async {
    final reference = now ?? DateTime.now();
    final removed = await _database.purgeExpiredScopes(
      reference.subtract(cacheRetention),
    );
    await _database.purgeReadNotificationsBefore(
      reference.subtract(notificationRetention),
    );
    await _database.writeMetadata(
      AppDatabase.maintenanceKey,
      '${reference.millisecondsSinceEpoch}',
    );
    return removed;
  }

  Future<void> clearScope(LocalScope scope) => _database.clearScope(scope);

  Future<void> clearAll() => _database.clearAll();
}
