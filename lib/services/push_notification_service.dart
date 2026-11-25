import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:callerapp_frontend/presentation/models/notification_models.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/data_change_bus.dart';
import 'package:callerapp_frontend/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class PushNotificationService {
  PushNotificationService._() {
    AuthService.instance.addListener(_authChanged);
  }

  static final instance = PushNotificationService._();

  bool _initialized = false;
  bool _registering = false;
  String? _token;

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    if (_initialized) {
      final token = _token;
      if (token != null) await _registerToken(token);
      return;
    }
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      FirebaseMessaging.onMessage.listen(_onMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);
      messaging.onRegistered.listen((token) {
        _token = token;
        unawaited(_registerToken(token));
      });
      final initial = await messaging.getInitialMessage();
      if (initial != null) _openMessage(initial);
      await messaging.register();
      _initialized = true;
    } catch (_) {
      // Firebase es opcional: las notificaciones locales siguen disponibles.
    }
  }

  void _authChanged() {
    if (AuthService.instance.isAuthenticated) {
      unawaited(initialize());
    }
  }

  Future<void> _onMessage(RemoteMessage message) async {
    final prospectId = int.tryParse(message.data['prospect_id'] ?? '');
    if (prospectId == null) return;
    await NotificationService.instance.showPushAssignment(
      prospectId: prospectId,
      title: message.notification?.title ?? 'Nuevo prospecto asignado',
      body: message.notification?.body ?? 'Tienes un nuevo prospecto.',
    );
    DataChangeBus.instance.notify(prospects: true, agenda: true);
  }

  void _openMessage(RemoteMessage message) {
    final prospectId = int.tryParse(message.data['prospect_id'] ?? '');
    if (prospectId == null) return;
    NotificationService.instance.pendingTarget.value = NotificationTarget(
      type: NotificationTargetType.prospect,
      id: prospectId,
    );
  }

  Future<void> _registerToken(String token) async {
    final auth = AuthService.instance;
    if (_registering || auth.token == null || auth.developmentId == null) {
      return;
    }
    _registering = true;
    try {
      await http.post(
        Uri.parse('${auth.baseUrl}/api/v1/notifications/devices'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': token, 'plataforma': 'android'}),
      );
    } catch (_) {
      // El próximo refresh de token o login vuelve a intentarlo.
    } finally {
      _registering = false;
    }
  }

  Future<void> unregisterCurrent() async {
    final auth = AuthService.instance;
    final token = _token;
    if (token == null || auth.token == null) return;
    try {
      await http.delete(
        Uri.parse('${auth.baseUrl}/api/v1/notifications/devices'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': token}),
      );
      await FirebaseMessaging.instance.unregister();
      _token = null;
    } catch (_) {}
  }
}
