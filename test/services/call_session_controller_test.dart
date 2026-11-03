import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/services/call_log_service.dart';
import 'package:callerapp_frontend/services/call_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCallLogService extends CallLogService {
  _FakeCallLogService({this.match, this.active});

  CallLogMatch? match;
  bool? active;
  DateTime? lastWindowStart;
  int lookups = 0;

  @override
  Future<CallLogMatch?> latestFor(String phone, DateTime startedAt) async {
    lookups++;
    lastWindowStart = startedAt;
    return match;
  }

  @override
  Future<bool?> isCallActive() async => active;
}

Future<CallSessionController> _startSession(_FakeCallLogService log) async {
  final controller = CallSessionController(callLog: log);
  addTearDown(controller.dispose);
  await controller.start(
    prospect: demoProspects.first,
    origin: 'detalle',
    startedAt: businessNow(),
  );
  return controller;
}

void main() {
  test('descarta la sesión cuando solo se abrió el marcador', () async {
    final log = _FakeCallLogService(active: false);
    final controller = await _startSession(log);

    expect(controller.hasUnverifiedCall, isTrue);

    final resolution = await controller.resolveAfterDialer(attempts: 1);

    expect(resolution, PendingCallResolution.discarded);
    expect(controller.activeCall, isNull);
    expect(controller.hasUnverifiedCall, isFalse);
  });

  test('la ventana de búsqueda usa el instante real, no la hora de negocio', () async {
    final log = _FakeCallLogService(active: false);
    final before = DateTime.now().millisecondsSinceEpoch;
    final controller = await _startSession(log);

    await controller.latestLog();

    final window = log.lastWindowStart;
    expect(window, isNotNull);
    expect(
      window!.millisecondsSinceEpoch,
      greaterThanOrEqualTo(before - 2000),
    );
    expect(
      window.difference(DateTime.now()).inSeconds.abs(),
      lessThanOrEqualTo(2),
    );
  });

  test('conserva la sesión cuando aparece una llamada nueva', () async {
    final log = _FakeCallLogService(
      match: CallLogMatch(
        durationSeconds: 42,
        id: '9001',
        startedAt: DateTime.now(),
      ),
    );
    final controller = await _startSession(log);

    final resolution = await controller.resolveAfterDialer(attempts: 1);

    expect(resolution, PendingCallResolution.verified);
    expect(controller.activeCall?.verified, isTrue);
    expect(controller.activeCall?.callLogId, '9001');
    expect(log.lookups, greaterThan(0));
  });

  test('conserva la sesión cuando el teléfono reporta una llamada activa', () async {
    final log = _FakeCallLogService(active: true);
    final controller = await _startSession(log);

    final resolution = await controller.resolveAfterDialer(attempts: 1);

    expect(resolution, PendingCallResolution.inProgress);
    expect(controller.activeCall?.verified, isTrue);
  });

  test('conserva la sesión si no se puede verificar la llamada', () async {
    final log = _FakeCallLogService(active: null);
    final controller = await _startSession(log);

    final resolution = await controller.resolveAfterDialer(attempts: 1);

    expect(resolution, PendingCallResolution.unverifiable);
    expect(controller.activeCall?.verified, isTrue);
  });

  test('ignora registros anteriores a la ventana de la llamada', () async {
    final log = _FakeCallLogService(active: false);
    final controller = await _startSession(log);
    log.match = CallLogMatch(
      durationSeconds: 60,
      id: 'vieja',
      startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    );

    expect(await controller.claimCompletedCall(attempts: 1), isFalse);
  });

  test('acepta el registro posterior a la ventana de la llamada', () async {
    final log = _FakeCallLogService(active: false);
    final controller = await _startSession(log);
    log.match = CallLogMatch(
      durationSeconds: 60,
      id: 'nueva',
      startedAt: DateTime.now(),
    );

    expect(await controller.claimCompletedCall(attempts: 1), isTrue);
  });
}
