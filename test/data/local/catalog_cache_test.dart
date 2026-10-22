import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/catalog_cache.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late CatalogCache cache;
  const first = LocalScope(userId: 1, developmentId: 10);
  const second = LocalScope(userId: 2, developmentId: 20);

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    cache = CatalogCache(database: database);
  });

  tearDown(() => database.close());

  test('escribe, lee y sobrescribe un catálogo', () async {
    await cache.write(first, 'canales', const [
      {'id': 1, 'nombre': 'Referido'},
    ]);
    expect((await cache.read(first, 'canales'))?.single['id'], 1);

    await cache.write(first, 'canales', const [
      {'id': 2, 'nombre': 'Facebook'},
    ]);
    expect((await cache.read(first, 'canales'))?.single['id'], 2);
  });

  test('aísla los catálogos por usuario y desarrollo', () async {
    await cache.write(first, 'canales', const [
      {'id': 1},
    ]);
    await cache.write(second, 'canales', const [
      {'id': 2},
    ]);

    expect((await cache.read(first, 'canales'))?.single['id'], 1);
    expect((await cache.read(second, 'canales'))?.single['id'], 2);
  });

  test('un JSON corrupto se trata como caché ausente', () async {
    await database.writeMetadata('catalog:canales:1:10', '{incompleto');

    expect(await cache.read(first, 'canales'), isNull);
  });

  test('la precarga vence después del intervalo', () async {
    expect(await cache.isWarmDue(first), isTrue);

    await cache.markWarmAttempt(first);
    expect(await cache.isWarmDue(first), isFalse);

    await database.writeMetadata(
      'catalog_warm:1:10',
      '${businessNow().subtract(CatalogCache.warmInterval + const Duration(minutes: 1)).millisecondsSinceEpoch}',
    );

    expect(await cache.isWarmDue(first), isTrue);
  });

  test('la precarga se aísla por usuario y desarrollo', () async {
    await cache.markWarmAttempt(first);

    expect(await cache.isWarmDue(second), isTrue);
  });
}
