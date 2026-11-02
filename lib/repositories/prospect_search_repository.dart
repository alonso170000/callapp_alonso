import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/search_history_store.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/search_models.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/business_clock.dart';

/// Une la caché de prospectos con el historial de búsquedas.
///
/// La pantalla recibe un solo objeto y no necesita conocer ni la base local ni
/// el servicio remoto. La lectura inicial es local; el refresco remoto queda
/// en manos de la pantalla para que la búsqueda nunca espere a la red.
class ProspectSearchRepository {
  ProspectSearchRepository({
    ProspectsRepository? repository,
    SearchHistoryStore? history,
    AuthService? auth,
  }) : _prospects = repository ?? ProspectsRepository(auth: auth),
       _ownsProspects = repository == null,
       _history = history ?? SearchHistoryStore();

  /// Tiempo máximo que se reutiliza la caché antes de intentar refrescarla.
  static const refreshInterval = Duration(minutes: 10);

  final ProspectsRepository _prospects;
  final bool _ownsProspects;
  final SearchHistoryStore _history;

  LocalScope get scope => _prospects.scope;

  /// Lee la caché y el historial sin tocar la red.
  Future<SearchSnapshot> load() async {
    final currentScope = scope;
    return SearchSnapshot(
      prospects: await _readCache(),
      recentSearches: await _history.read(currentScope),
      cachedAt: await _cachedAt(),
    );
  }

  /// Consulta el backend, actualiza la caché y devuelve también el historial.
  ///
  /// Las excepciones de [ProspectsRepository] se propagan para que la pantalla
  /// decida si muestra un aviso o conserva los resultados guardados.
  Future<SearchSnapshot> refresh() async {
    final currentScope = scope;
    final prospects = await _prospects.refresh();
    return SearchSnapshot(
      prospects: prospects,
      recentSearches: await _history.read(currentScope),
      cachedAt: businessNow(),
    );
  }

  /// `true` si la caché es tan antigua que conviene refrescarla en segundo plano.
  bool isRefreshDue(SearchSnapshot snapshot, {DateTime? now}) {
    final cachedAt = snapshot.cachedAt;
    if (cachedAt == null) return true;
    return (now ?? businessNow()).difference(cachedAt) >= refreshInterval;
  }

  /// Guarda el término como reciente y devuelve el historial actualizado.
  Future<List<RecentSearch>> rememberQuery(
    String query, {
    ProspectRecord? prospect,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return _history.read(scope);
    return _history.add(
      scope,
      RecentSearch(
        query: trimmed,
        prospectId: prospect?.id,
        prospectName: prospect?.name,
        searchedAt: businessNow(),
      ),
    );
  }

  Future<List<RecentSearch>> removeQuery(String query) =>
      _history.remove(scope, query);

  Future<void> clearHistory() => _history.clear(scope);

  Future<List<ProspectRecord>> _readCache() async {
    try {
      return await _prospects.readCache();
    } on Object {
      return const [];
    }
  }

  Future<DateTime?> _cachedAt() async {
    try {
      return await _prospects.cachedAt();
    } on Object {
      return null;
    }
  }

  void dispose() {
    if (_ownsProspects) _prospects.dispose();
  }
}
