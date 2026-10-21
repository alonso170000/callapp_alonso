import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/mappers/prospect_cache_mapper.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:sqflite/sqflite.dart';

class ProspectsCache {
  ProspectsCache({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<ProspectRecord>> read(LocalScope scope) async {
    final database = await _database.databaseOrNull;
    if (database == null) return const [];
    final rows = await database.query(
      'cached_prospects',
      where: 'user_id = ? AND development_id = ?',
      whereArgs: [scope.userId, scope.developmentId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(ProspectCacheMapper.fromRow).toList();
  }

  Future<void> replace(LocalScope scope, List<ProspectRecord> prospects) async {
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await database.transaction((transaction) async {
      await transaction.delete(
        'cached_prospects',
        where: 'user_id = ? AND development_id = ?',
        whereArgs: [scope.userId, scope.developmentId],
      );
      for (final prospect in prospects) {
        if (prospect.id == null) continue;
        await transaction.insert(
          'cached_prospects',
          ProspectCacheMapper.toRow(
            prospect,
            userId: scope.userId,
            developmentId: scope.developmentId,
          ),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await transaction.insert('cache_metadata', {
        'user_id': scope.userId,
        'development_id': scope.developmentId,
        'resource': AppDatabase.prospectsResource,
        'refreshed_at_ms': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
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
        AppDatabase.prospectsResource,
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
        'cached_prospects',
        where: 'user_id = ? AND development_id = ?',
        whereArgs: [scope.userId, scope.developmentId],
      );
      await transaction.delete(
        'cache_metadata',
        where: 'user_id = ? AND development_id = ? AND resource = ?',
        whereArgs: [
          scope.userId,
          scope.developmentId,
          AppDatabase.prospectsResource,
        ],
      );
    });
  }
}
