import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_widgets.dart';
import 'package:callerapp_frontend/presentation/widgets/home/home_dashboard_widgets.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

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
  AgendaStatus? _status;

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
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.homeBackground,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: agendaHeadingStyle.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 12),
              Text(activity.prospect, style: agendaHeadingStyle),
              Text(
                '${_dayLabel(activity.date)} · ${TimeOfDay.fromDateTime(activity.date).format(context)}',
              ),
              const SizedBox(height: 12),
              Text(activity.description),
              const SizedBox(height: 12),
              Text('Estado: ${activity.status.label}'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        _activities
            .where(
              (activity) =>
                  DateUtils.isSameDay(activity.date, _date) &&
                  (_status == null || activity.status == _status),
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
                  PopupMenuButton<String>(
                    tooltip: 'Filtrar actividades',
                    initialValue: _status?.name ?? 'all',
                    icon: Icon(
                      _status == null ? Icons.tune : Icons.filter_alt,
                      color: AppColors.primaryColor,
                    ),
                    onSelected: (value) => setState(
                      () => _status = value == 'all'
                          ? null
                          : AgendaStatus.values.byName(value),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'all', child: Text('Todas')),
                      ...AgendaStatus.values.map(
                        (status) => PopupMenuItem(
                          value: status.name,
                          child: Text(status.label),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_status != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    label: Text(_status!.label),
                    onDeleted: () => setState(() => _status = null),
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
                          _status = null;
                        }),
                        child: const Text('Volver a hoy'),
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
