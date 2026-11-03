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

  /// [startedAt] debe ser el instante real en que se abrió el marcador (epoch
  /// correcto), no la hora de negocio.
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

  /// Indica si el dispositivo tiene una llamada activa ahora mismo.
  ///
  /// Devuelve `null` cuando no hay permiso o la plataforma no lo soporta, para
  /// que la app pueda conservar la sesión en lugar de descartar una llamada
  /// real por falta de información.
  Future<bool?> isCallActive() async {
    try {
      return await _channel.invokeMethod<bool>('isCallActive');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
