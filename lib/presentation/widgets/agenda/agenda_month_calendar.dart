import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/services/business_clock.dart';

class AgendaMonthCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final List<AgendaActivity> activities;
  final ValueChanged<DateTime> onSelected;

  const AgendaMonthCalendar({
    super.key,
    required this.selectedDate,
    required this.activities,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final palette = AppPalette.of(context);
    final first = DateTime(selectedDate.year, selectedDate.month);
    final offset = first.weekday - 1;
    final days = DateTime(first.year, first.month + 1, 0).day;
    final weeks = ((offset + days) / 7).ceil();
    final activityDates = activities
        .map((item) => DateUtils.dateOnly(item.date))
        .toSet();
    final today = DateUtils.dateOnly(businessNow());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: palette.calendarSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: labels
                .map(
                  (label) => Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SulphurPoint',
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          ...List.generate(
            weeks,
            (week) => Row(
              children: List.generate(7, (weekday) {
                final date = DateTime(
                  first.year,
                  first.month,
                  1 - offset + week * 7 + weekday,
                );
                final selected = DateUtils.isSameDay(date, selectedDate);
                final isToday = DateUtils.isSameDay(date, today);
                final inMonth = date.month == first.month;
                final hasActivities = activityDates.contains(date);
                final foreground = selected
                    ? palette.selectedForeground
                    : isToday
                    ? palette.todayForeground
                    : Theme.of(context).colorScheme.primary
                          .withValues(alpha: inMonth ? 1 : 0.35);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Semantics(
                      button: true,
                      selected: selected,
                      label:
                          '${date.day}/${date.month}/${date.year}${hasActivities ? ', con actividades' : ', sin actividades'}',
                      excludeSemantics: true,
                      child: Material(
                        key: isToday
                            ? const ValueKey('agenda-month-today')
                            : null,
                        color: selected
                            ? palette.selectedFill
                            : isToday
                            ? palette.todayFill
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: selected
                              ? BorderSide.none
                              : isToday
                              ? BorderSide(color: palette.todayBorder, width: 2)
                              : BorderSide.none,
                        ),
                        child: InkWell(
                          key: ValueKey(
                            'agenda-month-${date.year}-${date.month}-${date.day}',
                          ),
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => onSelected(date),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Column(
                              children: [
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontFamily: 'SulphurPoint',
                                    fontSize: 18,
                                    color: foreground,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  key: hasActivities
                                      ? ValueKey(
                                          'agenda-month-activity-${date.year}-${date.month}-${date.day}',
                                        )
                                      : null,
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: !hasActivities
                                        ? Colors.transparent
                                        : selected
                                        ? palette.activityDotSelected
                                        : palette.activityDot,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
