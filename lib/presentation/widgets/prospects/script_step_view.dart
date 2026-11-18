import 'package:callerapp_frontend/presentation/widgets/app_press_bounce.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/models/guion_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/call_script_components.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:callerapp_frontend/services/script_template.dart';

class ScriptStepView extends StatelessWidget {
  const ScriptStepView({
    super.key,
    required this.paso,
    required this.canGoBack,
    required this.onBack,
    required this.onNavigate,
    required this.onRestart,
    required this.prospectName,
    required this.asesorName,
    this.desarrolloName,
  });
  final GuionPaso paso;
  final bool canGoBack;
  final VoidCallback onBack;
  final ValueChanged<int> onNavigate;
  final VoidCallback onRestart;
  final String prospectName;
  final String asesorName;
  final String? desarrolloName;
  String _render(String text) => renderScriptText(
    text,
    nombre: prospectName,
    asesor: asesorName,
    desarrollo: desarrolloName,
  );
  IconData? _icon(String? icon) => switch (icon) {
    'inversion' => Iconsax.chart_2_copy,
    'vivienda' => Iconsax.home_2_copy,
    'renta' => Iconsax.key_copy,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final renderedContent = _render(paso.contenido);
    final renderedNote = paso.notaAsesor == null
        ? null
        : _render(paso.notaAsesor!);
    final renderedBullets = paso.vinetas.map(_render).toList();
    final unresolved =
        hasUnresolvedVariables(renderedContent) ||
        (renderedNote != null && hasUnresolvedVariables(renderedNote)) ||
        renderedBullets.any(hasUnresolvedVariables);
    final note = renderedNote == null || renderedNote.trim().isEmpty
        ? null
        : CallScriptNote(text: renderedNote);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (canGoBack)
              Semantics(
                label: 'Volver al paso anterior',
                button: true,
                child: AppPressBounce(
                  child: IconButton(
                    tooltip: 'Volver al paso anterior',
                    onPressed: onBack,
                    icon: const Icon(Iconsax.arrow_left_copy),
                  ),
                ),
              ),
            Expanded(
              child: Text(
                paso.titulo,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (paso.notaPosicion == 'antes' && note != null) ...[
          note,
          const SizedBox(height: 8),
        ],
        for (final paragraph in renderedContent.split(RegExp(r'\n\s*\n'))) ...[
          CallScriptSpeech(text: paragraph),
          const SizedBox(height: 8),
        ],
        if (renderedBullets.isNotEmpty) ...[
          CallScriptBenefits(items: renderedBullets),
          const SizedBox(height: 8),
        ],
        if (paso.notaPosicion != 'antes' && note != null) ...[
          note,
          const SizedBox(height: 8),
        ],
        if (unresolved) ...[
          const CallScriptNote(
            text: 'Sustituye las variables entre llaves antes de leer.',
          ),
          const SizedBox(height: 8),
        ],
        if (paso.opciones.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 10,
              runSpacing: 8,
              children: paso.opciones
                  .map(
                    (option) => SizedBox(
                      width: constraints.maxWidth < 360
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 10) / 2,
                      child: AppPressBounce(
                        child: OutlinedButton.icon(
                          style: callScriptButtonStyle(AppColors.scriptBlue),
                          onPressed: () => onNavigate(option.siguientePasoId),
                          icon: _icon(option.icono) == null
                              ? const SizedBox.shrink()
                              : Icon(_icon(option.icono)),
                          label: Text(
                            option.etiqueta,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
        else if (paso.siguientePasoId != null)
          SizedBox(
            width: double.infinity,
            child: AppPressBounce(
              child: FilledButton.icon(
                style: callScriptButtonStyle(AppColors.scriptBlue),
                onPressed: () => onNavigate(paso.siguientePasoId!),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Iconsax.arrow_right_3_copy),
                label: const Text('SEGUIR LEYENDO'),
              ),
            ),
          )
        else
          Center(
            child: Column(
              children: [
                const Text('Fin del guion'),
                AppPressBounce(
                  child: TextButton(
                    onPressed: onRestart,
                    child: const Text('Volver al inicio'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
