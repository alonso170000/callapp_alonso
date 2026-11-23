import 'package:callerapp_frontend/data/local/app_database.dart';

/// Preferencia del dispositivo: se muestra una vez por instalación.
class OnboardingStore {
  OnboardingStore({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  static const completedKey = 'onboarding_completed_v2';

  final AppDatabase _database;

  Future<bool> isCompleted() async =>
      (await _database.readMetadata(completedKey)) == '1';

  Future<void> markCompleted() => _database.writeMetadata(completedKey, '1');
}
