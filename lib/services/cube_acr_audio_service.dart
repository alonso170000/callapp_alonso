import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/presentation/models/call_models.dart';
import 'package:callerapp_frontend/services/audio_import_service.dart';
import 'package:callerapp_frontend/services/phone_number.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class CubeAcrAudioCandidate {
  const CubeAcrAudioCandidate({
    required this.uri,
    required this.name,
    required this.recordedAt,
  });

  final String uri;
  final String name;
  final DateTime recordedAt;
}

class CubeAcrAudioService {
  CubeAcrAudioService({AppDatabase? database, AuthService? auth})
    : _database = database ?? AppDatabase.instance,
      _auth = auth ?? AuthService.instance;

  static const _channel = MethodChannel('callerapp/cube_acr');
  static const _uriPrefix = 'cube_acr_tree_uri';
  static const _namePrefix = 'cube_acr_tree_name';
  final AppDatabase _database;
  final AuthService _auth;

  LocalScope get scope {
    final userId = _auth.userId;
    final developmentId = _auth.developmentId;
    if (userId == null || developmentId == null) {
      throw const AudioImportException(
        'Inicia sesión para vincular la carpeta de Cube ACR.',
      );
    }
    return LocalScope(userId: userId, developmentId: developmentId);
  }

  String _key(String prefix, LocalScope scope) =>
      '$prefix:${scope.userId}:${scope.developmentId}';

  Future<String?> folderName() => _read(_key(_namePrefix, scope));

  Future<bool> hasFolder() async =>
      (await _read(_key(_uriPrefix, scope))) != null;

  Future<String?> linkFolder() async {
    final selected = await _channel.invokeMapMethod<String, dynamic>(
      'pickFolder',
    );
    final uri = selected?['uri'];
    final name = selected?['name'];
    if (uri is! String || uri.isEmpty || name is! String || name.isEmpty) {
      return null;
    }
    await _write(_key(_uriPrefix, scope), uri);
    await _write(_key(_namePrefix, scope), name);
    return name;
  }

  Future<List<CubeAcrAudioCandidate>> findCandidates(
    ProspectCallSession call,
  ) async {
    final treeUri = await _read(_key(_uriPrefix, scope));
    if (treeUri == null) return const [];
    final raw = await _channel.invokeListMethod<dynamic>('listRecordings', {
      'treeUri': treeUri,
    });
    if (raw == null) return const [];
    final number = PhoneNumber.digits(call.phone);
    final suffix = number.length > 10
        ? number.substring(number.length - 10)
        : number;
    final start = call.startedAt.subtract(const Duration(minutes: 2));
    final end = call.endedAt.add(const Duration(minutes: 5));
    final candidates = <CubeAcrAudioCandidate>[];
    for (final value in raw) {
      if (value is! Map) continue;
      final name = value['name'];
      final uri = value['uri'];
      if (name is! String || uri is! String) continue;
      final match = RegExp(
        r'^phone_(\d{8})-(\d{6})_(\d{7,15})\.amr$',
        caseSensitive: false,
      ).firstMatch(name);
      if (match == null) continue;
      final recordedAt = _parseDate(match.group(1)!, match.group(2)!);
      final recordedNumber = PhoneNumber.digits(match.group(3)!);
      final recordedSuffix = recordedNumber.length > 10
          ? recordedNumber.substring(recordedNumber.length - 10)
          : recordedNumber;
      if (recordedAt == null ||
          recordedAt.isBefore(start) ||
          recordedAt.isAfter(end)) {
        continue;
      }
      if (suffix.isEmpty || suffix != recordedSuffix) continue;
      candidates.add(
        CubeAcrAudioCandidate(uri: uri, name: name, recordedAt: recordedAt),
      );
    }
    candidates.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return candidates;
  }

  Future<ImportedCallAudio> copyToPrivate(
    CubeAcrAudioCandidate candidate,
  ) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'copyRecording',
      {'uri': candidate.uri, 'name': candidate.name},
    );
    final filePath = result?['path'];
    if (filePath is! String || filePath.isEmpty) {
      throw const AudioImportException(
        'No se pudo copiar la grabación de Cube ACR.',
      );
    }
    return ImportedCallAudio(path: filePath, name: candidate.name);
  }

  DateTime? _parseDate(String date, String time) {
    try {
      return DateTime(
        int.parse(date.substring(0, 4)),
        int.parse(date.substring(4, 6)),
        int.parse(date.substring(6, 8)),
        int.parse(time.substring(0, 2)),
        int.parse(time.substring(2, 4)),
        int.parse(time.substring(4, 6)),
      );
    } on FormatException {
      return null;
    }
  }

  Future<String?> _read(String key) async {
    final database = await _database.databaseOrNull;
    if (database == null) return null;
    final rows = await database.query(
      'app_metadata',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.single['value'] as String?;
  }

  Future<void> _write(String key, String value) async {
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await database.insert('app_metadata', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
