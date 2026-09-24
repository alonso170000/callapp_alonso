//go_conter sirve para navegar la navecion de la app
import 'package:go_router/go_router.dart';
import 'package:callerapp_frontend/presentation/screens/screens.dart';

// usar go_router nos ayuda a nosotros no tengamos que hacer configuraciones especiales si queremos usarlo en la web
// creamos la configuracion global del router y esto define como navegamos entre pantallas
final appRouter = GoRouter(
  initialLocation: '/',

  // errorBuilder: (context, state) =>
  //     NotFoundScreen(onGoHome: () => context.go('/')),
  routes: [
    // GoRoute(
    //   //url de la ruta
    //   path: '/',
    //   //nombre de la ruta (util para la nevegacion por nombre)
    //   name: SplashScreen.name,
    //   //es el widget que se mostrara cuando entremos en esta ruta
    //   builder: (context, state) => SplashScreen(),
    // ),
    GoRoute(
      //url de la ruta
      path: '/',
      //nombre de la ruta (util para la nevegacion por nombre)
      name: LoginScreen.name,
      //es el widget que se mostrara cuando entremos en esta ruta
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      name: HomeScreen.name,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
