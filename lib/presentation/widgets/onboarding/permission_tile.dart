import 'package:callerapp_frontend/presentation/widgets/app_press_bounce.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:flutter/material.dart';

class PermissionTile extends StatelessWidget {
  const PermissionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
    required this.busy,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool granted;
  final bool busy;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.surfaceContainerHighest,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: profileHeading.copyWith(
                      fontSize: 18,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description),
                  const SizedBox(height: 10),
                  if (granted)
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: colors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'PERMITIDO',
                          style: profileHeading.copyWith(
                            fontSize: 16,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppPressBounce(
                          enabled: !busy,
                          child: FilledButton(
                            onPressed: busy ? null : onRequest,
                            child: Text(busy ? 'SOLICITANDO…' : 'PERMITIR'),
                          ),
                        ),
                        AppPressBounce(
                          child: TextButton(
                            onPressed: onOpenSettings,
                            child: const Text('AJUSTES'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
