import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/onboarding_store.dart';
import 'package:callerapp_frontend/services/onboarding_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('carga pendiente y completa el onboarding en Android', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final store = OnboardingStore(database: database);
    final controller = OnboardingController(store: store, isAndroid: true);

    await controller.load();
    expect(controller.completed, isFalse);

    await controller.complete();
    expect(controller.completed, isTrue);
    expect(await store.isCompleted(), isTrue);
  });
}
