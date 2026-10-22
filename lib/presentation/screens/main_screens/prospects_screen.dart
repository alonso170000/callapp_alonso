import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/new_prospect_sheet.dart';
import 'package:callerapp_frontend/presentation/models/prospect_filters.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_card.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/widgets/home/home_dashboard_widgets.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';

class ProspectsController {
  void Function(Set<int>, String)? _show;
  void showFromHome(Set<int> ids, String label) => _show?.call(ids, label);
  VoidCallback? _open;
  void Function(int)? _openProspect;
  VoidCallback? _refresh;
  void openNewProspect() => _open?.call();
  void openProspect(int prospectId) => _openProspect?.call(prospectId);
  void refresh() => _refresh?.call();
  void dispose() {
    _open = null;
    _show = null;
    _openProspect = null;
    _refresh = null;
  }
}

class ProspectsScreen extends StatefulWidget {
  final ProspectsController? controller;
  final Future<List<ProspectRecord>> Function()? loadProspects;
  final ValueChanged<AgendaActivity>? onNotificationActivity;
  const ProspectsScreen({
    super.key,
    this.controller,
    this.loadProspects,
    this.onNotificationActivity,
  });

  @override
  State<ProspectsScreen> createState() => _ProspectsScreenState();
}

class _ProspectsScreenState extends State<ProspectsScreen> {
  final _records = <ProspectRecord>[];
  final _repository = ProspectsRepository();
  bool _loading = false;
  String? _error;
  int _request = 0;

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.loadProspects != null) {
        final records = await widget.loadProspects!.call();
        if (!mounted || request != _request) return;
        setState(() {
          _records.clear();
          _records.addAll(records);
        });
        return;
      }

      var hasCachedRecords = false;
      try {
        final cached = await _repository.readCache();
        if (!mounted || request != _request) return;
        if (cached.isNotEmpty) {
          hasCachedRecords = true;
          setState(() {
            _records.clear();
            _records.addAll(cached);
          });
        }
      } catch (_) {
        // Una caché dañada o no disponible no debe impedir la consulta remota.
      }

      try {
        final records = await _repository.refresh();
        if (!mounted || request != _request) return;
        setState(() {
          _records.clear();
          _records.addAll(records);
          _error = null;
        });
      } on ProspectsException catch (error) {
        if (!mounted || request != _request) return;
        setState(() {
          _error = hasCachedRecords
              ? 'Mostrando datos guardados. ${error.message}'
              : error.message;
        });
      }
    } on ProspectsException catch (error) {
      if (mounted && request == _request) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  void _sessionChanged() {
    ++_request;
    _records.clear();
    _search.clear();
    _status = 'Todos';
    _advanced = ProspectFilters.forSeller();
    _load();
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._open = _addProspect;
    widget.controller?._show = _showFromHome;
    widget.controller?._openProspect = _openProspectById;
    widget.controller?._refresh = _load;
    AuthService.instance.addListener(_sessionChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant ProspectsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._open = null;
      oldWidget.controller?._show = null;
      oldWidget.controller?._openProspect = null;
      oldWidget.controller?._refresh = null;
      widget.controller?._open = _addProspect;
      widget.controller?._show = _showFromHome;
      widget.controller?._openProspect = _openProspectById;
      widget.controller?._refresh = _load;
    }
  }

  void _showFromHome(Set<int> ids, String label) {
    setState(() {
      _search.clear();
      _status = 'Todos';
      _advanced = ProspectFilters(
        prospectIds: ids,
        sourceLabel: label,
        sort: 'Asignación más reciente',
      );
    });
    _load();
  }

  Future<void> _openProspectById(int prospectId) async {
    var index = _records.indexWhere((record) => record.id == prospectId);
    if (index == -1) {
      await _load();
      if (!mounted) return;
      index = _records.indexWhere((record) => record.id == prospectId);
    }
    if (index == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El prospecto ya no está disponible.')),
      );
      return;
    }
    final prospect = _records[index];
    context.push(
      '/prospectos/${Uri.encodeComponent(prospect.phone.isEmpty ? 'id-${prospect.id}' : prospect.phone)}',
      extra: prospect,
    );
  }

  Future<void> _addProspect() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => NewProspectSheet(repository: _repository),
    );
    if (!mounted || created != true) return;
    setState(() {
      _search.clear();
      _status = 'Todos';
      _advanced = ProspectFilters.forSeller();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prospecto registrado correctamente.')),
    );
    await _load();
  }

  static const _filters = [
    'Todos',
    'Atrasados',
    'Nuevo',
    'Contactado y validado',
    'Seguimiento',
    'Cotización',
    'Negociación',
    'Venta realizada',
  ];
  final _search = TextEditingController();
  String _status = 'Todos';
  ProspectFilters _advanced = ProspectFilters.forSeller();

  @override
  void dispose() {
    widget.controller?._open = null;
    widget.controller?._show = null;
    widget.controller?._openProspect = null;
    widget.controller?._refresh = null;
    _search.dispose();
    AuthService.instance.removeListener(_sessionChanged);
    _repository.dispose();
    super.dispose();
  }

  String _normalize(String value) {
    var result = value.toLowerCase();
    const accents = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u'};
    accents.forEach((key, value) => result = result.replaceAll(key, value));
    return result;
  }

  List<ProspectRecord> get _visible => _filtered(_advanced);
  List<ProspectRecord> _filtered(ProspectFilters filters) {
    final now = DateTime.now();
    final query = _normalize(_search.text.trim());
    final result = _records
        .where(
          (p) =>
              (_status == 'Todos' ||
                  (_status == 'Atrasados'
                      ? p.nextContact != null && p.nextContact!.isBefore(now)
                      : _normalize(p.status.trim()) == _normalize(_status))) &&
              filters.matches(p, now) &&
              _normalize('${p.name} ${p.phone} ${p.email}').contains(query),
        )
        .toList();
    result.sort((a, b) => filters.compare(a, b, now: now));
    return result;
  }

  Future<void> _showFilters() async {
    FocusScope.of(context).unfocus();
    final selection = await showModalBottomSheet<ProspectFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: ProspectFiltersSheet(
          initial: _advanced,
          count: (filters) => _filtered(filters).length,
        ),
      ),
    );
    if (selection != null && mounted) setState(() => _advanced = selection);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final prospects = _visible;
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        key: const PageStorageKey('prospects-list'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeHeader(
                    userName: AuthService.instance.userName,
                    onNotificationActivity: widget.onNotificationActivity,
                    title:
                        AuthService.instance.activeDevelopment?['rol']
                                ?.toString()
                                .toLowerCase() ==
                            'admin'
                        ? 'PROSPECTOS DEL DESARROLLO'
                        : 'MIS PROSPECTOS',
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontFamily: 'SulphurPoint',
                      fontSize: 14,
                      color: palette.fieldForeground,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, teléfono o email...',
                      hintStyle: TextStyle(
                        fontFamily: 'SulphurPoint',
                        fontSize: 14,
                        color: palette.fieldHint,
                      ),
                      filled: true,
                      fillColor: palette.fieldFill,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        Iconsax.search_normal_1_copy,
                        color: palette.fieldForeground,
                        size: 23,
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(6),
                        child: IconButton.filled(
                          tooltip: 'Filtrar prospectos',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor:
                                !_advanced.active || _advanced.isSellerDefault
                                ? Colors.white
                                : AppColors.accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _showFilters,
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: AppColors.accentColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _filters
                        .map(
                          (filter) => ChoiceChip(
                            label: Text(filter),
                            selected: _status == filter,
                            showCheckmark: false,
                            onSelected: (_) => setState(() {
                              _status = filter;
                            }),
                            selectedColor: palette.chipSelectedFill,
                            backgroundColor: palette.chipFill,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 5,
                            ),
                            labelStyle: TextStyle(
                              fontFamily: 'SulphurPoint',
                              fontSize: 12,
                              color: _status == filter
                                  ? palette.chipSelectedForeground
                                  : palette.chipForeground,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  if (_advanced.active && !_advanced.isSellerDefault)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InputChip(
                        label: Text(
                          _advanced.sourceLabel ?? 'Filtros activos',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        backgroundColor: AppColors.primaryColor,
                        labelStyle: const TextStyle(
                          fontFamily: 'SulphurPoint',
                          color: AppColors.homeBackground,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 18),
                        deleteIconColor: AppColors.homeBackground,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                        onDeleted: () =>
                            setState(() => _advanced = ProspectFilters()),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'MOSTRANDO ${prospects.length} PROSPECTOS',
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Ordenar prospectos',
                        color: AppColors.primaryColor,
                        surfaceTintColor: Colors.transparent,
                        elevation: 8,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.homeDeepTeal),
                        ),
                        initialValue: _advanced.sort,
                        onSelected: (value) =>
                            setState(() => _advanced.sort = value),
                        itemBuilder: (_) => ProspectFilters.sorts
                            .map(
                              (value) => PopupMenuItem(
                                value: value,
                                padding: EdgeInsets.zero,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 48,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  color: value == _advanced.sort
                                      ? AppColors.homeWarmText
                                      : AppColors.primaryColor,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          value,
                                          style: TextStyle(
                                            fontFamily: 'SulphurPoint',
                                            fontSize: 18,
                                            fontWeight: value == _advanced.sort
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: value == _advanced.sort
                                                ? AppColors.primaryColor
                                                : AppColors.homeBackground,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: palette.chipFill,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _advanced.sort,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'SulphurPoint',
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Theme.of(context).colorScheme.primary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(child: Text(_error!)),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          if (prospects.isEmpty && !_loading && _error == null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.search_normal_1_copy,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No se encontraron prospectos',
                      style: TextStyle(
                        fontFamily: 'SulphurPoint',
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _search.clear();
                        _status = 'Todos';
                        _advanced = ProspectFilters.forSeller();
                      }),
                      child: Text(
                        'Limpiar filtros',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontFamily: 'SulphurPoint',
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 118),
            sliver: SliverList.builder(
              itemCount: prospects.length,
              itemBuilder: (_, index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ProspectCard(
                  prospect: prospects[index],
                  onTap: () => context.push(
                    '/prospectos/${Uri.encodeComponent(prospects[index].phone.isEmpty ? 'id-${prospects[index].id}' : prospects[index].phone)}',
                    extra: prospects[index],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
