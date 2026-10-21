import 'dart:async';

import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';

/// Consulta periódicamente los prospectos del vendedor para avisarle cuando
/// el backend le asigne uno nuevo.
class ProspectAssignmentController {
  ProspectAssignmentController({
    ProspectsRepository? repository,
    AuthService? auth,
    this.interval = const Duration(seconds: 30),
  }) : _repository = repository ?? ProspectsRepository(auth: auth),
       _ownsRepository = repository == null,
       _auth = auth ?? AuthService.instance;

  final ProspectsRepository _repository;
  final bool _ownsRepository;
  final AuthService _auth;
  final Duration interval;

  Timer? _timer;
  bool _checking = false;
  String? _lastError;

  String? get lastError => _lastError;

  /// Arranca el chequeo inmediato y programa las siguientes consultas.
  void start() {
    if (_timer != null) return;
    unawaited(check());
    _timer = Timer.periodic(interval, (_) => unawaited(check()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Consulta los prospectos y deja que el repositorio detecte las altas.
  Future<void> check() async {
    if (_checking) return;
    if (_auth.userId == null || _auth.developmentId == null) return;
    _checking = true;
    try {
      await _repository.refresh();
      _lastError = null;
    } on ProspectsException catch (error) {
      _lastError = error.message;
    } catch (_) {
      _lastError = 'No se pudieron sincronizar los prospectos asignados.';
    } finally {
      _checking = false;
    }
  }

  void dispose() {
    stop();
    if (_ownsRepository) _repository.dispose();
  }
}
