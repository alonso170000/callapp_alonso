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
    required this.windowStart,
    required this.origin,
    this.sourceActivityId,
    this.verified = false,
    this.callLogId,
  });

  final ProspectRecord prospect;

  /// Hora de negocio usada para el payload y la duración estimada.
  final DateTime startedAt;

  /// Instante real (epoch correcto) desde el que se busca la llamada en el
  /// registro del sistema. No usa la hora de negocio para evitar corrimientos.
  final DateTime windowStart;

  final String origin;
  final int? sourceActivityId;

  /// `true` cuando el registro de llamadas o el estado del teléfono confirman
  /// que la llamada ocurrió. Mientras sea `false` la sesión es solo un intento.
  final bool verified;
  final String? callLogId;

  ActiveCall copyWith({bool? verified, String? callLogId}) => ActiveCall(
    prospect: prospect,
    startedAt: startedAt,
    windowStart: windowStart,
    origin: origin,
    sourceActivityId: sourceActivityId,
    verified: verified ?? this.verified,
    callLogId: callLogId ?? this.callLogId,
  );
}

/// Resultado de comprobar si la llamada realmente ocurrió al volver del
/// marcador del teléfono.
enum PendingCallResolution {
  /// No había una sesión pendiente que verificar.
  notPending,

  /// Hay evidencia de la llamada; la sesión se conserva.
  verified,

  /// La llamada sigue activa en el dispositivo; la barra debe mostrarse pero
  /// todavía no hay registro que cerrar.
  inProgress,

  /// No hubo llamada; la sesión se descartó en silencio.
  discarded,

  /// No se pudo verificar (permisos o plataforma). Se conserva para que el
  /// usuario pueda registrarla o descartarla manualmente.
  unverifiable,
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
  bool _resolvingPending = false;
  Future<bool>? _claimInFlight;

  ActiveCall? get activeCall => _activeCall;
  Duration get elapsed => _elapsed;
  int? get lastCallId => _lastCallId;
  bool get hasStaleSession => _staleSession;

  /// `true` mientras la sesión se abrió al lanzar el marcador pero todavía no
  /// hay evidencia de que la llamada haya ocurrido.
  bool get hasUnverifiedCall => _activeCall != null && !_activeCall!.verified;

  Future<CallLogMatch?> latestLog() {
    final current = _activeCall;
    if (current == null) return Future.value();
    return _callLog.latestFor(current.prospect.phone, current.windowStart);
  }

  /// Comprueba, al volver del marcador, si la llamada realmente ocurrió.
  ///
  /// Si solo se abrió la app de teléfono y no se marcó, la sesión se descarta
  /// en silencio para no registrar llamadas inexistentes.
  Future<PendingCallResolution> resolveAfterDialer({
    int attempts = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    final current = _activeCall;
    if (current == null || current.verified) {
      return PendingCallResolution.notPending;
    }
    if (_resolvingPending) return PendingCallResolution.notPending;
    _resolvingPending = true;
    try {
      CallLogMatch? logged;
      for (var attempt = 0; attempt < attempts; attempt++) {
        final pending = _activeCall;
        if (pending == null) return PendingCallResolution.discarded;
        logged = await _callLog.latestFor(
          pending.prospect.phone,
          pending.windowStart,
        );
        if (logged != null) break;
        if (attempt < attempts - 1) {
          await Future<void>.delayed(retryDelay);
        }
      }
      final pending = _activeCall;
      if (pending == null) return PendingCallResolution.discarded;
      if (logged != null) {
        _activeCall = pending.copyWith(
          verified: true,
          callLogId: logged.id,
        );
        await _persist();
        notifyListeners();
        return PendingCallResolution.verified;
      }
      final activeOnDevice = await _callLog.isCallActive();
      if (activeOnDevice == null) {
        // Sin permiso o sin soporte nativo no se puede confirmar: se conserva
        // la sesión para no perder una llamada real.
        _activeCall = pending.copyWith(verified: true);
        await _persist();
        notifyListeners();
        return PendingCallResolution.unverifiable;
      }
      if (activeOnDevice) {
        _activeCall = pending.copyWith(verified: true);
        await _persist();
        notifyListeners();
        return PendingCallResolution.inProgress;
      }
      await cancel();
      return PendingCallResolution.discarded;
    } finally {
      _resolvingPending = false;
    }
  }

  Future<bool> claimCompletedCall({
    int attempts = 6,
    Duration retryDelay = const Duration(seconds: 1),
  }) {
    final inFlight = _claimInFlight;
    if (inFlight != null) return inFlight;
    final future = _claimCompletedCall(attempts: attempts, retryDelay: retryDelay);
    _claimInFlight = future;
    return future.whenComplete(() => _claimInFlight = null);
  }

  Future<bool> _claimCompletedCall({
    required int attempts,
    required Duration retryDelay,
  }) async {
    final current = _activeCall;
    if (current == null || _autoClosureClaimed) return false;
    for (var attempt = 0; attempt < attempts; attempt++) {
      final logged = await _callLog.latestFor(
        current.prospect.phone,
        current.windowStart,
      );
      final loggedAt = logged?.startedAt;
      if (logged != null &&
          (loggedAt == null ||
              !loggedAt.isBefore(
                current.windowStart.subtract(const Duration(seconds: 5)),
              ))) {
        _autoClosureClaimed = true;
        return true;
      }
      if (attempt < attempts - 1) await Future<void>.delayed(retryDelay);
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
      windowStart: DateTime.now(),
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
      current.windowStart,
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
        windowStart: json['window_start_ms'] is int
            ? DateTime.fromMillisecondsSinceEpoch(json['window_start_ms'] as int)
            : startedAt,
        origin: json['origin'] as String,
        sourceActivityId: json['source_activity_id'] as int?,
        // Las sesiones antiguas no guardaban el estado de verificación; se
        // conservan para no interrumpir una llamada que ya estaba en curso.
        verified: json['verified'] as bool? ?? true,
        callLogId: json['call_log_id'] as String?,
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
        'window_start_ms': current.windowStart.millisecondsSinceEpoch,
        'origin': current.origin,
        'source_activity_id': current.sourceActivityId,
        'verified': current.verified,
        'call_log_id': current.callLogId,
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
