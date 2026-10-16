import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Converts API instants to Cancun wall-clock time', () {
    final value = businessTimeFromInstant(
      DateTime.parse('2026-10-16T22:30:00.000Z'),
    );

    expect(value, DateTime(2026, 10, 16, 17, 30));
  });

  test(
    'Converts Cancun selections to UTC independently of device timezone',
    () {
      expect(
        businessTimeToUtcIso8601(DateTime(2026, 10, 16, 17, 30)),
        '2026-10-16T22:30:00.000Z',
      );
    },
  );
}
