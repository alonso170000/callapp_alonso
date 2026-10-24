import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/home_screen.dart';
import 'package:callerapp_frontend/services/notification_service.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('Profile data is read-only and logout works at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('Login destination')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.byIcon(Iconsax.profile_circle_copy));
      await tester.pumpAndSettle();
      expect(find.text('MI PERFIL'), findsOneWidget);
      expect(find.text('DATOS PERSONALES'), findsOneWidget);
      expect(find.byTooltip('Datos personales no editables'), findsNWidgets(4));
      final scrollable = find.descendant(
        of: find.byKey(const PageStorageKey('profile-scroll')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byTooltip('Cambiar notificaciones'),
        150,
        scrollable: scrollable,
      );
      await Scrollable.ensureVisible(
        tester.element(find.byTooltip('Cambiar notificaciones')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      final notificationsWereEnabled = NotificationService.instance.enabled;
      await tester.tap(find.byTooltip('Cambiar notificaciones'));
      await tester.pumpAndSettle();
      expect(
        find.text(notificationsWereEnabled ? 'DESACTIVADO' : 'ACTIVADO'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('CERRAR SESIÓN'),
        150,
        scrollable: scrollable,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('CERRAR SESIÓN')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('CERRAR SESIÓN'));
      await tester.pumpAndSettle();
      expect(find.text('Login destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
