import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/sync_models.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';

class SyncConflictsSheet extends StatefulWidget {
  const SyncConflictsSheet({
    super.key,
    required this.conflicts,
    required this.onRetry,
    required this.onDiscard,
  });

  final List<SyncConflictViewData> conflicts;
  final Future<void> Function(int id) onRetry;
  final Future<void> Function(int id) onDiscard;

  @override
  State<SyncConflictsSheet> createState() => _SyncConflictsSheetState();
}

class _SyncConflictsSheetState extends State<SyncConflictsSheet> {
  int? _workingId;
  String? _error;

  Future<void> _run(int id, Future<void> Function(int) action) async {
    if (_workingId != null) return;
    setState(() {
      _workingId = id;
      _error = null;
    });
    try {
      await action(id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'No se pudo resolver el conflicto. Intenta nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.all(AppStyles.spacingLarge(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'CONFLICTOS DE SINCRONIZACIÓN',
              style: agendaHeadingStyle.copyWith(color: colors.primary),
            ),
            SizedBox(height: AppStyles.spacingSmall(context)),
            Text(
              'El servidor rechazó estos cambios. Puedes reintentarlos o conservar la versión del servidor.',
            ),
            if (_error != null) ...[
              SizedBox(height: AppStyles.spacingSmall(context)),
              Text(_error!, style: TextStyle(color: colors.error)),
            ],
            SizedBox(height: AppStyles.spacingMedium(context)),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.conflicts.length,
                separatorBuilder: (_, _) =>
                    SizedBox(height: AppStyles.spacingSmall(context)),
                itemBuilder: (context, index) {
                  final conflict = widget.conflicts[index];
                  final working = _workingId == conflict.id;
                  return Card(
                    color: colors.errorContainer,
                    child: Padding(
                      padding: EdgeInsets.all(AppStyles.spacingMedium(context)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            conflict.title,
                            style: TextStyle(
                              fontFamily: 'BebasNeue',
                              fontSize: AppStyles.textButtom(context),
                            ),
                          ),
                          Text(conflict.message),
                          Text('Intentos: ${conflict.attemptCount}'),
                          SizedBox(height: AppStyles.spacingSmall(context)),
                          Wrap(
                            spacing: AppStyles.spacingSmall(context),
                            runSpacing: AppStyles.spacingSmall(context),
                            children: [
                              OutlinedButton(
                                onPressed: _workingId == null
                                    ? () => _run(conflict.id, widget.onDiscard)
                                    : null,
                                child: const Text('USAR VERSIÓN DEL SERVIDOR'),
                              ),
                              FilledButton(
                                onPressed: _workingId == null
                                    ? () => _run(conflict.id, widget.onRetry)
                                    : null,
                                child: Text(
                                  working ? 'PROCESANDO…' : 'REINTENTAR',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
