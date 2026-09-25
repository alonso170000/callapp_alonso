import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospect_detail_screen.dart';
//go_conter sirve para navegar la navecion de la app
import 'package:go_router/go_router.dart';
import 'package:callerapp_frontend/presentation/screens/auth/login_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/home_screen.dart';

// usar go_router nos ayuda a nosotros no tengamos que hacer configuraciones especiales si queremos usarlo en la web
// creamos la configuracion global del router y esto define como navegamos entre pantallas
final appRouter = GoRouter(
  initialLocation: '/home',

  // errorBuilder: (context, state) =>
  //     NotFoundScreen(onGoHome: () => context.go('/')),
  routes: [
    GoRoute(
      path: '/prospectos/:phone',
      builder: (context, state) {
        final matches = demoProspects.where(
          (p) => p.phone == state.pathParameters['phone'],
        );
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Prospecto')),
            body: const Center(child: Text('Prospecto no encontrado')),
          );
        }
        return ProspectDetailScreen(prospect: matches.first);
      },
    ),
    GoRoute(
      path: '/login',
      name: LoginScreen.name,
      builder: (context, state) => const LoginScreen(),
    ),
    // GoRoute(
    //   //url de la ruta
    //   path: '/',
    //   //nombre de la ruta (util para la nevegacion por nombre)
    //   name: SplashScreen.name,
    //   //es el widget que se mostrara cuando entremos en esta ruta
    //   builder: (context, state) => SplashScreen(),
    // ),

    // GoRoute(
    //   //url de la ruta
    //   path: '/',
    //   //nombre de la ruta (util para la nevegacion por nombre)
    //   name: LoginScreen.name,
    //   //es el widget que se mostrara cuando entremos en esta ruta
    //   builder: (context, state) => const LoginScreen(),
    // ),
    GoRoute(
      path: '/home',
      name: HomeScreen.name,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
