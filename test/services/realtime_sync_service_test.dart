import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/data_change_bus.dart';
import 'package:callerapp_frontend/services/realtime_sync_service.dart';
import 'package:callerapp_frontend/services/session_store.dart';
import 'package:callerapp_frontend/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('solo notifica cuando cambia una versión ya conocida', () async {
    final auth = await _auth();
    final bus = DataChangeBus(debounce: Duration.zero);
    addTearDown(bus.dispose);
    var notifications = 0;
    bus.addListener(() => notifications++);
    final service = _FakeSyncService(['v1', 'v1', 'v2']);
    final realtime = RealtimeSyncService(
      service: service,
      auth: auth,
      changes: bus,
      interval: const Duration(days: 1),
    );
    addTearDown(realtime.dispose);

    await realtime.checkNow();
    await Future<void>.delayed(Duration.zero);
    expect(notifications, 0);
    await realtime.checkNow();
    await Future<void>.delayed(Duration.zero);
    expect(notifications, 0);
    await realtime.checkNow();
    await Future<void>.delayed(Duration.zero);
    expect(notifications, 1);
  });

  test('un error de sincronización no se propaga', () async {
    final realtime = RealtimeSyncService(
      service: _FakeSyncService(const [], fail: true),
      auth: await _auth(),
      changes: DataChangeBus(debounce: Duration.zero),
    );
    addTearDown(realtime.dispose);

    await realtime.checkNow();
  });
}

Future<AuthService> _auth() async {
  final store = MemorySessionStore()
    ..session = const StoredSession(
      token: 'token-prueba',
      userId: 1,
      activeDevelopment: {'id': 2},
    );
  final auth = AuthService(baseUrl: 'https://example.com', sessionStore: store);
  await auth.restoreSession();
  return auth;
}

class _FakeSyncService extends SyncService {
  _FakeSyncService(this.versions, {this.fail = false});
  final List<String> versions;
  final bool fail;
  int index = 0;

  @override
  Future<String> fetchVersion() async {
    if (fail) throw const SyncException('Sin conexión');
    return versions[index++];
  }

  @override
  void dispose() {}
}
