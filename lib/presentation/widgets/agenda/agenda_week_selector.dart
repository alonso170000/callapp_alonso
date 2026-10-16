import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/services/business_clock.dart';

class AgendaWeekSelector extends StatelessWidget {
  final DateTime selectedDate;
  final List<AgendaActivity> activities;
  final ValueChanged<DateTime> onSelected;

  const AgendaWeekSelector({
    super.key,
    required this.selectedDate,
    required this.activities,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'SÃ¡b', 'Dom'];
    final start = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day - selectedDate.weekday + 1,
    );
    final today = DateUtils.dateOnly(businessNow());
    return Row(
      children: List.generate(7, (index) {
        final date = DateTime(start.year, start.month, start.day + index);
        final selected = DateUtils.isSameDay(date, selectedDate);
        final isToday = DateUtils.isSameDay(date, today);
        final daily = activities.where(
          (item) => DateUtils.isSameDay(item.date, date),
        );
        final completed =
            daily.isNotEmpty &&
            daily.every((item) => item.status == AgendaStatus.completed);
        final foreground = selected
            ? AppColors.homeBackground
            : Theme.of(context).colorScheme.primary;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Semantics(
              button: true,
              selected: selected,
              label:
                  '${labels[index]} ${date.day}/${date.month}/${date.year}, ${daily.length} actividades',
              excludeSemantics: true,
              child: Material(
                key: isToday ? const ValueKey('agenda-week-today') : null,
                color: selected
                    ? AppColors.primaryColor
                    : isToday
                    ? AppColors.homeGreenToday
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: isToday
                      ? const BorderSide(
                          color: AppColors.homeGreenToday,
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                child: InkWell(
                  key: ValueKey('agenda-week-day-$index'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onSelected(date),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Column(
                      children: [
                        Text(
                          labels[index],
                          style: TextStyle(
                            fontFamily: 'SulphurPoint',
                            fontSize: 14,
                            color: foreground,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontFamily: 'BebasNeue',
                            fontSize: 23,
                            height: 1.1,
                            color: foreground,
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (daily.isNotEmpty)
                          Icon(
                            key: ValueKey(
                              'agenda-week-activity-${date.year}-${date.month}-${date.day}',
                            ),
                            completed
                                ? Icons.task_alt_rounded
                                : Icons.update_rounded,
                            size: 17,
                            color: selected
                                ? AppColors.homeWarmText
                                : completed
                                ? const Color(0xFF55AD62)
                                : AppColors.primaryColor.withValues(
                                    alpha: 0.65,
                                  ),
                          )
                        else
                          const SizedBox(height: 17),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
