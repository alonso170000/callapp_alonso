import 'package:callerapp_frontend/repositories/agenda_repository.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/presentation/models/agenda_filters.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_widgets.dart';
import 'package:callerapp_frontend/presentation/widgets/home/home_dashboard_widgets.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospect_detail_screen.dart';
import 'package:callerapp_frontend/services/phone_call_service.dart';
import 'package:callerapp_frontend/services/phone_number.dart';
import 'package:callerapp_frontend/services/call_session_controller.dart';

class AgendaController {
  void Function(DateTime, Set<int>, String)? _show;
  ValueChanged<AgendaActivity>? _showActivity;
  void showFromHome(DateTime date, Set<int> ids, String label) =>
      _show?.call(date, ids, label);
  VoidCallback? _openNewActivity;
  VoidCallback? _refresh;

  void openNewActivity() => _openNewActivity?.call();
  void refresh() => _refresh?.call();
  void openActivity(AgendaActivity activity) => _showActivity?.call(activity);

  void dispose() {
    _openNewActivity = null;
    _refresh = null;
    _show = null;
    _showActivity = null;
  }
}

class AgendaScreen extends StatefulWidget {
  final AgendaController? controller;
  final Future<List<AgendaActivity>> Function()? loadActivities;
  final Future<List<ProspectRecord>> Function()? loadProspects;
  final ValueChanged<AgendaActivity>? onNotificationActivity;
  final Widget? syncStatus;
  final PhoneCallService? phoneCallService;

  const AgendaScreen({
    super.key,
    this.controller,
    this.loadActivities,
    this.loadProspects,
    this.onNotificationActivity,
    this.syncStatus,
    this.phoneCallService,
  });

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  static const _months = [
    'ENERO',
    'FEBRERO',
    'MARZO',
    'ABRIL',
    'MAYO',
    'JUNIO',
    'JULIO',
    'AGOSTO',
    'SEPTIEMBRE',
    'OCTUBRE',
    'NOVIEMBRE',
    'DICIEMBRE',
  ];
  static const _days = [
    'LUNES',
    'MARTES',
    'MIÉRCOLES',
    'JUEVES',
    'VIERNES',
    'SÁBADO',
    'DOMINGO',
  ];
  DateTime _date = DateUtils.dateOnly(businessNow());
  final List<AgendaActivity> _activities = [];
  final _service = AgendaService();
  late final AgendaRepository _repository = AgendaRepository(service: _service);
  final _prospects = ProspectsRepository();
  bool _loading = false;
  bool _calling = false;
  final _callSession = CallSessionController.instance;
  String? _error;
  int _request = 0;

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.loadActivities != null) {
        final activities = await widget.loadActivities!.call();
        if (!mounted || request != _request) return;
        setState(() {
          _activities.clear();
          _activities.addAll(activities);
        });
        return;
      }

      var hasCachedActivities = false;
      try {
        final cached = await _repository.readCache();
        if (!mounted || request != _request) return;
        if (cached.isNotEmpty) {
          hasCachedActivities = true;
          setState(() {
            _activities
              ..clear()
              ..addAll(cached);
          });
        }
      } catch (_) {
        // Una caché dañada no debe impedir la consulta remota.
      }

      try {
        final activities = await _repository.refresh();
        if (!mounted || request != _request) return;
        setState(() {
          _activities
            ..clear()
            ..addAll(activities);
          _error = null;
        });
      } on AgendaException catch (error) {
        if (!mounted || request != _request) return;
        setState(() {
          _error = hasCachedActivities
              ? 'Mostrando datos guardados. ${error.message}'
              : error.message;
        });
      }
    } on AgendaException catch (error) {
      if (mounted && request == _request) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  void _sessionChanged() {
    ++_request;
    _activities.clear();
    _filters = AgendaFilters();
    _load();
  }

  AgendaPeriod _period = AgendaPeriod.day;
  AgendaFilters _filters = AgendaFilters();

  @override
  void initState() {
    super.initState();
    widget.controller?._openNewActivity = _showNewActivityDialog;
    widget.controller?._refresh = _load;
    widget.controller?._show = _showFromHome;
    widget.controller?._showActivity = _showActivity;
    AuthService.instance.addListener(_sessionChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant AgendaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._openNewActivity = null;
      oldWidget.controller?._refresh = null;
      oldWidget.controller?._show = null;
      oldWidget.controller?._showActivity = null;
      widget.controller?._openNewActivity = _showNewActivityDialog;
      widget.controller?._refresh = _load;
      widget.controller?._show = _showFromHome;
      widget.controller?._showActivity = _showActivity;
    }
  }

  @override
  void dispose() {
    widget.controller?._openNewActivity = null;
    widget.controller?._refresh = null;
    widget.controller?._show = null;
    widget.controller?._showActivity = null;
    AuthService.instance.removeListener(_sessionChanged);
    _repository.dispose();
    _service.dispose();
    _prospects.dispose();
    super.dispose();
  }

  void _showFromHome(DateTime date, Set<int> ids, String label) {
    setState(() {
      _date = DateUtils.dateOnly(date);
      _period = AgendaPeriod.day;
      _filters = AgendaFilters(
        activityIds: ids,
        sourceLabel: label,
        selectedTypes: {...AgendaFilters.types, 'Llamada'},
      );
    });
    _load();
  }

  Future<void> _showNewActivityDialog() async {
    final scheduled = await showModalBottomSheet<DateTime>(
      context: context,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => NewAgendaActivityDialog(
        initialDate: _date,
        agendaRepository: _repository,
      ),
    );
    if (!mounted || scheduled == null) return;
    setState(() {
      _date = DateUtils.dateOnly(scheduled);
      _filters = AgendaFilters();
    });
    _showActionMessage('Actividad agendada.');
    await _load();
  }

  Future<void> _showFilters() async {
    final prospects =
        _activities.map((activity) => activity.prospect).toSet().toList()
          ..sort();
    final result = await showModalBottomSheet<AgendaFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => AgendaFiltersSheet(
        initial: _filters,
        prospects: prospects,
        count: (filters) => _activities.where(filters.matches).length,
      ),
    );
    if (mounted && result != null) setState(() => _filters = result);
  }

  DateTime get _start => switch (_period) {
    AgendaPeriod.day => _date,
    AgendaPeriod.week => DateTime(
      _date.year,
      _date.month,
      _date.day - _date.weekday + 1,
    ),
    AgendaPeriod.month => DateTime(_date.year, _date.month),
  };

  DateTime get _end => switch (_period) {
    AgendaPeriod.day => DateTime(_date.year, _date.month, _date.day + 1),
    AgendaPeriod.week => DateTime(_start.year, _start.month, _start.day + 7),
    AgendaPeriod.month => DateTime(_date.year, _date.month + 1),
  };

  String _dayLabel(DateTime date) =>
      '${_days[date.weekday - 1]}, ${date.day} DE ${_months[date.month - 1]}, ${date.year}';

  String get _periodLabel {
    if (_period == AgendaPeriod.day) return _dayLabel(_date);
    if (_period == AgendaPeriod.month) {
      return '${_months[_date.month - 1]}, ${_date.year}';
    }
    final last = _end.subtract(const Duration(days: 1));
    if (_start.month == last.month && _start.year == last.year) {
      return '${_start.day} - ${last.day} DE ${_months[last.month - 1]}, ${last.year}';
    }
    if (_start.year != last.year) {
      return '${_start.day} ${_months[_start.month - 1]} ${_start.year} - ${last.day} ${_months[last.month - 1]} ${last.year}';
    }
    return '${_start.day} ${_months[_start.month - 1]} – ${last.day} ${_months[last.month - 1]} ${last.year}';
  }

  void _move(int direction) => setState(() {
    _date = _period == AgendaPeriod.month
        ? DateTime(
            _date.year,
            _date.month + direction,
            _date.day.clamp(
              1,
              DateTime(_date.year, _date.month + direction + 1, 0).day,
            ),
          )
        : DateTime(
            _date.year,
            _date.month,
            _date.day + direction * (_period == AgendaPeriod.week ? 7 : 1),
          );
  });

  void _showActivity(AgendaActivity activity) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (detailContext) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            bottom: false,
            child: AgendaActivityDetail(
              activity: activity,
              loadProspects: widget.loadProspects ?? _cachedProspects,
              onClose: () => Navigator.pop(detailContext),
              onMessage: () => _showActionMessage(
                'Mensaje para ${activity.prospect}',
                detailContext,
              ),
              onCall: () => _callActivity(activity, detailContext),
              onOpenProspect: () => _openProspect(activity, detailContext),
              onDelete: () => _deleteActivity(activity, detailContext),
              onEdit: () => _editActivity(activity, detailContext),
              onComplete: () => _completeActivity(activity, detailContext),
              onReschedule: () => _cancelActivity(activity, detailContext),
            ),
          ),
        ),
      ),
    );
  }

  bool _openingProspect = false;
  final _deleting = <int>{};
  final _changingStatus = <int>{};
  Future<void> _editActivity(
    AgendaActivity activity,
    BuildContext detailContext,
  ) async {
    if (activity.id == null ||
        (activity.status != AgendaStatus.pending &&
            activity.status != AgendaStatus.overdue)) {
      _showActionMessage(
        'Solo se pueden editar actividades pendientes o atrasadas.',
        detailContext,
      );
      return;
    }
    final scheduled = await showModalBottomSheet<DateTime>(
      context: detailContext,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(detailContext).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => NewAgendaActivityDialog(
        initialDate: activity.date,
        activity: activity,
        agendaRepository: _repository,
      ),
    );
    if (scheduled == null || !mounted) return;
    if (detailContext.mounted) Navigator.pop(detailContext);
    setState(() => _date = DateUtils.dateOnly(scheduled));
    _showActionMessage('Actividad actualizada.');
    await _load();
  }

  Future<List<ProspectRecord>> _cachedProspects() async {
    final loader = widget.loadProspects;
    if (loader != null) return loader();
    final cached = await _prospects.readCache();
    if (cached.isNotEmpty) return cached;
    return _prospects.refresh();
  }

  Future<void> _openProspect(
    AgendaActivity activity,
    BuildContext detailContext,
  ) async {
    if (_openingProspect) return;
    if (activity.prospectId == null) {
      _showActionMessage(
        'Esta actividad no tiene un prospecto asociado.',
        detailContext,
      );
      return;
    }
    _openingProspect = true;
    try {
      var prospects = await _cachedProspects();
      var matches = prospects.where((p) => p.id == activity.prospectId);
      if (matches.isEmpty) {
        prospects = await _prospects.refresh();
        matches = prospects.where((p) => p.id == activity.prospectId);
      }
      if (!detailContext.mounted) return;
      if (matches.isEmpty) {
        _showActionMessage(
          'El prospecto ya no está disponible en tu sesión.',
          detailContext,
        );
        return;
      }
      final prospect = matches.first;
      if (_callSession.activeCall != null) {
        _showActionMessage(
          'Termina la llamada en curso antes de marcar otro número.',
          detailContext,
        );
        return;
      }
      await detailContext.push(
        '/prospectos/${Uri.encodeComponent(prospect.phone.isEmpty ? 'id-${prospect.id}' : prospect.phone)}',
        extra: ProspectDetailArguments(
          prospect: prospect,
          sourceActivity: activity,
        ),
      );
    } on ProspectsException catch (error) {
      if (detailContext.mounted) {
        _showActionMessage(error.message, detailContext);
      }
    } finally {
      _openingProspect = false;
    }
  }

  Future<void> _callActivity(
    AgendaActivity activity,
    BuildContext detailContext,
  ) async {
    if (_calling) return;
    if (activity.prospectId == null) {
      _showActionMessage(
        'Esta actividad no tiene un prospecto asociado.',
        detailContext,
      );
      return;
    }
    try {
      var prospects = await _cachedProspects();
      var matches = prospects.where((value) => value.id == activity.prospectId);
      if (matches.isEmpty) {
        prospects = await _prospects.refresh();
        matches = prospects.where((value) => value.id == activity.prospectId);
      }
      if (!detailContext.mounted) return;
      if (matches.isEmpty) {
        _showActionMessage(
          'El prospecto ya no está disponible en tu sesión.',
          detailContext,
        );
        return;
      }
      final prospect = matches.first;
      if (!PhoneNumber.isDialable(prospect.phone)) {
        _showActionMessage(
          'El prospecto no tiene un teléfono válido para llamar.',
          detailContext,
        );
        return;
      }
      final confirmed = await showDialog<bool>(
        context: detailContext,
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
      if (confirmed != true || !detailContext.mounted) return;
      _calling = true;
      final startedAt = businessNow();
      final phone = widget.phoneCallService ?? PhoneCallService();
      try {
        await phone.call(prospect.phone);
      } on PhoneCallException catch (value) {
        if (!detailContext.mounted) return;
        _showActionMessage(value.message, detailContext);
        return;
      }
      _calling = false;
      if (!detailContext.mounted) return;
      await _callSession.start(
        prospect: prospect,
        origin: 'agenda',
        sourceActivityId: activity.id,
        startedAt: startedAt,
      );
      if (!detailContext.mounted) return;
      Navigator.pop(detailContext);
      if (!mounted) return;
      await context.push(
        '/prospectos/${Uri.encodeComponent(prospect.phone)}',
        extra: ProspectDetailArguments(
          prospect: prospect,
          sourceActivity: activity,
          callStarted: false,
          callSuccessful: false,
        ),
      );
      if (mounted) await _load();
    } on ProspectsException catch (error) {
      if (detailContext.mounted) {
        _showActionMessage(error.message, detailContext);
      }
    } finally {
      _calling = false;
    }
  }

  Future<void> _deleteActivity(
    AgendaActivity activity,
    BuildContext detailContext,
  ) async {
    final id = activity.id;
    if (id == null || !_deleting.add(id)) return;
    try {
      final confirmed = await showDialog<bool>(
        context: detailContext,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar actividad'),
          content: const Text('¿Eliminar esta actividad creada por error?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !detailContext.mounted) return;
      final result = await _repository.delete(activity);
      if (!detailContext.mounted) return;
      Navigator.pop(detailContext);
      if (mounted) {
        _showActionMessage(
          result.isPending
              ? 'Actividad eliminada. Pendiente de sincronizar.'
              : 'Actividad eliminada.',
        );
        await _load();
      }
    } on AgendaException catch (error) {
      if (detailContext.mounted) {
        _showActionMessage(error.message, detailContext);
      }
    } finally {
      _deleting.remove(id);
    }
  }

  void _showActionMessage(String message, [BuildContext? messageContext]) {
    ScaffoldMessenger.of(messageContext ?? context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmActivityAction(
    BuildContext detailContext, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: detailContext,
      barrierColor: Colors.black54,
      useSafeArea: true,
      backgroundColor: Theme.of(detailContext).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'SulphurPoint',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar confirmación',
                    onPressed: () => Navigator.pop(sheetContext, false),
                    icon: const Icon(Icons.close, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'SulphurPoint',
                  fontSize: 17,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'VOLVER',
                        style: TextStyle(fontFamily: 'BebasNeue', fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('confirm-activity-action'),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.homeBackground,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return confirmed == true;
  }

  Future<void> _completeActivity(
    AgendaActivity activity,
    BuildContext detailContext,
  ) async {
    if (activity.isFollowUp) return;
    final confirmed = await _confirmActivityAction(
      detailContext,
      title: 'Completar actividad',
      message: '¿Confirmas que esta actividad fue completada?',
      confirmLabel: 'SÍ, COMPLETAR',
    );
    if (!confirmed || !detailContext.mounted) return;
    final id = activity.id;
    if (id != null) {
      if (!_changingStatus.add(id)) return;
      try {
        final result = await _repository.complete(activity);
        if (!detailContext.mounted) return;
        Navigator.pop(detailContext);
        if (mounted) {
          _showActionMessage(
            result.isPending
                ? 'Actividad completada. Pendiente de sincronizar.'
                : 'Actividad completada.',
          );
          await _load();
        }
      } on AgendaException catch (error) {
        if (detailContext.mounted) {
          _showActionMessage(error.message, detailContext);
        }
      } finally {
        _changingStatus.remove(id);
      }
      return;
    }
    if (activity.status != AgendaStatus.completed) {
      final index = _activities.indexOf(activity);
      if (index != -1) {
        setState(() {
          _activities[index] = activity.copyWith(
            status: AgendaStatus.completed,
          );
        });
      }
    }
    Navigator.pop(detailContext);
    _showActionMessage('Actividad completada.');
  }

  Future<void> _cancelActivity(
    AgendaActivity activity,
    BuildContext detailContext,
  ) async {
    final confirmed = await _confirmActivityAction(
      detailContext,
      title: 'Cancelar actividad',
      message: '¿Seguro que deseas cancelar esta actividad? Esta acción no se puede deshacer.',
      confirmLabel: 'SÍ, CANCELAR',
    );
    if (!confirmed || !detailContext.mounted) return;
    final id = activity.id;
    if (id != null) {
      if (!_changingStatus.add(id)) return;
      try {
        final result = await _repository.cancel(activity);
        if (!detailContext.mounted) return;
        Navigator.pop(detailContext);
        if (mounted) {
          _showActionMessage(
            result.isPending
                ? 'Actividad cancelada. Pendiente de sincronizar.'
                : 'Actividad cancelada.',
          );
          await _load();
        }
      } on AgendaException catch (error) {
        if (detailContext.mounted) {
          _showActionMessage(error.message, detailContext);
        }
      } finally {
        _changingStatus.remove(id);
      }
      return;
    }
    final index = _activities.indexOf(activity);
    if (index != -1) {
      setState(() {
        _activities[index] = activity.copyWith(status: AgendaStatus.cancelled);
      });
    }
    if (detailContext.mounted) Navigator.pop(detailContext);
    _showActionMessage('Actividad cancelada.');
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final filteredActivities = _activities.where(_filters.matches).toList();
    final visible =
        filteredActivities
            .where((activity) => DateUtils.isSameDay(activity.date, _date))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        key: const PageStorageKey('agenda-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverList.list(
              children: [
                HomeHeader(
                  userName: AuthService.instance.userName,
                  title: 'MI AGENDA',
                  onNotificationActivity:
                      widget.onNotificationActivity ?? _showActivity,
                ),
                if (widget.syncStatus != null) widget.syncStatus!,
                const SizedBox(height: 20),
                if (_loading)
                  LinearProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                if (_error != null) ...[
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
                AgendaPeriodSelector(
                  selected: _period,
                  onSelected: (period) => setState(() => _period = period),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: palette.navSelectedFill,
                        foregroundColor: palette.navSelectedForeground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      tooltip: 'Periodo anterior',
                      onPressed: () => _move(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        _periodLabel,
                        textAlign: TextAlign.center,
                        style: agendaHeadingStyle.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: palette.navSelectedFill,
                        foregroundColor: palette.navSelectedForeground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      tooltip: 'Periodo siguiente',
                      onPressed: () => _move(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                if (_period == AgendaPeriod.month) ...[
                  const SizedBox(height: 16),
                  AgendaMonthCalendar(
                    selectedDate: _date,
                    activities: filteredActivities,
                    onSelected: (date) => setState(() => _date = date),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_period == AgendaPeriod.week) ...[
                  const SizedBox(height: 16),
                  AgendaWeekSelector(
                    selectedDate: _date,
                    activities: filteredActivities,
                    onSelected: (date) => setState(() => _date = date),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'MOSTRANDO ${visible.length} ${visible.length == 1 ? 'ACTIVIDAD' : 'ACTIVIDADES'}',
                        style: agendaHeadingStyle.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Filtrar actividades',
                      icon: Icon(
                        _filters.active ? Icons.filter_alt : Icons.tune,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: _showFilters,
                    ),
                    IconButton(
                      tooltip: 'Ir a hoy',
                      onPressed: () => setState(
                        () => _date = DateUtils.dateOnly(businessNow()),
                      ),
                      icon: Icon(
                        Iconsax.calendar_copy,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (_filters.active)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InputChip(
                      backgroundColor: AppColors.primaryColor,
                      labelStyle: const TextStyle(
                        color: AppColors.whiteColor,
                        fontFamily: 'SulphurPoint',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      label: Text(_filters.sourceLabel ?? 'Filtros activos'),
                      onDeleted: () =>
                          setState(() => _filters = AgendaFilters()),
                      deleteIconColor: AppColors.whiteColor,
                    ),
                  ),
                if (visible.isEmpty && !_loading && _error == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Iconsax.calendar_2_copy,
                          size: 52,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _period != AgendaPeriod.day
                              ? 'No hay actividades para este día.'
                              : 'No hay actividades para este periodo.',
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _date = DateUtils.dateOnly(businessNow());
                            _filters = AgendaFilters();
                          }),
                          child: Text(
                            'Volver a hoy',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontFamily: 'SulphurPoint',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              118 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverList.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final activity = visible[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AgendaActivityTile(
                    activity: activity,
                    onTap: () => _showActivity(activity),
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
