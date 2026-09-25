import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';

class AgendaPeriodSelector extends StatelessWidget {
  final AgendaPeriod selected;
  final ValueChanged<AgendaPeriod> onSelected;

  const AgendaPeriodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.primaryColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: AgendaPeriod.values
          .map(
            (period) => Expanded(
              child: Semantics(
                selected: period == selected,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: period == selected
                        ? AppColors.primaryColor
                        : Colors.transparent,
                    foregroundColor: period == selected
                        ? AppColors.homeWarmText
                        : AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'SulphurPoint',
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () => onSelected(period),
                  child: Text(switch (period) {
                    AgendaPeriod.day => 'Día',
                    AgendaPeriod.week => 'Semana',
                    AgendaPeriod.month => 'Mes',
                  }),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}
