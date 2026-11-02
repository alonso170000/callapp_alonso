import 'dart:convert';

import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/presentation/models/prospect_search.dart';
import 'package:callerapp_frontend/presentation/models/search_models.dart';
import 'package:callerapp_frontend/services/business_clock.dart';

/// Historial local de los últimos términos buscados.
///
/// Se guarda en `app_metadata` con una clave terminada en
/// `:<userId>:<developmentId>` para que el mantenimiento de 30 días lo purgue
/// junto con el resto del ámbito. No requiere migración de esquema.
class SearchHistoryStore {
  SearchHistoryStore({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  static const int maxEntries = 8;

  final AppDatabase _database;

  String _key(LocalScope scope) =>
      'search_history:${scope.userId}:${scope.developmentId}';

  /// Entradas del ámbito, de la más reciente a la más antigua.
  Future<List<RecentSearch>> read(LocalScope scope) async {
    try {
      final raw = await _database.readMetadata(_key(scope));
      final entries = _decode(raw);
      entries.sort((first, second) {
        final byDate = second.searchedAt.compareTo(first.searchedAt);
        if (byDate != 0) return byDate;
        return ProspectSearch.normalize(first.query)
            .compareTo(ProspectSearch.normalize(second.query));
      });
      return entries;
    } on Object {
      return const [];
    }
  }

  /// Agrega o actualiza un término y devuelve el historial resultante.
  ///
  /// La deduplicación ignora mayúsculas y acentos. Si la entrada nueva no
  /// trae prospecto asociado, se conserva el que ya estaba guardado para el
  /// mismo término. El historial nunca supera [maxEntries].
  Future<List<RecentSearch>> add(LocalScope scope, RecentSearch entry) async {
    final query = entry.query.trim();
    if (query.isEmpty) return read(scope);

    final normalizedQuery = ProspectSearch.normalize(query);
    final current = await read(scope);
    RecentSearch? previous;
    for (final item in current) {
      if (ProspectSearch.normalize(item.query) == normalizedQuery) {
        previous = item;
        break;
      }
    }

    final updated = <RecentSearch>[
      RecentSearch(
        query: query,
        prospectId: entry.prospectId ?? previous?.prospectId,
        prospectName: entry.prospectName ?? previous?.prospectName,
        searchedAt: entry.searchedAt,
      ),
      for (final item in current)
        if (ProspectSearch.normalize(item.query) != normalizedQuery) item,
    ];
    if (updated.length > maxEntries) {
      updated.removeRange(maxEntries, updated.length);
    }
    await _write(scope, updated);
    return List.unmodifiable(updated);
  }

  /// Elimina un término del historial sin distinguir mayúsculas ni acentos.
  Future<List<RecentSearch>> remove(LocalScope scope, String query) async {
    final normalizedQuery = ProspectSearch.normalize(query);
    final current = await read(scope);
    final updated = current
        .where(
          (item) => ProspectSearch.normalize(item.query) != normalizedQuery,
        )
        .toList();
    await _write(scope, updated);
    return List.unmodifiable(updated);
  }

  /// Borra todo el historial del ámbito.
  Future<void> clear(LocalScope scope) async {
    try {
      await _database.writeMetadata(_key(scope), '[]');
    } on Object {
      // El historial no debe bloquear la pantalla ni provocar errores visibles.
    }
  }

  Future<void> _write(LocalScope scope, List<RecentSearch> entries) async {
    try {
      await _database.writeMetadata(
        _key(scope),
        jsonEncode([for (final entry in entries) _toJson(entry)]),
      );
    } on Object {
      // La búsqueda sigue funcionando aunque el almacenamiento local falle.
    }
  }

  List<RecentSearch> _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final entries = <RecentSearch>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final entry = _fromJson(item);
        if (entry != null) entries.add(entry);
      }
      return entries;
    } on FormatException {
      return [];
    } on Object {
      return [];
    }
  }

  Map<String, Object?> _toJson(RecentSearch entry) => {
    'query': entry.query,
    'prospect_id': entry.prospectId,
    'prospect_name': entry.prospectName,
    'searched_at_ms': entry.searchedAt.millisecondsSinceEpoch,
  };

  RecentSearch? _fromJson(Map<dynamic, dynamic> item) {
    final query = item['query'];
    if (query is! String || query.trim().isEmpty) return null;

    final timestamp = item['searched_at_ms'];
    final searchedAt = timestamp is int
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : businessNow();
    final prospectId = item['prospect_id'];
    final prospectName = item['prospect_name'];

    return RecentSearch(
      query: query,
      prospectId: prospectId is int ? prospectId : null,
      prospectName: prospectName is String && prospectName.trim().isNotEmpty
          ? prospectName
          : null,
      searchedAt: searchedAt,
    );
  }
}
