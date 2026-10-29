import 'package:flutter/services.dart';

class CallLogMatch {
  const CallLogMatch({
    required this.durationSeconds,
    required this.id,
    this.startedAt,
  });
  final int durationSeconds;
  final String id;
  final DateTime? startedAt;
}

/// Puente Android para reconciliar una llamada saliente con el registro del SO.
/// Si no hay permiso o aún no existe la fila, devuelve `null` y la duración de
/// la sesión se marca explícitamente como estimada.
class CallLogService {
  static const _channel = MethodChannel('callerapp/call_log');

  Future<CallLogMatch?> latestFor(String phone, DateTime startedAt) async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('latestFor', {
        'phone': phone,
        'startedAtMs': startedAt.millisecondsSinceEpoch,
      });
      if (raw == null || raw['durationSeconds'] is! int || raw['id'] == null) {
        return null;
      }
      return CallLogMatch(
        durationSeconds: raw['durationSeconds'] as int,
        id: '${raw['id']}',
        startedAt: raw['startedAtMs'] is int
            ? DateTime.fromMillisecondsSinceEpoch(raw['startedAtMs'] as int)
            : null,
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
