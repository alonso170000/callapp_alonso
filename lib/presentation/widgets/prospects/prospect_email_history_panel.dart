import 'package:callerapp_frontend/presentation/models/prospect_history_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:flutter/material.dart';

class ProspectEmailHistoryPanel extends StatelessWidget {
  const ProspectEmailHistoryPanel({
    super.key,
    required this.emails,
    this.error,
    this.onRetry,
  });
  final List<ProspectEmailHistoryEntry> emails;
  final String? error;
  final VoidCallback? onRetry;

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}\n${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ProspectDetailPanel(
      title: 'Historial de correos',
      color: AppColors.prospectHistoryHeader,
      nested: true,
      initiallyExpanded: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: palette.historySurfaceFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: error != null
            ? Column(
                children: [
                  Text(error!),
                  if (onRetry != null)
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Reintentar'),
                    ),
                ],
              )
            : emails.isEmpty
            ? Text(
                'Aún no se han enviado correos.',
                style: TextStyle(color: palette.historySurfaceInk),
              )
            : Column(
                children: emails
                    .map(
                      (email) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: palette.historyCardFill,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.mail_outline,
                                color: palette.historyCardInk,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      email.templateName.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'BebasNeue',
                                        fontSize: 17,
                                        color: palette.historyCardInk,
                                      ),
                                    ),
                                    Text(email.description),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _date(email.sentAt),
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }
}
