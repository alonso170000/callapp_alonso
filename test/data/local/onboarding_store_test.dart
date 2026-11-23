import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/onboarding_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('persiste la finalización fuera del ámbito de sesión', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final store = OnboardingStore(database: database);

    expect(await store.isCompleted(), isFalse);
    await store.markCompleted();
    expect(await store.isCompleted(), isTrue);

    await database.clearScope(const LocalScope(userId: 1, developmentId: 2));
    expect(await store.isCompleted(), isTrue);
  });
}
