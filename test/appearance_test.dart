import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/appearance_controller.dart';
import 'package:callerapp_frontend/resources/styles/app_themes.dart';
import 'package:callerapp_frontend/presentation/widgets/profile/appearance_sheet.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/home_screen.dart';

void main() {
  Future<AuthService> auth() async {
    final auth = AuthService(
      baseUrl: 'https://example.com',
      client: MockClient(
        (_) async =>
            http.Response('{"status":"success","token":"session"}', 200),
      ),
    );
    await auth.login('ana', 'password');
    return auth;
  }

  http.Response response(String theme) => http.Response(
    jsonEncode({
      'success': true,
      'data': {'tema': theme},
    }),
    200,
  );
  test(
    'Loads account preference, saves only theme and resets on logout',
    () async {
      final session = await auth();
      var stored = 'oscuro';
      final controller = AppearanceController(
        auth: session,
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/preferences');
          expect(request.headers['Authorization'], 'Bearer session');
          if (request.method == 'PUT') {
            final body = jsonDecode(request.body) as Map;
            expect(body.keys.toList(), ['tema']);
            stored = body['tema'] as String;
          }
          return response(stored);
        }),
      );
      addTearDown(controller.dispose);
      await controller.reload();
      expect(controller.appearance, AppAppearance.dark);
      await controller.select(AppAppearance.light);
      expect(stored, 'claro');
      await controller.reload();
      expect(controller.appearance, AppAppearance.light);
      session.logout();
      expect(controller.appearance, AppAppearance.system);
    },
  );
  test('Failed save restores previous theme and reports error', () async {
    final controller = AppearanceController(
      auth: await auth(),
      client: MockClient(
        (request) async => request.method == 'PUT'
            ? http.Response('{}', 500)
            : response('claro'),
      ),
    );
    addTearDown(controller.dispose);
    await controller.reload();
    await expectLater(
      controller.select(AppAppearance.dark),
      throwsA(isA<AppearanceException>()),
    );
    expect(controller.appearance, AppAppearance.light);
    expect(controller.error, isNotNull);
    expect(controller.saving, isFalse);
  });
  test('Preference response from logged-out account is discarded', () async {
    final session = await auth();
    final pending = Completer<http.Response>();
    final controller = AppearanceController(
      auth: session,
      client: MockClient((_) => pending.future),
    );
    addTearDown(controller.dispose);
    final load = controller.reload();
    session.logout();
    pending.complete(response('oscuro'));
    await load;
    expect(controller.appearance, AppAppearance.system);
    expect(controller.loading, isFalse);
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('Home and Profile use readable dark surfaces at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.build(Brightness.dark),
          home: HomeScreen(
            loadActivities: () async => [],
            loadProspects: () async => [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final header = tester.widget<Text>(find.text('BIENVENIDO'));
      expect(header.style!.color, const Color(0xFF91E5D6));
      await tester.tap(find.bySemanticsLabel('Perfil').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.text('MI PERFIL')).style!.color,
        const Color(0xFF91E5D6),
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'Appearance switches immediately and system tracks device at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final controller = AppearanceController(
          auth: await auth(),
          client: MockClient(
            (request) async => response(
              request.method == 'PUT'
                  ? (jsonDecode(request.body) as Map)['tema'] as String
                  : 'sistema',
            ),
          ),
        );
        addTearDown(controller.dispose);
        await controller.reload();
        await tester.pumpWidget(
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => MaterialApp(
              theme: AppThemes.build(Brightness.light),
              darkTheme: AppThemes.build(Brightness.dark),
              themeMode: controller.appearance.mode,
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => AppearanceSheet(controller: controller),
                    ),
                    child: const Text('Cambiar'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Cambiar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Oscuro'));
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.text('Cambiar'))).brightness,
          Brightness.dark,
        );
        expect(
          Theme.of(tester.element(find.text('Cambiar'))).colorScheme.surface,
          const Color(0xFF112521),
        );
        await tester.tap(find.text('Cambiar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sistema'));
        await tester.pumpAndSettle();
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.text('Cambiar'))).brightness,
          Brightness.light,
        );
        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.text('Cambiar'))).brightness,
          Brightness.dark,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
