import 'dart:async';

import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_search.dart';
import 'package:callerapp_frontend/presentation/models/search_models.dart';
import 'package:callerapp_frontend/presentation/widgets/search/search_widgets.dart';
import 'package:callerapp_frontend/repositories/prospect_search_repository.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Pantalla del buscador global de prospectos.
///
/// Lee primero la caché local y, si hace falta, refresca en segundo plano. La
/// pantalla nunca bloquea la escritura esperando a la red.
class SearchScreen extends StatefulWidget {
  static const name = 'search-screen';

  const SearchScreen({
    super.key,
    this.repository,
    this.onOpenProspect,
    this.now,
  });

  final ProspectSearchRepository? repository;
  final ValueChanged<ProspectRecord>? onOpenProspect;
  final DateTime Function()? now;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final ProspectSearchRepository _repository;
  late final bool _ownsRepository;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  List<ProspectRecord> _records = const [];
  List<RecentSearch> _recent = const [];
  String _query = '';
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  String? _notice;
  int _request = 0;

  DateTime _now() => widget.now?.call() ?? businessNow();

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ProspectSearchRepository();
    _ownsRepository = widget.repository == null;
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    if (_ownsRepository) _repository.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _refreshing = false;
      _error = null;
      _notice = null;
    });
    try {
      final snapshot = await _repository.load();
      if (!mounted || request != _request) return;
      setState(() {
        _records = snapshot.prospects;
        _recent = snapshot.recentSearches;
        _loading = false;
      });
      if (snapshot.prospects.isEmpty ||
          _repository.isRefreshDue(snapshot, now: _now())) {
        unawaited(
          _refresh(silent: snapshot.prospects.isNotEmpty, request: request),
        );
      }
    } on ProspectsException catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } on Object {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo abrir el buscador.';
      });
    }
  }

  Future<void> _refresh({bool silent = false, int? request}) async {
    if (_refreshing || !mounted) return;
    setState(() {
      _refreshing = true;
      if (!silent) {
        _error = null;
        _notice = null;
      }
    });
    try {
      final snapshot = await _repository.refresh();
      if (!mounted || (request != null && request != _request)) return;
      setState(() {
        _records = snapshot.prospects;
        _recent = snapshot.recentSearches;
        _error = null;
        _notice = null;
      });
    } on ProspectsException catch (error) {
      if (!mounted || (request != null && request != _request)) return;
      setState(() {
        if (_records.isEmpty) {
          _error = error.message;
        } else {
          _notice = 'Mostrando resultados guardados. ${error.message}';
        }
      });
    } on Object {
      if (!mounted || (request != null && request != _request)) return;
      setState(() {
        if (_records.isEmpty) {
          _error = 'No se pudieron cargar los prospectos.';
        } else {
          _notice = 'Mostrando resultados guardados.';
        }
      });
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _rememberCurrentQuery({ProspectRecord? prospect}) async {
    final query = _query.trim();
    if (query.isEmpty) return;
    try {
      final recent = await _repository.rememberQuery(query, prospect: prospect);
      if (mounted) setState(() => _recent = recent);
    } on Object {
      // El historial es una ayuda; nunca debe bloquear la navegación.
    }
  }

  void _applyRecent(RecentSearch entry) {
    _controller.text = entry.query;
    _controller.selection = TextSelection.collapsed(offset: entry.query.length);
    setState(() => _query = entry.query);
    _focusNode.requestFocus();
  }

  Future<void> _removeRecent(String query) async {
    try {
      final recent = await _repository.removeQuery(query);
      if (mounted) setState(() => _recent = recent);
    } on Object {
      // Si falla el almacenamiento local, se conserva la lista visible.
    }
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Borrar historial'),
        content: const Text(
          '¿Deseas eliminar todos los términos buscados recientemente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('BORRAR'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.clearHistory();
      if (mounted) setState(() => _recent = const []);
    } on Object {
      // El historial no debe bloquear la pantalla.
    }
  }

  void _clearQuery() {
    _controller.clear();
    setState(() => _query = '');
    _focusNode.requestFocus();
  }

  void _openProspect(ProspectRecord prospect) {
    unawaited(_rememberCurrentQuery(prospect: prospect));
    final callback = widget.onOpenProspect;
    if (callback != null) {
      callback(prospect);
      return;
    }
    final identifier = prospect.phone.trim().isEmpty
        ? 'id-${prospect.id}'
        : prospect.phone.trim();
    context.push(
      '/prospectos/${Uri.encodeComponent(identifier)}',
      extra: prospect,
    );
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Volver',
                    onPressed: _close,
                    style: IconButton.styleFrom(
                      backgroundColor: palette.brandFill,
                      foregroundColor: palette.onBrand,
                      minimumSize: const Size(48, 48),
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSearchField(context, palette)),
                ],
              ),
            ),
            if (_refreshing)
              LinearProgressIndicator(
                minHeight: 2,
                color: palette.navForeground,
                backgroundColor: palette.fieldFill,
              ),
            if (_notice != null) _SearchNotice(message: _notice!),
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, AppPalette palette) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      autocorrect: false,
      textInputAction: TextInputAction.search,
      cursorColor: palette.fieldForeground,
      style: TextStyle(
        fontFamily: 'SulphurPoint',
        fontSize: 16,
        color: palette.fieldForeground,
      ),
      onChanged: (value) => setState(() => _query = value),
      onSubmitted: (_) => unawaited(_rememberCurrentQuery()),
      decoration: InputDecoration(
        hintText: 'Buscar prospecto...',
        hintStyle: TextStyle(
          fontFamily: 'SulphurPoint',
          fontSize: 15,
          color: palette.fieldHint,
        ),
        filled: true,
        fillColor: palette.fieldFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(
          Iconsax.search_normal_1_copy,
          color: palette.fieldForeground,
          size: 23,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 24,
        ),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: _clearQuery,
                icon: Icon(
                  Icons.close_rounded,
                  color: palette.fieldForeground,
                  size: 22,
                ),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 24,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading || (_refreshing && _records.isEmpty && _error == null)) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (_error != null && _records.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: SearchEmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'No se pudo cargar',
            message: _error!,
            actionLabel: 'Reintentar',
            onAction: _load,
          ),
        ),
      );
    }
    if (_query.trim().isEmpty) return _buildInitial(context);

    final results = ProspectSearch.filter(_records, _query);
    if (results.isEmpty) {
      return _buildRefreshableEmpty(
        context,
        icon: Iconsax.search_normal_1_copy,
        title: 'Sin resultados',
        message:
            'No encontramos prospectos con “$_query”. Prueba con otro nombre, teléfono o correo.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => _refresh(),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: _listPadding(context),
        children: [
          SearchSectionHeader(title: 'Resultados (${results.length})'),
          const SizedBox(height: 8),
          for (final prospect in results) ...[
            ProspectSearchTile(
              prospect: prospect,
              onTap: () => _openProspect(prospect),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildInitial(BuildContext context) {
    final suggestions = ProspectSearch.suggestions(_records, now: _now());
    if (_recent.isEmpty && suggestions.isEmpty) {
      return _buildRefreshableEmpty(
        context,
        icon: Icons.people_outline_rounded,
        title: 'Aún no hay sugerencias',
        message: 'Cuando tengas prospectos asignados aparecerán aquí. También puedes actualizar para buscarlos.',
        actionLabel: 'Actualizar',
        onAction: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: _listPadding(context),
        children: [
          if (_recent.isNotEmpty) ...[
            SearchSectionHeader(
              title: 'Últimos buscados',
              actionLabel: 'Borrar todo',
              onAction: () => unawaited(_confirmClearHistory()),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in _recent)
                  RecentSearchChip(
                    query: entry.query,
                    onTap: () => _applyRecent(entry),
                    onDelete: () => unawaited(_removeRecent(entry.query)),
                  ),
              ],
            ),
          ],
          if (_recent.isNotEmpty && suggestions.isNotEmpty)
            const SizedBox(height: 24),
          if (suggestions.isNotEmpty) ...[
            const SearchSectionHeader(title: 'Prospectos sugeridos'),
            const SizedBox(height: 8),
            for (final suggestion in suggestions) ...[
              ProspectSearchTile(
                prospect: suggestion.prospect,
                reason: suggestion.reason,
                onTap: () => _openProspect(suggestion.prospect),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRefreshableEmpty(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return RefreshIndicator(
      onRefresh: () => _refresh(),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: _listPadding(context),
        children: [
          const SizedBox(height: 24),
          SearchEmptyState(
            icon: icon,
            title: title,
            message: message,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
        ],
      ),
    );
  }

  EdgeInsets _listPadding(BuildContext context) => EdgeInsets.fromLTRB(
    16,
    8,
    16,
    24 + MediaQuery.viewPaddingOf(context).bottom,
  );
}

class _SearchNotice extends StatelessWidget {
  const _SearchNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: palette.noticeSurfaceFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: palette.noticeSurfaceInk,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'SulphurPoint',
                  fontSize: 13,
                  color: palette.noticeSurfaceInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
