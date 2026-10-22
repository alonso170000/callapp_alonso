import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/repositories/agenda_repository.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/home_models.dart';
import 'package:callerapp_frontend/presentation/models/home_dashboard_data.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_widgets.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:callerapp_frontend/services/business_clock.dart';

import 'home_dashboard_widgets.dart';

class HomeDashboardController {
  VoidCallback? _refresh;
  void refresh() => _refresh?.call();
  void dispose() => _refresh = null;
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({
    super.key,
    required this.active,
    required this.onAgenda,
    required this.onProspects,
    required this.onActivity,
    required this.onAddProspect,
    this.loadActivities,
    this.loadProspects,
    this.syncStatus,
    this.controller,
  });
  final bool active;
  final void Function(DateTime, Set<int>, String) onAgenda;
  final void Function(Set<int>, String) onProspects;
  final ValueChanged<AgendaActivity> onActivity;
  final VoidCallback onAddProspect;
  final Future<List<AgendaActivity>> Function()? loadActivities;
  final Future<List<ProspectRecord>> Function()? loadProspects;
  final Widget? syncStatus;
  final HomeDashboardController? controller;
  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final _agenda = AgendaRepository();
  final _prospects = ProspectsRepository();
  HomeDashboardData? _data;
  bool _loading = true;
  String? _error;
  int _request = 0;
  DateTime _selectedDate = DateUtils.dateOnly(businessNow());
  void _selectDate(DateTime date) =>
      setState(() => _selectedDate = DateUtils.dateOnly(date));

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

  String get _weekLabel {
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day - _selectedDate.weekday + 1,
    );
    final last = DateTime(start.year, start.month, start.day + 6);
    if (start.month == last.month && start.year == last.year) {
      return '${start.day} - ${last.day} DE ${_months[last.month - 1]}, ${last.year}';
    }
    return '${start.day} ${_months[start.month - 1]} - ${last.day} ${_months[last.month - 1]}, ${last.year}';
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._refresh = _load;
    AuthService.instance.addListener(_sessionChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant HomeDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._refresh = null;
      widget.controller?._refresh = _load;
    }
    if (widget.active && !oldWidget.active) _load();
  }

  void _sessionChanged() {
    _data = null;
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.loadProspects != null) {
        final values = await Future.wait<Object>([
          widget.loadProspects!.call(),
          widget.loadActivities?.call() ?? _agenda.refresh(),
        ]);
        if (!mounted || request != _request) return;
        setState(
          () => _data = HomeDashboardData(
            values[0] as List<ProspectRecord>,
            values[1] as List<AgendaActivity>,
            businessNow(),
          ),
        );
        return;
      }

      var cachedProspects = <ProspectRecord>[];
      var cachedActivities = <AgendaActivity>[];
      try {
        cachedProspects = await _prospects.readCache();
      } catch (_) {
        // La API sigue disponible aunque SQLite no pueda leerse.
      }
      try {
        cachedActivities = await _agenda.readCache();
      } catch (_) {
        // La API sigue disponible aunque SQLite no pueda leerse.
      }
      if (!mounted || request != _request) return;
      final hasCache =
          cachedProspects.isNotEmpty || cachedActivities.isNotEmpty;
      if (hasCache) {
        setState(
          () => _data = HomeDashboardData(
            cachedProspects,
            cachedActivities,
            businessNow(),
          ),
        );
      }

      List<ProspectRecord>? refreshedProspects;
      List<AgendaActivity>? refreshedActivities;
      Object? prospectsError;
      Object? activitiesError;
      await Future.wait([
        () async {
          try {
            refreshedProspects = await _prospects.refresh();
          } catch (error) {
            prospectsError = error;
          }
        }(),
        () async {
          try {
            refreshedActivities =
                await (widget.loadActivities?.call() ?? _agenda.refresh());
          } catch (error) {
            activitiesError = error;
          }
        }(),
      ]);
      if (!mounted || request != _request) return;

      if (refreshedProspects != null || refreshedActivities != null) {
        setState(
          () => _data = HomeDashboardData(
            refreshedProspects ?? cachedProspects,
            refreshedActivities ?? cachedActivities,
            businessNow(),
          ),
        );
      }

      final errors = [
        if (prospectsError != null) _errorMessage(prospectsError!),
        if (activitiesError != null) _errorMessage(activitiesError!),
      ];
      setState(() {
        _error = errors.isEmpty
            ? null
            : hasCache
            ? 'Mostrando datos guardados. ${errors.first}'
            : errors.first;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  String _errorMessage(Object error) => switch (error) {
    AgendaException(:final message) => message,
    ProspectsException(:final message) => message,
    _ => 'No se pudo cargar Inicio. Intenta nuevamente.',
  };

  @override
  void dispose() {
    widget.controller?._refresh = null;
    AuthService.instance.removeListener(_sessionChanged);
    _agenda.dispose();
    _prospects.dispose();
    super.dispose();
  }

  Widget _section(
    String title,
    Color color,
    List<ProspectRecord> records, {
    bool add = false,
  }) => ProspectSection(
    title: title,
    color: color,
    height: 136,
    showAddButton: add,
    onOpen: () => widget.onProspects(
      records.map((p) => p.id).whereType<int>().toSet(),
      add
          ? title
          : '$title · ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
    ),
    onAdd: widget.onAddProspect,
    onProspect: (index) => context.push(
      '/prospectos/${records[index].phone}',
      extra: records[index],
    ),
    prospects: records
        .map(
          (p) => ProspectItem(
            name: p.name,
            avatarUrl: p.avatarUrl,
            subtitle: p.status,
            avatarColor: p.avatarColor,
            accentColor: p.statusColor,
          ),
        )
        .toList(),
  );

  Widget _activitySection(
    String title,
    Color color,
    List<AgendaActivity> activities,
    HomeDashboardData data,
  ) {
    final prospectsById = {
      for (final prospect in data.prospects)
        if (prospect.id != null) prospect.id!: prospect,
    };
    final entries = [
      for (final activity in activities)
        if (activity.prospectId != null &&
            prospectsById.containsKey(activity.prospectId))
          (activity: activity, prospect: prospectsById[activity.prospectId]!),
    ];

    return ProspectSection(
      title: title,
      color: color,
      height: 136,
      onOpen: () => widget.onProspects(
        entries.map((entry) => entry.prospect.id).whereType<int>().toSet(),
        '$title · ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
      ),
      onProspect: (index) => widget.onActivity(entries[index].activity),
      prospects: [
        for (final entry in entries)
          ProspectItem(
            name: entry.prospect.name,
            avatarUrl: entry.prospect.avatarUrl,
            subtitle: entry.activity.title,
            avatarColor: entry.prospect.avatarColor,
            accentColor: entry.prospect.statusColor,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final loaded = _data;
    final data = loaded == null
        ? null
        : HomeDashboardData(
            loaded.prospects,
            loaded.activities,
            businessNow(),
            selectedDate: _selectedDate,
          );
    return RefreshIndicator(
      onRefresh: _load,
      backgroundColor: Theme.of(context).colorScheme.surface,
      color: Theme.of(context).colorScheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 118),
            sliver: SliverList.list(
              children: [
                HomeHeader(
                  userName: AuthService.instance.userName,
                  onNotificationActivity: widget.onActivity,
                ),
                if (widget.syncStatus != null) widget.syncStatus!,
                if (_loading)
                  LinearProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
                if (data != null) ...[
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
                        tooltip: 'Semana anterior',
                        onPressed: () => _selectDate(
                          DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day - 7,
                          ),
                        ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          _weekLabel,
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
                        tooltip: 'Semana siguiente',
                        onPressed: () => _selectDate(
                          DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day + 7,
                          ),
                        ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AgendaWeekSelector(
                    selectedDate: _selectedDate,
                    activities: data.activities,
                    onSelected: _selectDate,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: MetricSummaryCard(
                          onTap: () => widget.onAgenda(
                            _selectedDate,
                            data.callsToday
                                .where(
                                  (a) => a.status == AgendaStatus.completed,
                                )
                                .map((a) => a.id)
                                .whereType<int>()
                                .toSet(),
                            'Seguimientos realizados',
                          ),
                          metric: DashboardMetric(
                            value: data.completed,
                            title: 'Seguimientos\nRealizados',
                            backgroundColor: AppColors.homeGreenCard,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: MetricSummaryCard(
                          onTap: () => widget.onAgenda(
                            _selectedDate,
                            data.callsToday
                                .where(data.isOpen)
                                .map((a) => a.id)
                                .whereType<int>()
                                .toSet(),
                            'Seguimientos pendientes',
                          ),
                          metric: DashboardMetric(
                            value: data.pending,
                            title: 'Seguimientos\nPendientes',
                            backgroundColor: AppColors.homeYellowCard,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _activitySection(
                    'Prospectos del día',
                    AppColors.homeOrangeSection,
                    data.todayActivities,
                    data,
                  ),
                  const SizedBox(height: 20),
                  _section(
                    'Prospectos nuevos',
                    AppColors.homeBlueSection,
                    data.newProspects,
                    add: true,
                  ),
                  const SizedBox(height: 20),
                  _activitySection(
                    'Seguimientos atrasados',
                    AppColors.homeRedSection,
                    data.overdueCalls,
                    data,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
