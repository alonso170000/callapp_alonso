import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/mappers/prospect_cache_mapper.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:sqflite/sqflite.dart';

class ProspectCacheScope {
  const ProspectCacheScope({required this.userId, required this.developmentId});

  final int userId;
  final int developmentId;
}

class ProspectsCache {
  ProspectsCache({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<ProspectRecord>> read(ProspectCacheScope scope) async {
    final database = await _database.database;
    final rows = await database.query(
      'cached_prospects',
      where: 'user_id = ? AND development_id = ?',
      whereArgs: [scope.userId, scope.developmentId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(ProspectCacheMapper.fromRow).toList();
  }

  Future<void> replace(
    ProspectCacheScope scope,
    List<ProspectRecord> prospects,
  ) async {
    final database = await _database.database;
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
        'resource': 'prospects',
        'refreshed_at_ms': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }
}
