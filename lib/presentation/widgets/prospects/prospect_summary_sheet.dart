import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class ProspectSummarySheet extends StatelessWidget {
  const ProspectSummarySheet({super.key, required this.prospect});
  final ProspectRecord prospect;

  @override
  Widget build(BuildContext context) {
    final date = prospect.assignedAt;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              prospect.name.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 28,
                color: AppColors.primaryColor,
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
            }.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(
                    fontFamily: 'SulphurPoint',
                    fontSize: 18,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            Text(
              prospect.note,
              style: TextStyle(
                fontFamily: 'SulphurPoint',
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}
