import 'package:callerapp_frontend/presentation/models/call_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_history_models.dart';
import 'package:callerapp_frontend/presentation/widgets/app_press_bounce.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class ProspectCallEffectivenessCard extends StatelessWidget {
  const ProspectCallEffectivenessCard({super.key, required this.summary});

  final ProspectCallSummary summary;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final totalLabel = summary.total == 1
        ? '1 llamada registrada'
        : '${summary.total} llamadas registradas';
    return Semantics(
      label:
          'Llamadas contestadas: ${summary.answered} de ${summary.total}, '
          '${summary.answeredPercent} por ciento. No contestadas: '
          '${summary.unanswered} de ${summary.total}, '
          '${summary.unansweredPercent} por ciento.',
      excludeSemantics: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.historyCardFill,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.prospectCallHighlight,
                  ),
                  child: const Icon(
                    Iconsax.call_calling_copy,
                    size: 20,
                    color: AppColors.textDarkColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Resumen de llamadas',
                          style: TextStyle(
                            fontFamily: 'BebasNeue',
                            fontSize: 18,
                            color: palette.historyCardInk,
                          ),
                        ),
                      ),
                      Text(
                        totalLabel,
                        style: TextStyle(
                          fontFamily: 'SulphurPoint',
                          fontSize: 12,
                          color: palette.historySurfaceInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CallCounter(
                    value: summary.answered,
                    label: 'Contestó',
                    color: AppColors.prospectCallAnswered,
                    labelColor: palette.historySurfaceInk,
                  ),
                ),
                Expanded(
                  child: _CallCounter(
                    value: summary.unanswered,
                    label: 'No contestó',
                    color: AppColors.prospectCallUnanswered,
                    labelColor: palette.historySurfaceInk,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${summary.answeredPercent}%',
                  style: TextStyle(
                    fontFamily: 'SulphurPoint',
                    fontSize: 12,
                    color: palette.historySurfaceInk,
                  ),
                ),
                Text(
                  '${summary.unansweredPercent}%',
                  style: TextStyle(
                    fontFamily: 'SulphurPoint',
                    fontSize: 12,
                    color: palette.historySurfaceInk,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 12,
                child: summary.isEmpty
                    ? ColoredBox(color: palette.historyCardFill)
                    : Row(
                        children: [
                          if (summary.answered > 0)
                            Expanded(
                              flex: summary.answered,
                              child: const SizedBox.expand(
                                key: ValueKey('call-summary-answered-bar'),
                                child: ColoredBox(
                                  color: AppColors.prospectCallAnswered,
                                ),
                              ),
                            ),
                          if (summary.unanswered > 0)
                            Expanded(
                              flex: summary.unanswered,
                              child: const SizedBox.expand(
                                key: ValueKey('call-summary-unanswered-bar'),
                                child: ColoredBox(
                                  color: AppColors.prospectCallUnanswered,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallCounter extends StatelessWidget {
  const _CallCounter({
    required this.value,
    required this.label,
    required this.color,
    required this.labelColor,
  });

  final int value;
  final String label;
  final Color color;
  final Color labelColor;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        '$value',
        style: TextStyle(fontFamily: 'BebasNeue', fontSize: 30, color: color),
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontFamily: 'SulphurPoint',
            fontSize: 13,
            color: labelColor,
          ),
        ),
      ),
    ],
  );
}

class ProspectCallHistoryPanel extends StatelessWidget {
  const ProspectCallHistoryPanel({
    super.key,
    required this.calls,
    required this.loading,
    this.error,
    this.onRetry,
    this.initiallyExpanded = true,
  });

  final List<ProspectCallRecord> calls;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ProspectDetailPanel(
      title: 'Efectividad de contactos',
      color: AppColors.prospectHistoryHeader,
      nested: true,
      initiallyExpanded: initiallyExpanded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: palette.historySurfaceFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _content(palette),
      ),
    );
  }

  Widget _content(AppPalette palette) {
    if (loading) {
      return const SizedBox(
        height: 90,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.authPanelTop),
        ),
      );
    }
    if (error != null) {
      return Column(
        children: [
          Text(error!, style: TextStyle(color: palette.historySurfaceInk)),
          if (onRetry != null)
            AppPressBounce(
              child: TextButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ),
        ],
      );
    }
    if (calls.isEmpty) {
      return Text(
        'Aún no se han registrado llamadas.',
        style: TextStyle(color: palette.historySurfaceInk),
      );
    }
    return ProspectCallEffectivenessCard(
      summary: ProspectCallSummary.fromRecords(calls),
    );
  }
}
