import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
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
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.fieldFill,
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
                          ? palette.navSelectedFill
                          : Colors.transparent,
                      foregroundColor: period == selected
                          ? palette.navSelectedForeground
                          : palette.fieldForeground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'SulphurPoint',
                        fontSize: 18,
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
}
