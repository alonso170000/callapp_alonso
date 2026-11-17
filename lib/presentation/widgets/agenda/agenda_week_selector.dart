import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
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

  Future<void> _showTodayAction(BuildContext context, DateTime today) async {
    final itemBox = context.findRenderObject() as RenderBox;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = itemBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final selected = await showMenu<bool>(
      context: context,
      position: RelativeRect.fromRect(
        offset & itemBox.size,
        Offset.zero & overlayBox.size,
      ),
      items: const [
        PopupMenuItem<bool>(value: true, child: Text('Regresar a hoy')),
      ],
    );
    if (selected == true) onSelected(today);
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    final palette = AppPalette.of(context);
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
          (item) =>
              DateUtils.isSameDay(item.date, date) &&
              item.status != AgendaStatus.cancelled,
        );
        final completed =
            daily.isNotEmpty &&
            daily.every((item) => item.status == AgendaStatus.completed);
        final foreground = selected
            ? palette.selectedForeground
            : isToday
            ? palette.todayForeground
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
                child: Builder(
                  builder: (dayContext) => InkWell(
                    key: ValueKey('agenda-week-day-$index'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onSelected(date),
                    onLongPress: () => _showTodayAction(dayContext, today),
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
                                  ? palette.activityDotSelected
                                  : completed
                                  ? palette.completedIcon
                                  : palette.pendingIcon,
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
          ),
        );
      }),
    );
  }
}
