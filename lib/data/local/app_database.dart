import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? databasePath})
    : this._(factory, databasePath);

  AppDatabase._(this._factory, this._databasePath);

  static final instance = AppDatabase();

  final DatabaseFactory? _factory;
  final String? _databasePath;
  Database? _database;
  Future<Database>? _opening;

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
        version: 1,
        onCreate: (database, _) async {
          await database.execute('''
            CREATE TABLE cached_prospects (
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
            CREATE TABLE cache_metadata (
              user_id INTEGER NOT NULL,
              development_id INTEGER NOT NULL,
              resource TEXT NOT NULL,
              refreshed_at_ms INTEGER NOT NULL,
              PRIMARY KEY (user_id, development_id, resource)
            )
          ''');
          await database.execute('''
            CREATE INDEX idx_cached_prospects_scope_name
            ON cached_prospects (user_id, development_id, name)
          ''');
          await database.execute('''
            CREATE INDEX idx_cached_prospects_scope_status
            ON cached_prospects (user_id, development_id, status)
          ''');
          await database.execute('''
            CREATE INDEX idx_cached_prospects_scope_next_contact
            ON cached_prospects (
              user_id,
              development_id,
              next_contact_at_ms
            )
          ''');
        },
      ),
    );
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    _opening = null;
    await database?.close();
  }
}
