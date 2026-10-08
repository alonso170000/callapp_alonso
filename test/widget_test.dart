import 'package:callerapp_frontend/config/router/app_router.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:callerapp_frontend/main.dart';

void main() {
  testWidgets('Protected routes require a real authenticated session', (
    tester,
  ) async {
    AuthService.instance.logout();
    appRouter.go('/home');
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();
    expect(find.text('INICIA'), findsOneWidget);
    expect(find.text('BIENVENIDO'), findsNothing);

    await tester.ensureVisible(find.text('INGRESAR'));
    await tester.tap(find.text('INGRESAR'));
    await tester.pumpAndSettle();
    expect(find.text('INICIA'), findsOneWidget);
    expect(find.text('BIENVENIDO'), findsNothing);
    expect(find.text('El usuario es obligatorio.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
