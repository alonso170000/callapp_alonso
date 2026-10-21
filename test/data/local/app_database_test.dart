import 'dart:io';

import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/prospects_cache.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('crea el esquema versión 4 con todas las tablas', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);

    final db = await database.database;
    final tables = (await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    )).map((row) => row['name']).toSet();

    expect(
      tables,
      containsAll([
        'cached_prospects',
        'cache_metadata',
        'activity_notifications',
        'cached_activities',
        'app_metadata',
        'pending_operations',
      ]),
    );
    expect(await db.getVersion(), AppDatabase.schemaVersion);
  });

  test('migra una base versión 2 conservando los datos existentes', () async {
    final directory = Directory.systemTemp.createTempSync('callerapp_db_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final databasePath = path.join(directory.path, 'legacy.db');

    final legacy = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE cached_prospects (
              user_id INTEGER NOT NULL,
              development_id INTEGER NOT NULL,
              prospect_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              PRIMARY KEY (user_id, development_id, prospect_id)
            )
          ''');
          await db.execute('''
            CREATE TABLE cache_metadata (
              user_id INTEGER NOT NULL,
              development_id INTEGER NOT NULL,
              resource TEXT NOT NULL,
              refreshed_at_ms INTEGER NOT NULL,
              PRIMARY KEY (user_id, development_id, resource)
            )
          ''');
          await db.execute('''
            CREATE TABLE activity_notifications (
              user_id INTEGER NOT NULL,
              development_id INTEGER NOT NULL,
              activity_id INTEGER NOT NULL,
              reminder_at_ms INTEGER NOT NULL,
              PRIMARY KEY (user_id, development_id, activity_id)
            )
          ''');
        },
      ),
    );
    await legacy.insert('cached_prospects', {
      'user_id': 1,
      'development_id': 2,
      'prospect_id': 3,
      'name': 'Ana',
    });
    await legacy.close();

    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    addTearDown(database.close);

    final db = await database.database;
    expect(await db.getVersion(), AppDatabase.schemaVersion);
    expect((await db.query('cached_prospects')).single['name'], 'Ana');
    expect(
      (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'cached_activities'",
      )),
      isNotEmpty,
    );
    expect(
      (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'app_metadata'",
      )),
      isNotEmpty,
    );
  });

  test('en plataformas sin Android la caché degrada sin errores', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final database = AppDatabase();
    final cache = ProspectsCache(database: database);
    const scope = LocalScope(userId: 1, developmentId: 2);
    final prospect = ProspectRecord(
      id: 5,
      name: 'Ana',
      phone: '998',
      email: 'ana@example.com',
      status: 'Nuevo',
      temperature: 'Tibio',
      avatarColor: Colors.teal,
      statusColor: Colors.blue,
    );

    expect(database.isAvailable, isFalse);
    await cache.replace(scope, [prospect]);
    expect(await cache.read(scope), isEmpty);
    expect(await cache.cachedAt(scope), isNull);
  });
}
