import 'package:callerapp_frontend/data/local/local_scope.dart';
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

  LocalScope get _scope {
    final userId = _auth.userId;
    final developmentId = _auth.developmentId;
    if (userId == null || developmentId == null) {
      throw const ProspectsException(
        'La sesión no identifica al usuario o desarrollo activo.',
      );
    }
    return LocalScope(userId: userId, developmentId: developmentId);
  }

  Future<List<ProspectRecord>> readCache() => _cache.read(_scope);

  Future<List<ProspectRecord>> refresh() async {
    final scope = _scope;
    final previous = await _cachedOrEmpty(scope);
    final prospects = await _service.fetch();
    try {
      await _cache.replace(scope, prospects);
    } catch (_) {
      // La API respondió correctamente; la caché es solo una optimización.
    }
    try {
      await NotificationService.instance.syncAssignedProspects(
        prospects,
        userId: scope.userId,
        developmentId: scope.developmentId,
        newlyVisibleProspectIds: newlyVisibleIds(previous, prospects),
        baseline: assignmentBaseline(previous),
      );
    } catch (_) {
      // Un fallo al registrar el aviso no debe impedir cargar los prospectos.
    }
    return prospects;
  }

  Future<List<ProspectRecord>> _cachedOrEmpty(LocalScope scope) async {
    try {
      return await _cache.read(scope);
    } catch (_) {
      return const [];
    }
  }

  /// Prospectos que aparecen por primera vez respecto a la caché anterior.
  static Set<int> newlyVisibleIds(
    List<ProspectRecord> previous,
    List<ProspectRecord> current,
  ) {
    final known = previous.map((prospect) => prospect.id).whereType<int>();
    final knownIds = known.toSet();
    return current
        .map((prospect) => prospect.id)
        .whereType<int>()
        .where((id) => !knownIds.contains(id))
        .toSet();
  }

  /// Fecha de asignación más reciente ya conocida. Devuelve `null` cuando no
  /// existe una caché previa y la sesión debe sembrarse sin avisos.
  static DateTime? assignmentBaseline(List<ProspectRecord> previous) {
    if (previous.isEmpty) return null;
    DateTime? latest;
    for (final prospect in previous) {
      final assignedAt = prospect.assignedAt;
      if (assignedAt != null &&
          (latest == null || assignedAt.isAfter(latest))) {
        latest = assignedAt;
      }
    }
    return latest ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  void dispose() {
    if (_ownsService) _service.dispose();
  }
}
