import 'dart:convert';

import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';

class ProfilePreferences {
  const ProfilePreferences({
    this.notificationsEnabled,
    this.reminderMinutes,
    this.appearance,
  });

  final bool? notificationsEnabled;
  final int? reminderMinutes;
  final String? appearance;

  ProfilePreferences copyWith({
    bool? notificationsEnabled,
    int? reminderMinutes,
    String? appearance,
  }) => ProfilePreferences(
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    appearance: appearance ?? this.appearance,
  );

  Map<String, Object?> toJson() => {
    'notifications_enabled': notificationsEnabled,
    'reminder_minutes': reminderMinutes,
    'appearance': appearance,
  };

  static ProfilePreferences? fromJson(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return null;
      final reminder = value['reminder_minutes'];
      return ProfilePreferences(
        notificationsEnabled: value['notifications_enabled'] is bool
            ? value['notifications_enabled'] as bool
            : null,
        reminderMinutes: reminder is int && [5, 15, 30, 60].contains(reminder)
            ? reminder
            : null,
        appearance: value['appearance'] is String
            ? value['appearance'] as String
            : null,
      );
    } on FormatException {
      return null;
    }
  }
}

class ProfilePreferencesStore {
  ProfilePreferencesStore({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  String _key(LocalScope scope) =>
      'profile_preferences:${scope.userId}:${scope.developmentId}';

  Future<ProfilePreferences?> read(LocalScope scope) async {
    try {
      final raw = await _database.readMetadata(_key(scope));
      return raw == null ? null : ProfilePreferences.fromJson(raw);
    } on Object {
      return null;
    }
  }

  Future<void> write(LocalScope scope, ProfilePreferences preferences) async {
    try {
      await _database.writeMetadata(
        _key(scope),
        jsonEncode(preferences.toJson()),
      );
      await _database.touchMetadata(scope, AppDatabase.preferencesResource);
    } on Object {
      // La preferencia local no debe bloquear el cambio visible en la app.
    }
  }

  Future<void> setNotificationsEnabled(LocalScope scope, bool value) async {
    final current = await read(scope) ?? const ProfilePreferences();
    await write(scope, current.copyWith(notificationsEnabled: value));
  }

  Future<void> setReminderMinutes(LocalScope scope, int value) async {
    final current = await read(scope) ?? const ProfilePreferences();
    await write(scope, current.copyWith(reminderMinutes: value));
  }

  Future<void> setAppearance(LocalScope scope, String value) async {
    final current = await read(scope) ?? const ProfilePreferences();
    await write(scope, current.copyWith(appearance: value));
  }
}
