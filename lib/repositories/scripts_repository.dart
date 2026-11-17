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
  LocalScope get scope {
    final userId = _auth.userId ?? _service.userId;
    final developmentId = _auth.developmentId ?? _service.developmentId;
    if (userId == null || developmentId == null) {
      throw const ScriptsSessionException(
        'La sesión no identifica al usuario o desarrollo activo.',
      );
    }
    return LocalScope(userId: userId, developmentId: developmentId);
  }

  Future<GuionesBundle?> readCache() => _cache.read(scope);
  Future<GuionesBundle> refresh({String? tipoProspecto}) async {
    final bundle = await _service.fetch(tipoProspecto: tipoProspecto);
    await _cache.write(scope, bundle);
    return bundle;
  }

  void dispose() {
    if (_ownsService) _service.dispose();
  }
}
