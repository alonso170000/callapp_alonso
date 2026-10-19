import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/prospects_cache.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('aísla y reemplaza prospectos por usuario y desarrollo', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final cache = ProspectsCache(database: database);
    const firstScope = ProspectCacheScope(userId: 1, developmentId: 10);
    const secondScope = ProspectCacheScope(userId: 1, developmentId: 20);

    await cache.replace(firstScope, [_prospect(11, 'Ana')]);
    await cache.replace(secondScope, [_prospect(22, 'Brenda')]);

    expect((await cache.read(firstScope)).single.name, 'Ana');
    expect((await cache.read(secondScope)).single.name, 'Brenda');

    await cache.replace(firstScope, [_prospect(33, 'Carla')]);
    expect((await cache.read(firstScope)).map((item) => item.id), [33]);
    expect((await cache.read(secondScope)).map((item) => item.id), [22]);

    await cache.replace(firstScope, []);
    expect(await cache.read(firstScope), isEmpty);
    expect((await cache.read(secondScope)).single.id, 22);
  });

  test('conserva los campos necesarios para filtros y presentación', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final cache = ProspectsCache(database: database);
    const scope = ProspectCacheScope(userId: 2, developmentId: 30);
    final nextContact = DateTime(2026, 10, 22, 14, 30);
    final prospect = ProspectRecord(
      id: 7,
      name: 'José Pérez',
      phone: '9980000000',
      email: 'jose@example.com',
      status: 'Seguimiento',
      temperature: 'Caliente',
      avatarColor: Colors.teal,
      statusColor: Colors.orange,
      nextContact: nextContact,
      qualification: const ['decisión', 'presupuesto'],
      decision: true,
      lastCallDuration: const Duration(minutes: 4, seconds: 12),
    );

    await cache.replace(scope, [prospect]);
    final restored = (await cache.read(scope)).single;

    expect(restored.id, prospect.id);
    expect(restored.nextContact, nextContact);
    expect(restored.qualification, prospect.qualification);
    expect(restored.decision, isTrue);
    expect(restored.lastCallDuration, prospect.lastCallDuration);
  });
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
