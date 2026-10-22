class ProspectCatalogs {
  const ProspectCatalogs({
    this.origins = const [],
    this.statuses = const [],
    this.lots = const [],
  });

  final List<Map<String, dynamic>> origins;
  final List<Map<String, dynamic>> statuses;
  final List<Map<String, dynamic>> lots;

  bool get canCreate => origins.isNotEmpty;
}
