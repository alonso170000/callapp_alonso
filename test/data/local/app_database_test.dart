import 'dart:io';

import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/catalog_cache.dart';
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

  test('devuelve la actualización más reciente del ámbito', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    const scope = LocalScope(userId: 1, developmentId: 2);
    final db = await database.database;
    final first = DateTime.utc(2026, 10, 24, 10);
    final latest = DateTime.utc(2026, 10, 24, 12);

    await db.insert('cache_metadata', {
      'user_id': scope.userId,
      'development_id': scope.developmentId,
      'resource': 'prospects',
      'refreshed_at_ms': first.millisecondsSinceEpoch,
    });
    await db.insert('cache_metadata', {
      'user_id': scope.userId,
      'development_id': scope.developmentId,
      'resource': 'activities',
      'refreshed_at_ms': latest.millisecondsSinceEpoch,
    });

    expect(await database.lastRefreshedAt(scope), latest);
  });

  test(
    'la limpieza de 30 días purga el ámbito completo y respeta el reciente',
    () async {
      final database = AppDatabase(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      addTearDown(database.close);
      final db = await database.database;
      const expired = LocalScope(userId: 3, developmentId: 4);
      const fresh = LocalScope(userId: 9, developmentId: 9);
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(days: 30));

      // Ámbito vencido: catálogos, mapa temporal→real y un aviso programado.
      await CatalogCache(database: database).write(expired, 'canales', const [
        {'id': 1, 'nombre': 'Referido'},
      ]);
      await db.insert('app_metadata', {
        'key': 'local_id_map:prospect:3:4',
        'value': '{"-1":10}',
      });
      await db.insert('activity_notifications', {
        'user_id': 3,
        'development_id': 4,
        'activity_id': 1,
        'title': 'Aviso',
        'prospect': 'Ana',
        'description': 'Recordatorio',
        'activity_at_ms': 1,
        'reminder_at_ms': 1,
        'status': 'pending',
        'location': '',
        'reminder_minutes': 15,
        'has_reminder': 1,
        'last_contact': '',
        'created_at_ms': 1,
      });
      await db.update('cache_metadata', {
        'refreshed_at_ms': now
            .subtract(const Duration(days: 40))
            .millisecondsSinceEpoch,
      }, where: 'user_id = 3 AND development_id = 4');

      // Ámbito reciente: un prospecto que no debe tocarse.
      await ProspectsCache(database: database)
          .replace(fresh, [_prospect(15, 'Reciente')]);
      await db.update('cache_metadata', {
        'refreshed_at_ms': now
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch,
      }, where: 'user_id = 9 AND development_id = 9');

      expect(await database.purgeExpiredScopes(cutoff), greaterThan(0));
      expect(await db.query('app_metadata'), isEmpty);
      expect(await db.query('activity_notifications'), isEmpty);
      expect(await db.query('cache_metadata', where: 'user_id = 3'), isEmpty);
      expect(
        (await ProspectsCache(database: database).read(fresh)).single.name,
        'Reciente',
      );
    },
  );
}

ProspectRecord _prospect(int id, String name) => ProspectRecord(
  id: id,
  name: name,
  phone: '$id',
  email: '$name@example.com',
  status: 'Nuevo',
  temperature: 'Tibio',
  avatarColor: Colors.teal,
  statusColor: Colors.blue,
);
