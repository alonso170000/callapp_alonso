import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/profile_preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late ProfilePreferencesStore store;
  const first = LocalScope(userId: 1, developmentId: 10);
  const second = LocalScope(userId: 2, developmentId: 20);

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    store = ProfilePreferencesStore(database: database);
  });

  tearDown(() => database.close());

  test('guarda preferencias de perfil por usuario y desarrollo', () async {
    await store.setNotificationsEnabled(first, false);
    await store.setReminderMinutes(first, 30);
    await store.setAppearance(first, 'oscuro');
    await store.setReminderMinutes(second, 5);

    final preferences = await store.read(first);
    expect(preferences?.notificationsEnabled, isFalse);
    expect(preferences?.reminderMinutes, 30);
    expect(preferences?.appearance, 'oscuro');
    expect((await store.read(second))?.reminderMinutes, 5);
    expect((await store.read(second))?.notificationsEnabled, isNull);
  });

  test('un valor inválido se trata como preferencia ausente', () async {
    await database.writeMetadata('profile_preferences:1:10', '{incompleto');

    expect(await store.read(first), isNull);
  });
}
