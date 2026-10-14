import 'package:flutter/material.dart';
import 'package:callerapp_frontend/services/appearance_controller.dart';

class AppearanceSheet extends StatelessWidget {
  const AppearanceSheet({super.key, required this.controller});
  final AppearanceController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'APARIENCIA',
              style: TextStyle(fontFamily: 'BebasNeue', fontSize: 26),
            ),
            const Text(
              'Sistema utiliza el modo claro u oscuro de tu dispositivo.',
              textAlign: TextAlign.center,
            ),
            if (controller.loading || controller.saving)
              const LinearProgressIndicator(),
            if (controller.error != null) ...[
              Text(
                controller.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton(
                onPressed: controller.saving ? null : controller.reload,
                child: const Text('Reintentar'),
              ),
            ],
            for (final value in AppAppearance.values)
              ListTile(
                enabled: !controller.saving && !controller.loading,
                leading: Icon(switch (value) {
                  AppAppearance.light => Icons.light_mode_outlined,
                  AppAppearance.dark => Icons.dark_mode_outlined,
                  AppAppearance.system => Icons.brightness_auto_outlined,
                }),
                title: Text(value.label),
                trailing: controller.appearance == value
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () async {
                  try {
                    await controller.select(value);
                  } on AppearanceException {
                    return;
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    ),
  );
}
