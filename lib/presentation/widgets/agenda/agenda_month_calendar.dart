import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';

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
    final first = DateTime(selectedDate.year, selectedDate.month);
    final offset = first.weekday - 1;
    final days = DateTime(first.year, first.month + 1, 0).day;
    final weeks = ((offset + days) / 7).ceil();
    final activityDates = activities
        .map((item) => DateUtils.dateOnly(item.date))
        .toSet();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.05),
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
                      style: const TextStyle(
                        fontFamily: 'SulphurPoint',
                        fontSize: 12,
                        color: AppColors.primaryColor,
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
                final inMonth = date.month == first.month;
                final hasActivities = activityDates.contains(date);
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
                        color: selected
                            ? AppColors.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
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
                                    fontSize: 14,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.primaryColor.withValues(
                                            alpha: inMonth ? 1 : 0.35,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: !hasActivities
                                        ? Colors.transparent
                                        : selected
                                        ? AppColors.homeWarmText
                                        : const Color(0xFFFF4655),
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
