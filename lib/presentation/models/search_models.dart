import 'package:callerapp_frontend/presentation/models/prospect_models.dart';

/// Término buscado recientemente en el buscador global.
///
/// Si el usuario abrió un prospecto desde el resultado, se guarda también su
/// identificador y nombre para poder ofrecerlo como acceso directo.
class RecentSearch {
  const RecentSearch({
    required this.query,
    required this.searchedAt,
    this.prospectId,
    this.prospectName,
  });

  final String query;
  final int? prospectId;
  final String? prospectName;
  final DateTime searchedAt;
}

/// Datos que necesita la pantalla del buscador para pintar su estado inicial
/// y sus resultados sin conocer la caché ni el historial.
class SearchSnapshot {
  const SearchSnapshot({
    required this.prospects,
    required this.recentSearches,
    this.cachedAt,
  });

  final List<ProspectRecord> prospects;
  final List<RecentSearch> recentSearches;
  final DateTime? cachedAt;
}
