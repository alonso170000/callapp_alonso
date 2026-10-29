import 'dart:async';
import 'dart:convert';

import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/presentation/models/call_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/services/call_log_service.dart';
import 'package:callerapp_frontend/services/cube_acr_audio_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class ActiveCall {
  const ActiveCall({
    required this.prospect,
    required this.startedAt,
    required this.origin,
    this.sourceActivityId,
  });

  final ProspectRecord prospect;
  final DateTime startedAt;
  final String origin;
  final int? sourceActivityId;
}

class CallRegistrationResult {
  const CallRegistrationResult({
    required this.success,
    required this.message,
    this.callId,
    this.pending = false,
    this.prospect,
  });

  final bool success;
  final String message;
  final int? callId;
  final bool pending;
  final ProspectRecord? prospect;
}

class CallSessionException implements Exception {
  const CallSessionException(this.message);
  final String message;
}

class CallSessionController extends ChangeNotifier {
  CallSessionController({
    ProspectsRepository? repository,
    CallLogService? callLog,
    AppDatabase? database,
    AuthService? auth,
  }) : _repository = repository ?? ProspectsRepository(),
       _callLog = callLog ?? CallLogService(),
       _database = database ?? AppDatabase.instance,
       _auth = auth ?? AuthService.instance;

  static final instance = CallSessionController();

  final ProspectsRepository _repository;
  final CallLogService _callLog;
  final AppDatabase _database;
  final AuthService _auth;
  Timer? _timer;
  ActiveCall? _activeCall;
  Duration _elapsed = Duration.zero;
  int? _lastCallId;
  bool _staleSession = false;
  bool _autoClosureClaimed = false;

  ActiveCall? get activeCall => _activeCall;
  Duration get elapsed => _elapsed;
  int? get lastCallId => _lastCallId;
  bool get hasStaleSession => _staleSession;

  Future<CallLogMatch?> latestLog() {
    final current = _activeCall;
    if (current == null) return Future.value();
    return _callLog.latestFor(current.prospect.phone, current.startedAt);
  }

  Future<bool> claimCompletedCall() async {
    final current = _activeCall;
    if (current == null || _autoClosureClaimed) return false;
    for (var attempt = 0; attempt < 6; attempt++) {
      final logged = await _callLog.latestFor(
        current.prospect.phone,
        current.startedAt,
      );
      final loggedAt = logged?.startedAt;
      if (logged != null &&
          (loggedAt == null ||
              !loggedAt.isBefore(
                current.startedAt.subtract(const Duration(seconds: 5)),
              ))) {
        _autoClosureClaimed = true;
        return true;
      }
      if (attempt < 5) await Future<void>.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  String get _storageKey {
    final userId = _auth.userId;
    final developmentId = _auth.developmentId;
    if (userId == null || developmentId == null) {
      throw const CallSessionException(
        'Inicia sesión para conservar la llamada en curso.',
      );
    }
    return 'active_call:$userId:$developmentId';
  }

  Future<void> start({
    required ProspectRecord prospect,
    required String origin,
    int? sourceActivityId,
    required DateTime startedAt,
  }) async {
    if (_activeCall != null) {
      throw const CallSessionException(
        'Termina la llamada en curso antes de marcar otro número.',
      );
    }
    _activeCall = ActiveCall(
      prospect: prospect,
      startedAt: startedAt,
      origin: origin,
      sourceActivityId: sourceActivityId,
    );
    _autoClosureClaimed = false;
    _elapsed = businessNow().difference(startedAt);
    await _persist();
    _startTimer();
    notifyListeners();
  }

  Future<CallRegistrationResult> finish({
    required ProspectCallOutcome outcome,
    required bool consent,
    ImportedCallAudio? audio,
  }) async {
    final current = _activeCall;
    if (current == null) {
      return const CallRegistrationResult(
        success: false,
        message: 'No hay una llamada en curso para registrar.',
      );
    }
    if (!consent && audio != null) {
      return const CallRegistrationResult(
        success: false,
        message: 'No se puede adjuntar audio sin consentimiento.',
      );
    }
    final endedAt = businessNow();
    final logged = await _callLog.latestFor(
      current.prospect.phone,
      current.startedAt,
    );
    final call = ProspectCallSession(
      startedAt: current.startedAt,
      endedAt: endedAt,
      outcome: outcome,
      phone: current.prospect.phone,
      origin: current.origin,
      sourceActivityId: current.sourceActivityId,
      realDurationSeconds: logged?.durationSeconds,
      callLogId: logged?.id,
      audioPath: consent ? audio?.path : null,
      audioName: consent ? audio?.name : null,
      consent: consent,
    );
    try {
      final result = await _repository.registerCall(current.prospect, call);
      _lastCallId = result.callId;
      await _clearActive();
      return CallRegistrationResult(
        success: true,
        pending: result.isPending,
        callId: result.callId,
        message: result.isPending
            ? 'Llamada registrada. Se sincronizará cuando haya conexión.'
            : 'Llamada registrada.',
        prospect: result.prospect,
      );
    } on Object catch (error) {
      final message = error is ProspectsException
          ? error.message
          : 'No se pudo registrar la llamada. Inténtalo nuevamente.';
      return CallRegistrationResult(success: false, message: message);
    }
  }

  Future<void> cancel() => _clearActive();

  Future<void> restore() async {
    String key;
    try {
      key = _storageKey;
    } on CallSessionException {
      return;
    }
    final database = await _database.databaseOrNull;
    if (database == null) return;
    final rows = await database.query(
      'app_metadata',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return;
    try {
      final json = jsonDecode(rows.single['value'] as String) as Map;
      final startedAt = DateTime.parse(json['started_at'] as String);
      if (businessNow().difference(startedAt) >= const Duration(hours: 4)) {
        _staleSession = true;
        notifyListeners();
        return;
      }
      _activeCall = ActiveCall(
        prospect: ProspectRecord(
          id: json['prospect_id'] as int?,
          name: json['name'] as String,
          phone: json['phone'] as String,
          email: json['email'] as String? ?? '',
          status: json['status'] as String? ?? 'Nuevo',
          temperature: json['temperature'] as String? ?? 'Tibio',
          avatarColor: AppColors.primaryColor,
          statusColor: AppColors.primaryColor,
        ),
        startedAt: startedAt,
        origin: json['origin'] as String,
        sourceActivityId: json['source_activity_id'] as int?,
      );
      _autoClosureClaimed = false;
      _elapsed = businessNow().difference(startedAt);
      _startTimer();
      notifyListeners();
    } on Object {
      await cancel();
    }
  }

  Future<void> discardStale() async {
    _staleSession = false;
    await _deletePersisted();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = _activeCall;
      if (current == null) return;
      _elapsed = businessNow().difference(current.startedAt);
      notifyListeners();
    });
  }

  Future<void> _persist() async {
    final current = _activeCall;
    final database = await _database.databaseOrNull;
    if (current == null || database == null) return;
    await database.insert('app_metadata', {
      'key': _storageKey,
      'value': jsonEncode({
        'prospect_id': current.prospect.id,
        'name': current.prospect.name,
        'phone': current.prospect.phone,
        'email': current.prospect.email,
        'status': current.prospect.status,
        'temperature': current.prospect.temperature,
        'started_at': current.startedAt.toIso8601String(),
        'origin': current.origin,
        'source_activity_id': current.sourceActivityId,
      }),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _deletePersisted() async {
    final database = await _database.databaseOrNull;
    if (database == null) return;
    try {
      await database.delete(
        'app_metadata',
        where: 'key = ?',
        whereArgs: [_storageKey],
      );
    } on CallSessionException {
      return;
    }
  }

  Future<void> _clearActive() async {
    _timer?.cancel();
    _timer = null;
    await _deletePersisted();
    _activeCall = null;
    _autoClosureClaimed = false;
    _elapsed = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
