import 'package:callerapp_frontend/presentation/models/prospect_email_models.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:flutter/material.dart';

class ProspectEmailOptionsSheet extends StatelessWidget {
  const ProspectEmailOptionsSheet({super.key, required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enviar correo',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontFamily: 'BebasNeue'),
            ),
            const SizedBox(height: 4),
            Text(
              email.isEmpty
                  ? 'Este prospecto no tiene correo registrado.'
                  : 'Se enviará a $email',
            ),
            const SizedBox(height: 12),
            for (final template in ProspectEmailTemplate.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: email.isEmpty
                        ? null
                        : () => Navigator.pop(context, template),
                    icon: const Icon(Icons.mail_outline),
                    label: Text(template.label),
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.secondaryActionFill,
                      foregroundColor: palette.secondaryActionForeground,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
