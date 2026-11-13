import 'package:callerapp_frontend/services/data_change_bus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agrupa cambios cercanos en una sola notificación', () async {
    final bus = DataChangeBus(debounce: const Duration(milliseconds: 5));
    addTearDown(bus.dispose);
    var notifications = 0;
    bus.addListener(() => notifications++);

    bus.notify(prospects: true);
    bus.notify(agenda: true);
    await Future<void>.delayed(const Duration(milliseconds: 15));

    expect(notifications, 1);
    expect(bus.revision, 1);
  });

  test('no emite cuando no se indica un dominio', () async {
    final bus = DataChangeBus(debounce: Duration.zero);
    addTearDown(bus.dispose);
    var notifications = 0;
    bus.addListener(() => notifications++);

    bus.notify();
    await Future<void>.delayed(Duration.zero);

    expect(notifications, 0);
    expect(bus.revision, 0);
  });
}
