import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:callerapp_frontend/config/router/app_router.dart';
import 'package:callerapp_frontend/resources/styles/app_themes.dart';
import 'package:callerapp_frontend/services/appearance_controller.dart';
import 'package:callerapp_frontend/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    //.router hace que cambie su forma de navegacion a una mas moderna en su manejo automatico de rutas
    return ListenableBuilder(
      listenable: AppearanceController.instance,
      builder: (context, _) => MaterialApp.router(
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
