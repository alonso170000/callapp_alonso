import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:callerapp_frontend/config/router/app_router.dart';
import 'package:callerapp_frontend/resources/styles/app_themes.dart';
import 'package:callerapp_frontend/services/appearance_controller.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/local_maintenance_service.dart';
import 'package:callerapp_frontend/services/notification_service.dart';
import 'package:callerapp_frontend/services/onboarding_controller.dart';
import 'package:callerapp_frontend/services/outbox_service.dart';
import 'package:callerapp_frontend/services/realtime_sync_service.dart';
import 'package:callerapp_frontend/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {
    // La app conserva las notificaciones locales si Firebase no está configurado.
  }
  await AuthService.instance.restoreSession();
  await OnboardingController.instance.load();
  await NotificationService.instance.initialize();
  unawaited(PushNotificationService.instance.initialize());
  unawaited(OutboxService.instance.initialize());
  unawaited(RealtimeSyncService.instance.start());
  unawaited(LocalMaintenanceService.instance.runIfDue());

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppearanceController.instance,
      builder: (context, _) => MaterialApp.router(
        title: 'CallApp',
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        locale: const Locale('es', 'MX'),
        supportedLocales: const [Locale('es', 'MX')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppThemes.build(Brightness.light),
        darkTheme: AppThemes.build(Brightness.dark),
        themeMode: AppearanceController.instance.appearance.mode,
      ),
    );
  }
}
