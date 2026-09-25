import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';

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
    const labels = ['Lun', 'Mar', 'MiÃ©', 'Jue', 'Vie', 'SÃ¡b', 'Dom'];
    final start = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day - selectedDate.weekday + 1,
    );
    return Row(
      children: List.generate(7, (index) {
        final date = DateTime(start.year, start.month, start.day + index);
        final selected = DateUtils.isSameDay(date, selectedDate);
        final daily = activities.where(
          (item) => DateUtils.isSameDay(item.date, date),
        );
        final completed =
            daily.isNotEmpty &&
            daily.every((item) => item.status == AgendaStatus.completed);
        final foreground = selected
            ? AppColors.homeBackground
            : AppColors.primaryColor;
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
                color: selected ? AppColors.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
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
                            fontSize: 12,
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
                        Icon(
                          daily.isEmpty
                              ? Icons.remove_rounded
                              : completed
                              ? Icons.task_alt_rounded
                              : Icons.update_rounded,
                          size: 17,
                          color: selected
                              ? AppColors.homeWarmText
                              : completed
                              ? const Color(0xFF55AD62)
                              : AppColors.primaryColor.withValues(alpha: 0.65),
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
    );
  }
}
