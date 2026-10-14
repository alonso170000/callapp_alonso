import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:go_router/go_router.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/new_prospect_sheet.dart';
import 'package:callerapp_frontend/presentation/models/prospect_filters.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_card.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/home/home_dashboard_widgets.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class ProspectsController {
  void Function(Set<int>, String)? _show;
  void showFromHome(Set<int> ids, String label) => _show?.call(ids, label);
  VoidCallback? _open;
  void openNewProspect() => _open?.call();
  void dispose() {
    _open = null;
    _show = null;
  }
}

class ProspectsScreen extends StatefulWidget {
  final ProspectsController? controller;
  final Future<List<ProspectRecord>> Function()? loadProspects;
  const ProspectsScreen({super.key, this.controller, this.loadProspects});

  @override
  State<ProspectsScreen> createState() => _ProspectsScreenState();
}

class _ProspectsScreenState extends State<ProspectsScreen> {
  final _records = <ProspectRecord>[];
  final _service = ProspectsService();
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
      final records = await (widget.loadProspects?.call() ?? _service.fetch());
      if (!mounted || request != _request) return;
      setState(() {
        _records.clear();
        _records.addAll(records);
      });
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
    AuthService.instance.addListener(_sessionChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant ProspectsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._open = null;
      oldWidget.controller?._show = null;
      widget.controller?._open = _addProspect;
      widget.controller?._show = _showFromHome;
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
      builder: (_) => const NewProspectSheet(),
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
    _search.dispose();
    AuthService.instance.removeListener(_sessionChanged);
    _service.dispose();
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
                    style: const TextStyle(
                      fontFamily: 'SulphurPoint',
                      fontSize: 14,
                      color: AppColors.primaryColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, teléfono o email...',
                      hintStyle: const TextStyle(
                        fontFamily: 'SulphurPoint',
                        fontSize: 13,
                        color: Color(0xFF5CABA4),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFC5E9E3),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Iconsax.search_normal_1_copy,
                        color: AppColors.primaryColor,
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
                            selectedColor: AppColors.primaryColor,
                            backgroundColor: const Color(0xFFABF5E7),
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
                                  ? AppColors.accentColor
                                  : const Color(0xFF3B8C83),
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
                        style: const TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 20,
                          color: AppColors.primaryColor,
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
                            color: const Color(0xFFABF5E7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Ordenar por ${_advanced.sort.toLowerCase()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'SulphurPoint',
                                    fontSize: 12,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: AppColors.primaryColor,
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
          
          if (prospects.isEmpty && !_loading && _error == null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Iconsax.search_normal_1_copy,
                      size: 40,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No se encontraron prospectos',
                      style: TextStyle(
                        fontFamily: 'SulphurPoint',
                        fontSize: 18,
                        color: AppColors.primaryColor,
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
                          color: AppColors.primaryColor,
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
