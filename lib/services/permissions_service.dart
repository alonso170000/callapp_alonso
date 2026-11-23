import 'package:callerapp_frontend/services/platform_support.dart';
import 'package:flutter/services.dart';

class PermissionsException implements Exception {
  const PermissionsException(this.message);
  final String message;
}

class PermissionSnapshot {
  const PermissionSnapshot({
    required this.notifications,
    required this.exactAlarms,
    required this.callLog,
    required this.phoneState,
  });

  static const unrestricted = PermissionSnapshot(
    notifications: true,
    exactAlarms: true,
    callLog: true,
    phoneState: true,
  );

  final bool notifications;
  final bool exactAlarms;
  final bool callLog;
  final bool phoneState;

  bool get callsGranted => callLog && phoneState;
}

class PermissionsService {
  PermissionsService({MethodChannel? channel, bool? isAndroid})
    : _channel = channel ?? const MethodChannel('callerapp/permissions'),
      _isAndroid = isAndroid ?? PlatformSupport.isAndroid;

  static final instance = PermissionsService();

  final MethodChannel _channel;
  final bool _isAndroid;

  Future<PermissionSnapshot> status() => _read('status');
  Future<PermissionSnapshot> requestCallPermissions() => _read('requestCalls');
  Future<PermissionSnapshot> requestNotificationPermission() =>
      _read('requestNotifications');

  Future<bool> requestExactAlarms() async {
    if (!_isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('requestExactAlarms') ?? false;
    } on PlatformException catch (error) {
      throw PermissionsException(
        error.message?.isNotEmpty == true
            ? error.message!
            : 'No se pudo abrir el ajuste de alarmas exactas.',
      );
    } on MissingPluginException {
      throw const PermissionsException(
        'Este dispositivo no permite solicitar alarmas exactas.',
      );
    }
  }

  Future<void> openAppSettings() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openAppSettings');
    } on PlatformException {
      throw const PermissionsException(
        'No se pudieron abrir los ajustes de la aplicación.',
      );
    } on MissingPluginException {
      throw const PermissionsException(
        'Este dispositivo no permite abrir los ajustes de la aplicación.',
      );
    }
  }

  Future<PermissionSnapshot> _read(String method) async {
    if (!_isAndroid) return PermissionSnapshot.unrestricted;
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(method);
      return PermissionSnapshot(
        notifications: raw?['notifications'] == true,
        exactAlarms: raw?['exactAlarms'] == true,
        callLog: raw?['callLog'] == true,
        phoneState: raw?['phoneState'] == true,
      );
    } on PlatformException catch (error) {
      throw PermissionsException(
        error.message?.isNotEmpty == true
            ? error.message!
            : 'No se pudieron consultar los permisos del dispositivo.',
      );
    } on MissingPluginException {
      throw const PermissionsException(
        'No se pudieron consultar los permisos del dispositivo.',
      );
    }
  }
}
