import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/sync_models.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';

class SyncPendingSheet extends StatefulWidget {
  const SyncPendingSheet({
    super.key,
    required this.issues,
    required this.onRetry,
  });

  final List<SyncPendingViewData> issues;
  final Future<void> Function(int id) onRetry;

  @override
  State<SyncPendingSheet> createState() => _SyncPendingSheetState();
}

class _SyncPendingSheetState extends State<SyncPendingSheet> {
  int? _workingId;
  String? _error;

  Future<void> _run(int id) async {
    if (_workingId != null) return;
    setState(() {
      _workingId = id;
      _error = null;
    });
    try {
      await widget.onRetry(id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo reintentar el cambio. Intenta nuevamente.',
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
              'CAMBIOS SIN SINCRONIZAR',
              style: agendaHeadingStyle.copyWith(color: colors.primary),
            ),
            SizedBox(height: AppStyles.spacingSmall(context)),
            const Text(
              'Estos cambios todavía no llegan al servidor. Revisa el motivo y reintenta.',
            ),
            if (_error != null) ...[
              SizedBox(height: AppStyles.spacingSmall(context)),
              Text(_error!, style: TextStyle(color: colors.error)),
            ],
            SizedBox(height: AppStyles.spacingMedium(context)),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.issues.length,
                separatorBuilder: (_, _) =>
                    SizedBox(height: AppStyles.spacingSmall(context)),
                itemBuilder: (context, index) {
                  final issue = widget.issues[index];
                  final working = _workingId == issue.id;
                  return Card(
                    color: colors.primaryContainer,
                    child: Padding(
                      padding: EdgeInsets.all(AppStyles.spacingMedium(context)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            issue.title,
                            style: TextStyle(
                              fontFamily: 'BebasNeue',
                              fontSize: AppStyles.textButtom(context),
                            ),
                          ),
                          Text(issue.message),
                          Text('Intentos: ${issue.attemptCount}'),
                          SizedBox(height: AppStyles.spacingSmall(context)),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: _workingId == null
                                  ? () => _run(issue.id)
                                  : null,
                              child: Text(
                                working ? 'PROCESANDO…' : 'REINTENTAR',
                              ),
                            ),
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
