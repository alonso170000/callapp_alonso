import 'package:callerapp_frontend/presentation/models/agenda_filters.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_widgets.dart';
import 'package:callerapp_frontend/presentation/widgets/home/home_dashboard_widgets.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class AgendaController {
  VoidCallback? _openNewActivity;

  void openNewActivity() => _openNewActivity?.call();

  void dispose() => _openNewActivity = null;
}

class AgendaScreen extends StatefulWidget {
  final AgendaController? controller;

  const AgendaScreen({super.key, this.controller});

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
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  late final List<AgendaActivity> _activities = demoAgendaActivities(_date);
  AgendaPeriod _period = AgendaPeriod.day;
  AgendaFilters _filters = AgendaFilters();

  @override
  void initState() {
    super.initState();
    widget.controller?._openNewActivity = _showNewActivityDialog;
  }

  @override
  void didUpdateWidget(covariant AgendaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._openNewActivity = null;
      widget.controller?._openNewActivity = _showNewActivityDialog;
    }
  }

  @override
  void dispose() {
    widget.controller?._openNewActivity = null;
    super.dispose();
  }

  Future<void> _showNewActivityDialog() async {
    final activity = await showModalBottomSheet<AgendaActivity>(
      context: context,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.homeBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => NewAgendaActivityDialog(initialDate: _date),
    );
    if (!mounted || activity == null) return;
    setState(() {
      _activities.add(activity);
      _date = DateUtils.dateOnly(activity.date);
      _filters = AgendaFilters();
    });
    _showActionMessage('Actividad agendada.');
  }

  Future<void> _showFilters() async {
    final prospects =
        _activities.map((activity) => activity.prospect).toSet().toList()
          ..sort();
    final result = await showModalBottomSheet<AgendaFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.homeBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => AgendaFiltersSheet(
        initial: _filters,
        prospects: prospects,
        count: (filters) => _activities
            .where(
              (activity) =>
                  DateUtils.isSameDay(activity.date, _date) &&
                  filters.matches(activity),
            )
            .length,
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
      '${_days[date.weekday - 1]}, ${date.day} DE ${_months[date.month - 1]}';

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
          backgroundColor: AppColors.homeBackground,
          body: SafeArea(
            bottom: false,
            child: AgendaActivityDetail(
              activity: activity,
              onClose: () => Navigator.pop(detailContext),
              onMessage: () => _showActionMessage(
                'Mensaje para ${activity.prospect}',
                detailContext,
              ),
              onCall: () => _showActionMessage(
                'Llamada para ${activity.prospect}',
                detailContext,
              ),
              onOpenProspect: () => _showActionMessage(
                'El detalle del prospecto estará disponible al conectar esta actividad.',
                detailContext,
              ),
              onEdit: () => _showActionMessage(
                'La edición estará disponible al conectar el servicio.',
                detailContext,
              ),
              onComplete: () => _completeActivity(activity, detailContext),
              onReschedule: () => _showActionMessage(
                'La cancelación estará disponible al conectar el servicio.',
                detailContext,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showActionMessage(String message, [BuildContext? messageContext]) {
    ScaffoldMessenger.of(messageContext ?? context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _completeActivity(AgendaActivity activity, BuildContext detailContext) {
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

  @override
  Widget build(BuildContext context) {
    final visible =
        _activities
            .where(
              (activity) =>
                  DateUtils.isSameDay(activity.date, _date) &&
                  _filters.matches(activity),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return CustomScrollView(
      key: const PageStorageKey('agenda-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          sliver: SliverList.list(
            children: [
              const HomeHeader(userName: 'Leonardo Pérez', title: 'MI AGENDA'),
              const SizedBox(height: 20),
              AgendaPeriodSelector(
                selected: _period,
                onSelected: (period) => setState(() => _period = period),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.homeWarmText,
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
                      style: agendaHeadingStyle,
                    ),
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.homeWarmText,
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
                  activities: _activities,
                  onSelected: (date) => setState(() => _date = date),
                ),
                const SizedBox(height: 16),
              ],
              if (_period == AgendaPeriod.week) ...[
                const SizedBox(height: 16),
                AgendaWeekSelector(
                  selectedDate: _date,
                  activities: _activities,
                  onSelected: (date) => setState(() => _date = date),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'MOSTRANDO ${visible.length} ${visible.length == 1 ? 'ACTIVIDAD' : 'ACTIVIDADES'}',
                      style: agendaHeadingStyle,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Filtrar actividades',
                    icon: Icon(
                      _filters.active ? Icons.filter_alt : Icons.tune,
                      color: AppColors.primaryColor,
                    ),
                    onPressed: _showFilters,
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
                    label: const Text('Filtros activos'),
                    onDeleted: () => setState(() => _filters = AgendaFilters()),
                    deleteIconColor: AppColors.whiteColor,
                  ),
                ),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.event_available_outlined,
                        size: 44,
                        color: AppColors.primaryColor,
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
                          _date = DateUtils.dateOnly(DateTime.now());
                          _filters = AgendaFilters();
                        }),
                        child: const Text(
                          'Volver a hoy',
                          style: TextStyle(
                            color: AppColors.primaryColor,
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
    );
  }
}
