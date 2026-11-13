import 'dart:async';

import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/data_change_bus.dart';
import 'package:callerapp_frontend/services/sync_service.dart';
import 'package:flutter/widgets.dart';

class RealtimeSyncService with WidgetsBindingObserver {
  RealtimeSyncService({
    SyncService? service,
    AuthService? auth,
    DataChangeBus? changes,
    this.interval = const Duration(seconds: 20),
  }) : _service = service ?? SyncService(auth: auth),
       _auth = auth ?? AuthService.instance,
       _changes = changes ?? DataChangeBus.instance;

  static final instance = RealtimeSyncService();

  final SyncService _service;
  final AuthService _auth;
  final DataChangeBus _changes;
  final Duration interval;
  Timer? _timer;
  String? _lastVersion;
  bool _started = false;
  bool _checking = false;
  bool _foreground = true;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _auth.addListener(_authChanged);
    _schedule();
    await checkNow();
  }

  Future<void> checkNow() async {
    if (_checking || !_foreground || !_auth.isAuthenticated) return;
    _checking = true;
    try {
      final version = await _service.fetchVersion();
      final previous = _lastVersion;
      _lastVersion = version;
      if (previous != null && previous != version) {
        _changes.notify(prospects: true, agenda: true);
      }
    } on SyncException {
      // La comprobación es oportunista; la app conserva sus datos locales.
    } finally {
      _checking = false;
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (!_foreground || !_auth.isAuthenticated) return;
    _timer = Timer.periodic(interval, (_) => unawaited(checkNow()));
  }

  void _authChanged() {
    if (!_auth.isAuthenticated) {
      _lastVersion = null;
      _timer?.cancel();
      return;
    }
    _schedule();
    unawaited(checkNow());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _schedule();
      unawaited(checkNow());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      _timer?.cancel();
    }
  }

  void dispose() {
    _timer?.cancel();
    _auth.removeListener(_authChanged);
    WidgetsBinding.instance.removeObserver(this);
    _service.dispose();
  }
}
