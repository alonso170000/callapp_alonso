import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/screens/screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    //.router hace que cambie su forma de navegacion a una mas moderna en su manejo automatico de rutas
    return MaterialApp.router(
      routerConfig: appRouter, //sistema de rutas que utilizaremos
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: AppColors.backgroundColor,
      ),
    );
  }
}