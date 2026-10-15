import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/home_models.dart';
import 'package:callerapp_frontend/presentation/models/home_dashboard_data.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

import 'home_dashboard_widgets.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({
    super.key,
    required this.active,
    required this.onAgenda,
    required this.onProspects,
    required this.onAddProspect,
    this.loadActivities,
    this.loadProspects,
  });
  final bool active;
  final void Function(DateTime, Set<int>, String) onAgenda;
  final void Function(Set<int>, String) onProspects;
  final VoidCallback onAddProspect;
  final Future<List<AgendaActivity>> Function()? loadActivities;
  final Future<List<ProspectRecord>> Function()? loadProspects;
  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final _agenda = AgendaService();
  final _prospects = ProspectsService();
  HomeDashboardData? _data;
  bool _loading = true;
  String? _error;
  int _request = 0;
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  void _selectDate(DateTime date) =>
      setState(() => _selectedDate = DateUtils.dateOnly(date));

  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_sessionChanged);
    _load();
  }

  void _sessionChanged() {
    _data = null;
    _load();
  }

  @override
  void didUpdateWidget(covariant HomeDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object>([
        widget.loadProspects?.call() ?? _prospects.fetch(),
        widget.loadActivities?.call() ?? _agenda.fetch(),
      ]);
      if (!mounted || request != _request) return;
      setState(
        () => _data = HomeDashboardData(
          values[0] as List<ProspectRecord>,
          values[1] as List<AgendaActivity>,
          DateTime.now(),
        ),
      );
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(
        () => _error = error is AgendaException
            ? error.message
            : error is ProspectsException
            ? error.message
            : 'No se pudo cargar Inicio. Intenta nuevamente.',
      );
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
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
  @override
  Widget build(BuildContext context) {
    final loaded = _data;
    final data = loaded == null
        ? null
        : HomeDashboardData(
            loaded.prospects,
            loaded.activities,
            DateTime.now(),
            selectedDate: _selectedDate,
          );
    return RefreshIndicator(
      onRefresh: _load,
      backgroundColor: Theme.of(context).colorScheme.surface,
      color: AppColors.primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 118),
            sliver: SliverList.list(
              children: [
                HomeHeader(userName: AuthService.instance.userName),
                if (_loading)
                  LinearProgressIndicator(
                    color: AppColors.primaryColor,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                const SizedBox(height: 6),
                if (_error != null) ...[
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
                if (data != null && _error == null) ...[
                  Row(
                    children: [
                      IconButton(
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
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'SulphurPoint',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
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
                  WeeklyProgressStrip(days: data.week, onSelected: _selectDate),
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
                            'Llamadas realizadas',
                          ),
                          metric: DashboardMetric(
                            value: data.completed,
                            title: 'Llamadas\nRealizadas',
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
                            'Llamadas pendientes',
                          ),
                          metric: DashboardMetric(
                            value: data.pending,
                            title: 'Llamadas\nPendientes',
                            backgroundColor: AppColors.homeYellowCard,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _section(
                    'Prospectos del día',
                    AppColors.homeOrangeSection,
                    data.todayProspects,
                  ),
                  const SizedBox(height: 20),
                  _section(
                    'Prospectos nuevos',
                    AppColors.homeBlueSection,
                    data.newProspects,
                    add: true,
                  ),
                  const SizedBox(height: 20),
                  _section(
                    'Llamadas atrasadas',
                    AppColors.homeRedSection,
                    data.prospectsFor(data.overdueCalls),
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
