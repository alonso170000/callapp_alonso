import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/scripts_cache.dart';
import 'package:callerapp_frontend/presentation/models/guion_models.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/scripts_service.dart';

class ScriptsRepository {
  ScriptsRepository({
    ScriptsService? service,
    ScriptsCache? cache,
    AuthService? auth,
  }) : _service = service ?? ScriptsService(auth: auth),
       _ownsService = service == null,
       _cache = cache ?? ScriptsCache(),
       _auth = auth ?? AuthService.instance;
  final ScriptsService _service;
  final bool _ownsService;
  final ScriptsCache _cache;
  final AuthService _auth;
  LocalScope scope(int developmentId) {
    final userId = _auth.userId ?? _service.userId;
    if (userId == null) {
      throw const ScriptsSessionException(
        'La sesión no identifica al usuario.',
      );
    }
    return LocalScope(userId: userId, developmentId: developmentId);
  }

  Future<GuionesBundle?> readCache({
    required int developmentId,
    String? tipoProspecto,
  }) => _cache.read(scope(developmentId), tipoProspecto: tipoProspecto);
  Future<GuionesBundle> refresh({
    required int developmentId,
    String? tipoProspecto,
  }) async {
    final bundle = await _service.fetch(
      developmentId: developmentId,
      tipoProspecto: tipoProspecto,
    );
    await _cache.write(
      scope(developmentId),
      bundle,
      tipoProspecto: tipoProspecto,
    );
    return bundle;
  }

  void dispose() {
    if (_ownsService) _service.dispose();
  }
}
