import 'package:callerapp_frontend/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:callerapp_frontend/services/cube_acr_audio_service.dart';
import 'package:callerapp_frontend/services/onboarding_controller.dart';
import 'package:callerapp_frontend/services/permissions_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePermissionsService extends PermissionsService {
  _FakePermissionsService() : super(isAndroid: false);

  PermissionSnapshot snapshot = const PermissionSnapshot(
    notifications: false,
    exactAlarms: false,
    callLog: false,
    phoneState: false,
  );

  @override
  Future<PermissionSnapshot> status() async => snapshot;

  @override
  Future<PermissionSnapshot> requestNotificationPermission() async {
    snapshot = PermissionSnapshot(
      notifications: true,
      exactAlarms: snapshot.exactAlarms,
      callLog: snapshot.callLog,
      phoneState: snapshot.phoneState,
    );
    return snapshot;
  }

  @override
  Future<PermissionSnapshot> requestCallPermissions() async {
    snapshot = PermissionSnapshot(
      notifications: snapshot.notifications,
      exactAlarms: snapshot.exactAlarms,
      callLog: true,
      phoneState: true,
    );
    return snapshot;
  }

  @override
  Future<bool> requestExactAlarms() async {
    snapshot = PermissionSnapshot(
      notifications: snapshot.notifications,
      exactAlarms: true,
      callLog: snapshot.callLog,
      phoneState: snapshot.phoneState,
    );
    return true;
  }

  @override
  Future<void> openAppSettings() async {}
}

class _FakeCubeAcrAudioService extends CubeAcrAudioService {
  String? name;

  @override
  Future<String?> folderName() async => name;

  @override
  Future<String?> linkFolder() async {
    name = 'Cube ACR';
    return name;
  }
}

class _FakeOnboardingController extends OnboardingController {
  _FakeOnboardingController() : super(isAndroid: false);
  int completions = 0;

  @override
  Future<void> complete() async {
    completions++;
  }
}

void main() {
  Future<
    (
      _FakePermissionsService,
      _FakeCubeAcrAudioService,
      _FakeOnboardingController,
    )
  >
  pumpScreen(WidgetTester tester, double width) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final permissions = _FakePermissionsService();
    final audio = _FakeCubeAcrAudioService();
    final controller = _FakeOnboardingController();
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          permissionsService: permissions,
          audioService: audio,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (permissions, audio, controller);
  }

  for (final width in [320.0, 390.0]) {
    testWidgets('muestra bienvenida sin opción de omitir a $width px', (
      tester,
    ) async {
      await pumpScreen(tester, width);
      expect(find.text('BIENVENIDO A CALLAPP'), findsOneWidget);
      expect(find.text('OMITIR POR AHORA'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('bloquea el avance hasta conceder todos los permisos', (
    tester,
  ) async {
    final (_, _, controller) = await pumpScreen(tester, 390);
    await tester.tap(find.text('COMENZAR'));
    await tester.pumpAndSettle();
    expect(find.text('NOTIFICACIONES'), findsOneWidget);
    expect(find.text('LLAMADAS'), findsOneWidget);
    expect(find.text('ALARMAS EXACTAS'), findsOneWidget);
    expect(find.text('OMITIR POR AHORA'), findsNothing);

    FilledButton continueButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'CONTINUAR'),
    );
    expect(continueButton().onPressed, isNull);

    await tester.tap(find.text('PERMITIR').first);
    await tester.pumpAndSettle();
    expect(find.text('PERMITIDO'), findsOneWidget);
    expect(continueButton().onPressed, isNull);

    await tester.tap(find.text('PERMITIR').first);
    await tester.pumpAndSettle();
    expect(find.text('PERMITIDO'), findsNWidgets(2));
    expect(continueButton().onPressed, isNull);

    await tester.tap(find.text('PERMITIR').first);
    await tester.pumpAndSettle();
    expect(find.text('PERMITIDO'), findsNWidgets(3));
    expect(continueButton().onPressed, isNotNull);

    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(find.text('OMITIR POR AHORA'), findsNothing);
    await tester.tap(find.text('VINCULAR CARPETA'));
    await tester.pumpAndSettle();
    expect(find.text('Cube ACR'), findsOneWidget);
    await tester.tap(find.text('FINALIZAR'));
    await tester.pumpAndSettle();
    expect(controller.completions, 1);
    expect(tester.takeException(), isNull);
  });
}
