import 'package:callerapp_frontend/services/phone_call_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'normalizes a phone number while preserving its international prefix',
    () {
      expect(
        PhoneCallService.normalizeNumber('+52 (998) 123-4567'),
        '+529981234567',
      );
    },
  );

  test('opens the external dialer with a normalized tel URI', () async {
    Uri? received;
    final service = PhoneCallService(
      canLaunch: (_) async => true,
      launch: (uri) async {
        received = uri;
        return true;
      },
    );

    await service.call('(998) 123 4567');

    expect(received, Uri(scheme: 'tel', path: '9981234567'));
  });

  test('rejects missing or short phone numbers', () async {
    final service = PhoneCallService();

    expect(
      () => service.call('123'),
      throwsA(
        isA<PhoneCallException>().having(
          (error) => error.message,
          'message',
          'El prospecto no tiene un teléfono válido para llamar.',
        ),
      ),
    );
  });

  test('reports when the dialer cannot be opened', () async {
    final service = PhoneCallService(canLaunch: (_) async => false);

    expect(
      () => service.call('9981234567'),
      throwsA(
        isA<PhoneCallException>().having(
          (error) => error.message,
          'message',
          'No se pudo abrir el marcador del teléfono.',
        ),
      ),
    );
  });

  test('maps platform launcher failures to a domain error', () async {
    final service = PhoneCallService(
      canLaunch: (_) async => throw Exception('plugin unavailable'),
    );

    expect(
      () => service.call('9981234567'),
      throwsA(
        isA<PhoneCallException>().having(
          (error) => error.message,
          'message',
          'No se pudo abrir el marcador del teléfono.',
        ),
      ),
    );
  });
}
