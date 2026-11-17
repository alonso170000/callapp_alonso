import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/scripts_cache.dart';
import 'package:callerapp_frontend/presentation/models/guion_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('aísla la caché por desarrollo y tipo', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final cache = ScriptsCache(database: database);
    const developmentA = LocalScope(userId: 7, developmentId: 21);
    const developmentB = LocalScope(userId: 7, developmentId: 22);
    const regular = GuionesBundle(
      guiones: [
        Guion(id: 1, codigo: 'regular', titulo: 'Regular', orden: 1, pasos: []),
      ],
    );
    const reactivated = GuionesBundle(
      guiones: [
        Guion(
          id: 2,
          codigo: 'reactivado',
          titulo: 'Reactivado',
          orden: 1,
          pasos: [],
        ),
      ],
    );

    await cache.write(developmentA, regular, tipoProspecto: 'regular');
    await cache.write(developmentA, reactivated, tipoProspecto: 'reactivado');
    await cache.write(developmentB, regular, tipoProspecto: 'reactivado');

    expect(
      (await cache.read(
        developmentA,
        tipoProspecto: 'regular',
      ))?.guiones.single.codigo,
      'regular',
    );
    expect(
      (await cache.read(
        developmentA,
        tipoProspecto: 'reactivado',
      ))?.guiones.single.codigo,
      'reactivado',
    );
    expect(
      (await cache.read(
        developmentB,
        tipoProspecto: 'reactivado',
      ))?.guiones.single.codigo,
      'regular',
    );
  });
}
