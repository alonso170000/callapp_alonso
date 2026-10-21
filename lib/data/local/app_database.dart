import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/services/platform_support.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// Base de datos local de la app.
///
/// Solo se abre en Android. Cuando la plataforma no la soporta, las lecturas
/// devuelven `null` y las escrituras se ignoran para que la app pueda seguir
/// trabajando contra la API. Las pruebas inyectan un `DatabaseFactory` (FFI)
/// y, por lo tanto, quedan habilitadas en cualquier plataforma.
class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? databasePath})
    : this._(factory, databasePath);

  AppDatabase._(this._factory, this._databasePath);

  static final instance = AppDatabase();

  static const schemaVersion = 4;
  static const prospectsResource = 'prospects';
  static const activitiesResource = 'activities';
  static const maintenanceKey = 'last_maintenance_at_ms';

  final DatabaseFactory? _factory;
  final String? _databasePath;
  Database? _database;
  Future<Database>? _opening;

  /// `true` cuando SQLite puede usarse en esta plataforma o cuando se inyectó
  /// un factory explícito (pruebas).
  bool get isAvailable => _factory != null || PlatformSupport.isAndroid;

  /// Devuelve la base de datos o `null` si el almacenamiento local no aplica.
  Future<Database?> get databaseOrNull async {
    if (!isAvailable) return null;
    return database;
  }

  Future<Database> get database {
    final current = _database;
    if (current != null) return Future.value(current);
    return _opening ??= _open().then(
      (database) {
        _database = database;
        _opening = null;
        return database;
      },
      onError: (Object error, StackTrace stackTrace) {
        _opening = null;
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }

  Future<Database> _open() async {
    final factory = _factory ?? databaseFactory;
    final resolvedPath =
        _databasePath ??
        path.join(await factory.getDatabasesPath(), 'callerapp.db');
    return factory.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: (database, _) async {
          await _createProspectsTable(database);
          await _createMetadataTable(database);
          await _createNotificationsTable(database);
          await _createActivitiesTable(database);
          await _createAppMetadataTable(database);
          await _createPendingOperationsTable(database);
        },
        onUpgrade: (database, oldVersion, _) async {
          if (oldVersion < 2) await _createNotificationsTable(database);
          if (oldVersion < 3) {
            await _createActivitiesTable(database);
            await _createAppMetadataTable(database);
          }
          if (oldVersion < 4) await _createPendingOperationsTable(database);
        },
      ),
    );
  }

  static Future<void> _createProspectsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS cached_prospects (
        user_id INTEGER NOT NULL,
        development_id INTEGER NOT NULL,
        prospect_id INTEGER NOT NULL,
        avatar_url TEXT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        status TEXT NOT NULL,
        temperature TEXT NOT NULL,
        appointment_at_ms INTEGER,
        comments TEXT,
        product TEXT NOT NULL DEFAULT '',
        lot_description TEXT NOT NULL DEFAULT '',
        dimension REAL NOT NULL DEFAULT 0,
        full_price REAL NOT NULL DEFAULT 0,
        decision INTEGER NOT NULL DEFAULT 0,
        willingness INTEGER NOT NULL DEFAULT 0,
        money INTEGER NOT NULL DEFAULT 0,
        passed_to_to INTEGER NOT NULL DEFAULT 0,
        discovery_complete INTEGER NOT NULL DEFAULT 0,
        days_since_contact INTEGER NOT NULL DEFAULT 0,
        assigned_at_ms INTEGER,
        next_contact_at_ms INTEGER,
        last_contact_result TEXT NOT NULL,
        last_call_duration_ms INTEGER,
        last_call_at_ms INTEGER,
        last_call_status TEXT,
        city TEXT NOT NULL,
        company TEXT NOT NULL,
        occupation TEXT NOT NULL,
        origin TEXT NOT NULL,
        channel_id INTEGER,
        status_id INTEGER,
        campaign_id INTEGER,
        interest_development_id INTEGER,
        interest_development TEXT NOT NULL,
        interest_lot_id INTEGER,
        interest_lot TEXT NOT NULL,
        qualification_json TEXT NOT NULL DEFAULT '[]',
        PRIMARY KEY (user_id, development_id, prospect_id)
      )
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_cached_prospects_scope_name
      ON cached_prospects (user_id, development_id, name)
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_cached_prospects_scope_status
      ON cached_prospects (user_id, development_id, status)
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_cached_prospects_scope_next_contact
      ON cached_prospects (user_id, development_id, next_contact_at_ms)
    ''');
  }

  static Future<void> _createMetadataTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS cache_metadata (
        user_id INTEGER NOT NULL,
        development_id INTEGER NOT NULL,
        resource TEXT NOT NULL,
        refreshed_at_ms INTEGER NOT NULL,
        PRIMARY KEY (user_id, development_id, resource)
      )
    ''');
  }

  static Future<void> _createNotificationsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS activity_notifications (
        user_id INTEGER NOT NULL,
        development_id INTEGER NOT NULL,
        activity_id INTEGER NOT NULL,
        prospect_id INTEGER,
        type TEXT,
        medium TEXT,
        title TEXT NOT NULL,
        prospect TEXT NOT NULL,
        description TEXT NOT NULL,
        activity_at_ms INTEGER NOT NULL,
        reminder_at_ms INTEGER NOT NULL,
        status TEXT NOT NULL,
        tags_json TEXT NOT NULL DEFAULT '[]',
        location TEXT NOT NULL,
        reminder_minutes INTEGER NOT NULL,
        has_reminder INTEGER NOT NULL,
        last_contact TEXT NOT NULL,
        prospect_avatar_url TEXT,
        completed_at_ms INTEGER,
        is_read INTEGER NOT NULL DEFAULT 0,
        dismissed INTEGER NOT NULL DEFAULT 0,
        created_at_ms INTEGER NOT NULL,
        PRIMARY KEY (user_id, development_id, activity_id)
      )
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_activity_notifications_scope_reminder
      ON activity_notifications (
        user_id,
        development_id,
        reminder_at_ms DESC
      )
    ''');
  }

  static Future<void> _createActivitiesTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS cached_activities (
        user_id INTEGER NOT NULL,
        development_id INTEGER NOT NULL,
        activity_id INTEGER NOT NULL,
        prospect_id INTEGER,
        prospect_avatar_url TEXT,
        type TEXT,
        medium TEXT,
        title TEXT NOT NULL,
        prospect TEXT NOT NULL,
        description TEXT NOT NULL,
        activity_at_ms INTEGER NOT NULL,
        server_status TEXT NOT NULL,
        tags_json TEXT NOT NULL DEFAULT '[]',
        location TEXT NOT NULL,
        reminder_minutes INTEGER NOT NULL,
        has_reminder INTEGER NOT NULL,
        last_contact TEXT NOT NULL,
        completed_at_ms INTEGER,
        delete_until_ms INTEGER,
        PRIMARY KEY (user_id, development_id, activity_id)
      )
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_cached_activities_scope_date
      ON cached_activities (user_id, development_id, activity_at_ms)
    ''');
  }

  static Future<void> _createAppMetadataTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createPendingOperationsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS pending_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        development_id INTEGER NOT NULL,
        operation_key TEXT NOT NULL,
        kind TEXT NOT NULL,
        entity_id INTEGER,
        payload_json TEXT NOT NULL,
        created_at_ms INTEGER NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        state TEXT NOT NULL DEFAULT 'pending',
        UNIQUE (user_id, development_id, operation_key)
      )
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_pending_operations_scope_order
      ON pending_operations (user_id, development_id, created_at_ms, id)
    ''');
  }

  /// Elimina los ámbitos cuya última actualización es anterior a [cutoff].
  ///
  /// Devuelve la cantidad de filas eliminadas entre cachés y metadata.
  Future<int> purgeExpiredScopes(DateTime cutoff) async {
    final database = await databaseOrNull;
    if (database == null) return 0;
    final cutoffMs = cutoff.millisecondsSinceEpoch;
    return database.transaction((transaction) async {
      var removed = 0;
      for (final entry in const {
        prospectsResource: 'cached_prospects',
        activitiesResource: 'cached_activities',
      }.entries) {
        final scopes = await transaction.query(
          'cache_metadata',
          columns: const ['user_id', 'development_id'],
          where: 'resource = ? AND refreshed_at_ms < ?',
          whereArgs: [entry.key, cutoffMs],
        );
        for (final scope in scopes) {
          removed += await transaction.delete(
            entry.value,
            where: 'user_id = ? AND development_id = ?',
            whereArgs: [scope['user_id'], scope['development_id']],
          );
        }
        removed += await transaction.delete(
          'cache_metadata',
          where: 'resource = ? AND refreshed_at_ms < ?',
          whereArgs: [entry.key, cutoffMs],
        );
      }
      return removed;
    });
  }

  /// Elimina los datos locales de un usuario y desarrollo concretos.
  Future<void> clearScope(LocalScope scope) async {
    final database = await databaseOrNull;
    if (database == null) return;
    final where = 'user_id = ? AND development_id = ?';
    final args = [scope.userId, scope.developmentId];
    await database.transaction((transaction) async {
      for (final table in const [
        'cached_prospects',
        'cached_activities',
        'cache_metadata',
        'activity_notifications',
      ]) {
        await transaction.delete(table, where: where, whereArgs: args);
      }
    });
  }

  /// Elimina todos los datos locales. Se conserva solo la estructura.
  Future<void> clearAll() async {
    final database = await databaseOrNull;
    if (database == null) return;
    await database.transaction((transaction) async {
      for (final table in const [
        'cached_prospects',
        'cached_activities',
        'cache_metadata',
        'activity_notifications',
        'app_metadata',
      ]) {
        await transaction.delete(table);
      }
    });
  }

  /// Elimina avisos leídos anteriores a [cutoff] de todos los ámbitos.
  Future<int> purgeReadNotificationsBefore(DateTime cutoff) async {
    final database = await databaseOrNull;
    if (database == null) return 0;
    return database.delete(
      'activity_notifications',
      where: 'is_read = 1 AND reminder_at_ms < ?',
      whereArgs: [cutoff.millisecondsSinceEpoch],
    );
  }

  Future<int?> readMetadataInt(String key) async {
    final database = await databaseOrNull;
    if (database == null) return null;
    final rows = await database.query(
      'app_metadata',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return int.tryParse('${rows.single['value']}');
  }

  Future<void> writeMetadata(String key, String value) async {
    final database = await databaseOrNull;
    if (database == null) return;
    await database.insert('app_metadata', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    _opening = null;
    await database?.close();
  }
}
