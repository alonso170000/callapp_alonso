import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    super.key,
    required this.pendingCount,
    required this.conflictCount,
    required this.syncing,
    required this.onSync,
    required this.onConflicts,
    required this.onPending,
  });

  final int pendingCount;
  final int conflictCount;
  final bool syncing;
  final VoidCallback onSync;
  final VoidCallback onConflicts;
  final VoidCallback onPending;

  @override
  Widget build(BuildContext context) {
    if (pendingCount == 0 && conflictCount == 0 && !syncing) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    final hasConflicts = conflictCount > 0;
    final title = hasConflicts
        ? '$conflictCount ${conflictCount == 1 ? 'conflicto requiere' : 'conflictos requieren'} atención'
        : syncing
        ? 'Sincronizando cambios…'
        : '$pendingCount ${pendingCount == 1 ? 'cambio pendiente' : 'cambios pendientes'}';
    return Semantics(
      container: true,
      label: title,
      child: Card(
        color: hasConflicts ? colors.errorContainer : colors.primaryContainer,
        child: Padding(
          padding: EdgeInsets.all(AppStyles.spacingMedium(context)),
          child: Wrap(
            spacing: AppStyles.spacingSmall(context),
            runSpacing: AppStyles.spacingSmall(context),
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (syncing)
                SizedBox.square(
                  dimension: AppStyles.spacingLarge(context),
                  child: CircularProgressIndicator(
                    strokeWidth: AppStyles.spacingTiny(context) / 2,
                  ),
                )
              else
                Icon(
                  hasConflicts
                      ? Icons.sync_problem_rounded
                      : Icons.cloud_upload_outlined,
                  color: hasConflicts
                      ? colors.onErrorContainer
                      : colors.onPrimaryContainer,
                ),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'SulphurPoint',
                  fontWeight: FontWeight.w800,
                  color: hasConflicts
                      ? colors.onErrorContainer
                      : colors.onPrimaryContainer,
                ),
              ),
              if (hasConflicts)
                TextButton(onPressed: onConflicts, child: const Text('REVISAR'))
              else if (pendingCount > 0)
                TextButton(
                  onPressed: onPending,
                  child: const Text('VER DETALLE'),
                ),
              FilledButton.tonal(
                onPressed: syncing || pendingCount == 0 ? null : onSync,
                child: Text(syncing ? 'SINCRONIZANDO…' : 'SINCRONIZAR AHORA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
