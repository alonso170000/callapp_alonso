import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:flutter/material.dart';

class ConvertProspectSheet extends StatelessWidget {
  const ConvertProspectSheet({super.key, required this.prospect});
  final ProspectRecord prospect;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            prospect.isClient ? 'Ya es cliente' : 'Convertir en cliente',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'BebasNeue', fontSize: 28),
          ),
          const SizedBox(height: 10),
          Text(
            prospect.isClient
                ? '${prospect.name} ya cuenta con un expediente de cliente.'
                : 'Se creará un expediente de cliente con los datos actuales de ${prospect.name}. ¿Deseas continuar?',
            textAlign: TextAlign.center,
          ),
          if (!prospect.isClient) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('CANCELAR'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('CONVERTIR'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
