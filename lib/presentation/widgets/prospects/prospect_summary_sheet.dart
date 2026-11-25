import 'package:callerapp_frontend/presentation/widgets/app_press_bounce.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';

class ProspectSummarySheet extends StatelessWidget {
  const ProspectSummarySheet({super.key, required this.prospect});
  final ProspectRecord prospect;

  @override
  Widget build(BuildContext context) {
    final date = prospect.assignedAt;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              prospect.name.toUpperCase(),
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 28,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            for (final entry in {
              'Estatus': prospect.status,
              'Ciudad': prospect.city,
              'Canal': prospect.origin,
              'Teléfono': prospect.phone.isEmpty
                  ? 'Sin teléfono'
                  : prospect.phone,
              'Correo': prospect.email.isEmpty ? 'Sin correo' : prospect.email,
              'Prioridad': prospect.temperature,
              'Asignación': date == null
                  ? 'Sin fecha de asignación'
                  : '${date.day}/${date.month}/${date.year}',
              if (prospect.assignedBy != null)
                'Asignado por': prospect.assignedBy!,
            }.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(
                    fontFamily: 'SulphurPoint',
                    fontSize: 18,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            Text(
              prospect.note,
              style: TextStyle(
                fontFamily: 'SulphurPoint',
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            AppPressBounce(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
