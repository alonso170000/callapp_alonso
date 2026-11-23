import 'package:callerapp_frontend/services/permissions_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('callerapp/permissions');

  PermissionsService service() =>
      PermissionsService(channel: channel, isAndroid: true);

  test('parsea los estados de los métodos nativos', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return {
            'notifications': true,
            'exactAlarms': false,
            'callLog': true,
            'phoneState': true,
          };
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    expect((await service().status()).notifications, isTrue);
    expect((await service().requestCallPermissions()).callsGranted, isTrue);
    expect(
      (await service().requestNotificationPermission()).exactAlarms,
      isFalse,
    );
    expect(calls, ['status', 'requestCalls', 'requestNotifications']);
  });

  test('convierte PlatformException en PermissionsException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(
            code: 'denied',
            message: 'No se pudo consultar el permiso.',
          ),
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await expectLater(
      service().status(),
      throwsA(
        isA<PermissionsException>().having(
          (error) => error.message,
          'message',
          'No se pudo consultar el permiso.',
        ),
      ),
    );
  });
}
