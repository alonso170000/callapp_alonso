import 'package:callerapp_frontend/services/auth_service.dart';

import 'dart:async';

import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:callerapp_frontend/repositories/agenda_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/new_prospect_sheet.dart';
import 'package:callerapp_frontend/presentation/models/prospect_filters.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_card.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_contact_options_sheet.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_search.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/contact_medium.dart';
import 'package:callerapp_frontend/presentation/models/prospect_action.dart';
import 'package:callerapp_frontend/presentation/widgets/home/home_dashboard_widgets.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/colors/prospect_tag_colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospect_detail_screen.dart';
import 'package:callerapp_frontend/services/phone_call_service.dart';
import 'package:callerapp_frontend/services/phone_number.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/services/call_session_controller.dart';
import 'package:callerapp_frontend/services/contact_launcher.dart';
import 'package:callerapp_frontend/services/notification_service.dart';
import 'package:callerapp_frontend/services/data_change_bus.dart';

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
  final PhoneCallService? phoneCallService;
  final DateTime Function()? now;
  final AgendaRepository? agendaRepository;
  final bool active;
  const ProspectsScreen({
    super.key,
    this.controller,
    this.loadProspects,
    this.onNotificationActivity,
    this.phoneCallService,
    this.now,
    this.agendaRepository,
    this.active = true,
  });

  @override
  State<ProspectsScreen> createState() => _ProspectsScreenState();
}

class _ProspectsScreenState extends State<ProspectsScreen> {
  final _records = <ProspectRecord>[];
  final _repository = ProspectsRepository();
  late final AgendaRepository _agendaRepository;
  bool _ownsAgendaRepository = false;
  List<AgendaActivity> _activities = const [];
  bool _agendaVerified = false;
  int _agendaRequest = 0;
  bool _loading = false;
  String? _error;
  int _request = 0;
  bool _calling = false;
  final _callSession = CallSessionController.instance;

  Future<void> _load() async {
    unawaited(_loadAgenda());
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

  Future<void> _loadAgenda() async {
    final request = ++_agendaRequest;
    try {
      final cached = await _agendaRepository.readCache();
      if (!mounted || request != _agendaRequest) return;
      if (cached.isNotEmpty) {
        setState(() {
          _activities = cached;
          _agendaVerified = true;
        });
      }
    } catch (_) {}
    try {
      final remote = await _agendaRepository.refresh();
      if (!mounted || request != _agendaRequest) return;
      setState(() {
        _activities = remote;
        _agendaVerified = true;
      });
    } catch (_) {
      if (!mounted || request != _agendaRequest) return;
      setState(() => _agendaVerified = false);
    }
  }

  void _sessionChanged() {
    ++_request;
    _records.clear();
    _activities = const [];
    _agendaVerified = false;
    _search.clear();
    _advanced = ProspectFilters.forSeller();
    _load();
  }

  void _dataChanged() {
    if (mounted && widget.active) _load();
  }

  @override
  void initState() {
    super.initState();
    _agendaRepository = widget.agendaRepository ?? AgendaRepository();
    _ownsAgendaRepository = widget.agendaRepository == null;
    widget.controller?._open = _addProspect;
    widget.controller?._show = _showFromHome;
    widget.controller?._openProspect = _openProspectById;
    widget.controller?._refresh = _load;
    AuthService.instance.addListener(_sessionChanged);
    DataChangeBus.instance.addListener(_dataChanged);
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
    if (widget.active && !oldWidget.active) _load();
  }

  void _showFromHome(Set<int> ids, String label) {
    setState(() {
      _search.clear();
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
    await context.push(
      '/prospectos/${Uri.encodeComponent(prospect.phone.isEmpty ? 'id-${prospect.id}' : prospect.phone)}',
      extra: prospect,
    );
    if (mounted) await _load();
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
      _advanced = ProspectFilters.forSeller();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prospecto registrado correctamente.')),
    );
    await _load();
  }

  final _search = TextEditingController();
  ProspectFilters _advanced = ProspectFilters.forSeller();

  DateTime get _now => (widget.now ?? businessNow)();

  List<String> get _statuses {
    final byNormalized = <String, String>{};
    for (final record in _records) {
      final normalized = ProspectSearch.normalize(record.status);
      if (normalized.isEmpty ||
          normalized == ProspectSearch.normalize('Atrasados')) {
        continue;
      }
      byNormalized.putIfAbsent(normalized, () => record.status.trim());
    }
    final ordered = <String>[];
    for (final status in ProspectFilters.statusOrder) {
      final value = byNormalized.remove(ProspectSearch.normalize(status));
      if (value != null) ordered.add(value);
    }
    final extras = byNormalized.values.toList()
      ..sort(
        (a, b) =>
            ProspectSearch.normalize(a).compareTo(ProspectSearch.normalize(b)),
      );
    return ['Todos', ...ordered, ...extras];
  }

  @override
  void dispose() {
    widget.controller?._open = null;
    widget.controller?._show = null;
    widget.controller?._openProspect = null;
    widget.controller?._refresh = null;
    _search.dispose();
    AuthService.instance.removeListener(_sessionChanged);
    DataChangeBus.instance.removeListener(_dataChanged);
    _repository.dispose();
    if (_ownsAgendaRepository) _agendaRepository.dispose();
    super.dispose();
  }

  String _activityDateLabel(BuildContext context, AgendaActivity activity) {
    final date = activity.date;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year} a las ${TimeOfDay.fromDateTime(date).format(context)}';
  }

  Future<void> _contactProspect(
    ProspectRecord prospect,
    ProspectAction action,
  ) async {
    final activity = action.activity;
    final medium = action.medium;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        final other =
            _activities
                .where(
                  (value) =>
                      value.prospectId == prospect.id &&
                      value.isFollowUp &&
                      (value.status == AgendaStatus.pending ||
                          value.status == AgendaStatus.overdue) &&
                      value.id != activity?.id,
                )
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));
        final otherActivity = other.isEmpty ? null : other.first;
        final verb = switch (medium) {
          ContactMedium.llamada => 'hacer la llamada',
          ContactMedium.whatsapp => 'enviar el mensaje',
          ContactMedium.correo => 'enviar el correo',
          ContactMedium.facebook => 'abrir Facebook',
        };
        final question = activity != null
            ? 'Hay un seguimiento por ${medium.channelLabel} ${activity.status == AgendaStatus.overdue ? 'atrasado' : 'agendado'} con este prospecto el ${_activityDateLabel(sheetContext, activity)}. ¿Quieres $verb y registrar el seguimiento?'
            : otherActivity != null
            ? 'Este prospecto no tiene un seguimiento por ${medium.channelLabel}, pero tiene ${otherActivity.title.toLowerCase()} ${otherActivity.status == AgendaStatus.overdue ? 'atrasado' : 'agendado'} el ${_activityDateLabel(sheetContext, otherActivity)}. ¿Quieres $verb?'
            : _agendaVerified
            ? 'Este prospecto no tiene seguimientos pendientes. ¿Quieres $verb?'
            : 'No se pudo verificar la agenda de este prospecto. ¿Quieres $verb?';
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    prospect.name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 28,
                      color: Theme.of(sheetContext).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(question),
                  const SizedBox(height: 20),
                  if (medium != ContactMedium.llamada)
                    FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: Text(switch (medium) {
                        ContactMedium.whatsapp => 'ABRIR WHATSAPP',
                        ContactMedium.correo => 'ABRIR CORREO',
                        ContactMedium.facebook => 'ENTENDIDO',
                        ContactMedium.llamada => 'SÍ, LLAMAR',
                      }),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext, false),
                            child: const Text('NO LLAMAR'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(sheetContext, true),
                            child: const Text('SÍ, LLAMAR'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!mounted || confirmed != true) return;
    if (medium == ContactMedium.facebook) {
      final opened = await const ContactLauncher().openFacebook();
      if (!mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Facebook.')),
        );
        return;
      }
      await _openProspectDetail(prospect, activity);
      return;
    }
    if (medium == ContactMedium.whatsapp) {
      final opened = await const ContactLauncher().openWhatsApp(
        prospect,
        activity: activity,
      );
      if (!mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
        );
        return;
      }
      await _openProspectDetail(prospect, activity);
      return;
    }
    if (medium == ContactMedium.correo) {
      final opened = await const ContactLauncher().openEmail(
        prospect,
        activity: activity,
      );
      if (!mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la aplicación de correo.'),
          ),
        );
        return;
      }
      await _openProspectDetail(prospect, activity);
      return;
    }
    final successful = await _runCall(prospect, activity: activity);
    if (!mounted || successful == null) return;
    await _openProspectDetail(prospect, activity);
  }

  Future<void> _showContactOptions(ProspectRecord prospect) async {
    final medium = await showModalBottomSheet<ContactMedium>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => ProspectContactOptionsSheet(
        prospect: prospect,
        agendaVerified: _agendaVerified,
      ),
    );
    if (!mounted || medium == null) return;

    if (medium == ContactMedium.llamada) {
      final successful = await _runCall(prospect);
      if (!mounted || successful == null) return;
      await _openProspectDetail(prospect, null);
      return;
    }
    if (medium == ContactMedium.whatsapp) {
      final opened = await const ContactLauncher().openWhatsApp(prospect);
      if (!mounted) return;
      if (!opened) {
        _showContactError('No se pudo abrir WhatsApp.');
        return;
      }
      await _openProspectDetail(prospect, null, contactMedium: medium);
      return;
    }
    if (medium == ContactMedium.correo) {
      final opened = await const ContactLauncher().openEmail(prospect);
      if (!mounted) return;
      if (!opened) {
        _showContactError('No se pudo abrir la aplicación de correo.');
        return;
      }
      await _openProspectDetail(prospect, null, contactMedium: medium);
      return;
    }
    if (medium == ContactMedium.facebook) {
      final opened = await const ContactLauncher().openFacebook();
      if (!mounted) return;
      if (!opened) {
        _showContactError('No se pudo abrir Facebook.');
        return;
      }
      await _openProspectDetail(prospect, null, contactMedium: medium);
    }
  }

  void _showContactError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openProspectDetail(
    ProspectRecord prospect,
    AgendaActivity? activity, {
    ContactMedium? contactMedium,
  }) async {
    await context.push(
      '/prospectos/${Uri.encodeComponent(prospect.phone.isEmpty ? 'id-${prospect.id}' : prospect.phone)}',
      extra: ProspectDetailArguments(
        prospect: prospect,
        sourceActivity: activity,
        callStarted: false,
        callSuccessful: false,
        initialContactMedium: contactMedium,
      ),
    );
    if (mounted) await _load();
  }

  Future<bool?> _runCall(
    ProspectRecord prospect, {
    AgendaActivity? activity,
  }) async {
    if (_calling) return null;
    if (_callSession.activeCall != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Termina la llamada en curso antes de marcar otro número.',
          ),
        ),
      );
      return null;
    }
    if (!PhoneNumber.isDialable(prospect.phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El prospecto no tiene un teléfono válido para llamar.',
          ),
        ),
      );
      return null;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Antes de marcar'),
        content: const Text(
          'Recuerda informar al prospecto que la llamada será grabada y preguntarle si acepta. Si aún no lo sabes, puedes marcar y confirmarlo al terminar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('MARCAR'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return null;
    _calling = true;
    final startedAt = businessNow();
    final service = widget.phoneCallService ?? PhoneCallService();
    try {
      await service.call(prospect.phone);
    } on PhoneCallException catch (value) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(value.message)));
      }
      return null;
    } finally {
      _calling = false;
    }
    if (!mounted) return null;
    await _callSession.start(
      prospect: prospect,
      origin: 'tarjeta',
      sourceActivityId: activity?.id,
      startedAt: startedAt,
    );
    await NotificationService.instance.showFollowUpReminder(prospect, activity);
    return false;
  }

  List<ProspectRecord> get _visible => _filtered(_advanced);
  List<ProspectRecord> _filtered(ProspectFilters filters) {
    final now = _now;
    final query = ProspectSearch.normalize(_search.text.trim());
    final result = _records
        .where(
          (p) =>
              filters.matches(p, now) &&
              ProspectSearch.normalize('${p.name} ${p.phone} ${p.email}')
                  .contains(query),
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
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => ProspectFiltersSheet(
        initial: _advanced,
        count: (filters) => _filtered(filters).length,
        now: widget.now ?? businessNow,
      ),
    );
    if (selection != null && mounted) setState(() => _advanced = selection);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final prospects = _visible;
    final activeFilters = _advanced.visibleSummary;
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
                        child: Badge(
                          isLabelVisible: activeFilters.isNotEmpty,
                          label: Text(
                            '${activeFilters.length}',
                            style: TextStyle(
                              fontFamily: 'SulphurPoint',
                              fontSize: 10,
                              color: palette.textColor,
                            ),
                          ),
                          backgroundColor: AppColors.brandColor,
                          child: Semantics(
                            container: true,
                            value: '${activeFilters.length} filtros activos',
                            child: IconButton.filled(
                              tooltip: 'Filtrar prospectos',
                              style: IconButton.styleFrom(
                                backgroundColor: palette.brandFill,
                                foregroundColor: palette.onBrand,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _showFilters,
                              icon: const Icon(Icons.tune_rounded, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    key: const ValueKey('prospect-status-filters'),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: _statuses.map((filter) {
                        final isAll = filter == 'Todos';
                        final selected = isAll
                            ? _advanced.status == null
                            : ProspectSearch.normalize(
                                    _advanced.status ?? '',
                                  ) ==
                                  ProspectSearch.normalize(filter);
                        final selectedFill = isAll
                            ? palette.chipSelectedFill
                            : ProspectTagColors.status(filter);
                        final selectedInk = isAll
                            ? palette.chipSelectedForeground
                            : palette.cardInk;
                        return ChoiceChip(
                          label: Text(filter),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) => setState(() {
                            _advanced.status = isAll ? null : filter;
                          }),
                          selectedColor: selectedFill,
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
                            color: selected
                                ? selectedInk
                                : palette.chipForeground,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (activeFilters.isNotEmpty)
                    SingleChildScrollView(
                      key: const ValueKey('prospect-active-filters'),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: activeFilters
                            .map(
                              (filter) => InputChip(
                                label: Text(filter.label),
                                deleteIcon: const Icon(Icons.close_rounded),
                                onDeleted: () => setState(
                                  () => _advanced = _advanced.clearGroup(
                                    filter.group,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
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
                        prospects.length == 1
                            ? 'MOSTRANDO 1 PROSPECTO'
                            : 'MOSTRANDO ${prospects.length} PROSPECTOS',
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
          if (_records.isEmpty && !_loading && _error == null)
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
                      'Aún no tienes prospectos asignados',
                      style: TextStyle(
                        fontFamily: 'SulphurPoint',
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: _load,
                      child: Text(
                        'Actualizar',
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
          if (_records.isNotEmpty &&
              prospects.isEmpty &&
              !_loading &&
              _error == null)
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
                      'No hay prospectos con estos filtros',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SulphurPoint',
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _search.clear();
                        _advanced = ProspectFilters.all();
                      }),
                      child: const Text('Ver todos'),
                    ),
                    if (_search.text.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(_search.clear),
                        child: const Text('Limpiar búsqueda'),
                      ),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 118),
            sliver: SliverList.builder(
              itemCount: prospects.length,
              itemBuilder: (_, index) {
                final prospect = prospects[index];
                final action = ProspectAction.resolve(
                  prospect: prospect,
                  activities: _activities,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ProspectCard(
                    prospect: prospect,
                    action: action,
                    onContact: (_) => _contactProspect(prospect, action),
                    onContactOptions: () =>
                        unawaited(_showContactOptions(prospect)),
                    onTap: () async {
                      await context.push(
                        '/prospectos/${Uri.encodeComponent(prospects[index].phone.isEmpty ? 'id-${prospects[index].id}' : prospects[index].phone)}',
                        extra: prospects[index],
                      );
                      if (mounted) await _load();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
