import 'package:callerapp_frontend/data/local/prospects_cache.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/services/notification_service.dart';

class ProspectsRepository {
  ProspectsRepository({
    ProspectsService? service,
    ProspectsCache? cache,
    AuthService? auth,
  }) : _service = service ?? ProspectsService(auth: auth),
       _ownsService = service == null,
       _cache = cache ?? ProspectsCache(),
       _auth = auth ?? AuthService.instance;

  final ProspectsService _service;
  final bool _ownsService;
  final ProspectsCache _cache;
  final AuthService _auth;

  ProspectCacheScope get _scope {
    final userId = _auth.userId;
    final developmentId = _auth.developmentId;
    if (userId == null || developmentId == null) {
      throw const ProspectsException(
        'La sesión no identifica al usuario o desarrollo activo.',
      );
    }
    return ProspectCacheScope(userId: userId, developmentId: developmentId);
  }

  Future<List<ProspectRecord>> readCache() => _cache.read(_scope);

  Future<List<ProspectRecord>> refresh() async {
    final scope = _scope;
    final prospects = await _service.fetch();
    await _cache.replace(scope, prospects);
    await NotificationService.instance.syncAssignedProspects(
      prospects,
      userId: scope.userId,
      developmentId: scope.developmentId,
    );
    return prospects;
  }

  void dispose() {
    if (_ownsService) _service.dispose();
  }
}
