import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/guion_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/script_accordion.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class ProspectScriptsPanel extends StatelessWidget {
  const ProspectScriptsPanel({
    super.key,
    required this.guiones,
    required this.loading,
    required this.error,
    required this.offline,
    required this.onRetry,
    required this.prospectName,
    required this.asesorName,
    this.desarrolloName,
    this.emptyMessage,
  });
  final GuionesBundle? guiones;
  final bool loading;
  final String? error;
  final bool offline;
  final VoidCallback onRetry;
  final String prospectName;
  final String asesorName;
  final String? desarrolloName;
  final String? emptyMessage;
  @override
  Widget build(BuildContext context) {
    if (loading && guiones == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 12),
            Text('Cargando guiones…'),
          ],
        ),
      );
    }
    if (error != null && guiones == null) {
      return Center(
        child: Column(
          children: [
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    final scripts = guiones?.guiones ?? const <Guion>[];
    if (scripts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            emptyMessage ?? 'Este desarrollo aún no tiene guiones publicados.',
          ),
        ),
      );
    }
    return Column(
      children: [
        if (offline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.scriptNote,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Sin conexión · guion guardado',
              textAlign: TextAlign.center,
            ),
          ),
        for (var index = 0; index < scripts.length; index++) ...[
          ScriptAccordion(
            key: ValueKey(scripts[index].id),
            guion: scripts[index],
            index: index,
            prospectName: prospectName,
            asesorName: asesorName,
            desarrolloName: desarrolloName,
          ),
          if (index < scripts.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}
