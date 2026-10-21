import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/mappers/activity_cache_mapper.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:sqflite/sqflite.dart';

class ActivitiesCache {
  ActivitiesCache({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<AgendaActivity>> read(LocalScope scope) async {
    final database = await _database.databaseOrNull;
    if (database == null) return const [];
    final rows = await database.query(
      'cached_activities',
      where: 'user_id = ? AND development_id = ?',
      whereArgs: [scope.userId, scope.developmentId],
      orderBy: 'activity_at_ms ASC',
    );
    return rows.map(ActivityCacheMapper.fromRow).toList();
  }

  Future<void> replace(
    LocalScope scope,
    List<AgendaActivity> activities,
  ) async {
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await database.transaction((transaction) async {
      await transaction.delete(
        'cached_activities',
        where: 'user_id = ? AND development_id = ?',
        whereArgs: [scope.userId, scope.developmentId],
      );
      for (final activity in activities) {
        if (activity.id == null) continue;
        await transaction.insert(
          'cached_activities',
          ActivityCacheMapper.toRow(
            activity,
            userId: scope.userId,
            developmentId: scope.developmentId,
          ),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await transaction.insert('cache_metadata', {
        'user_id': scope.userId,
        'development_id': scope.developmentId,
        'resource': AppDatabase.activitiesResource,
        'refreshed_at_ms': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> upsert(LocalScope scope, AgendaActivity activity) async {
    if (activity.id == null) return;
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await database.insert(
      'cached_activities',
      ActivityCacheMapper.toRow(
        activity,
        userId: scope.userId,
        developmentId: scope.developmentId,
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(LocalScope scope, int activityId) async {
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await database.delete(
      'cached_activities',
      where: 'user_id = ? AND development_id = ? AND activity_id = ?',
      whereArgs: [scope.userId, scope.developmentId, activityId],
    );
  }

  /// Momento de la última actualización confirmada, o `null` si no hay caché.
  Future<DateTime?> cachedAt(LocalScope scope) async {
    final database = await _database.databaseOrNull;
    if (database == null) return null;
    final rows = await database.query(
      'cache_metadata',
      columns: const ['refreshed_at_ms'],
      where: 'user_id = ? AND development_id = ? AND resource = ?',
      whereArgs: [
        scope.userId,
        scope.developmentId,
        AppDatabase.activitiesResource,
      ],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      rows.single['refreshed_at_ms'] as int,
    );
  }

  Future<void> clear(LocalScope scope) async {
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await database.transaction((transaction) async {
      await transaction.delete(
        'cached_activities',
        where: 'user_id = ? AND development_id = ?',
        whereArgs: [scope.userId, scope.developmentId],
      );
      await transaction.delete(
        'cache_metadata',
        where: 'user_id = ? AND development_id = ? AND resource = ?',
        whereArgs: [
          scope.userId,
          scope.developmentId,
          AppDatabase.activitiesResource,
        ],
      );
    });
  }
}
