import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/models/call_script_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/call_script_components.dart';

class ProspectFollowUpCallScript extends StatelessWidget {
  final VoidCallback onContinue;

  const ProspectFollowUpCallScript({super.key, required this.onContinue});

  Widget _speech(String text) => CallScriptSpeech(text: text);

  Widget _benefitList(CallScriptBenefitGroup group, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(group.title, style: const TextStyle(fontSize: 14)),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: group.items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Iconsax.tick_circle_copy,
                        size: 17,
                        color: Color(0xFF006B61),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(item, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ],
  );

  Widget _category(CallScriptBenefitGroup group) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF8B8329),
      borderRadius: BorderRadius.circular(7),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          color: const Color(0xFF62352D),
          child: Text(
            group.title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            group.items.join(',\n'),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ProspectDetailPanel(
    title: 'Llamada 2',
    color: const Color(0xFF786B20),
    nested: true,
    initiallyExpanded: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBC6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Llamada de Seguimiento (Día 2)',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF665000),
            ),
          ),
          const SizedBox(height: 12),
          _speech(
            'Hola buen día Sr(a). Cesar Martinez Dorado, ¿Cómo está? '
            'Habla Miguel Jurado.\n\n'
            'Hablamos el día de ayer y le envié la información del desarrollo '
            'RUNA YUCATÁN, dígame... ¿Encontró alguna ubicación de su agrado?',
          ),
          const SizedBox(height: 12),
          const CallScriptNote(
            text:
                '¿Qué preguntas tiene?\n'
                '(Resuelve dudas antes de pasar a la corrida financiera).',
          ),
          const SizedBox(height: 12),
          _speech(
            'Me gustaría comentarle de nuevo que no solo es un terreno; la '
            'inversión le incluye un proyecto completo con alta plusvalía y '
            'en armonía con el medio ambiente:',
          ),
          const SizedBox(height: 12),
          CallScriptColumns(
            children: [
              _benefitList(demoFollowUpIncludes, const Color(0xFF9BF5EB)),
              _benefitList(demoFollowUpBenefits, const Color(0xFFA9F6AC)),
            ],
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '“Inversión inteligente en un proyecto completo”',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF665000),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          CallScriptColumns(
            children: demoFollowUpCategories.map(_category).toList(),
          ),
          const SizedBox(height: 12),
          _speech(
            'Contamos con 0% impacto ecológico y cultura verde. El uso de '
            'suelo es habitacional con límite de construcción del 50%, '
            'garantizando plusvalía y cero contaminación visual.',
          ),
          const SizedBox(height: 12),
          _speech('¿Desea que comencemos a construir su sueño hoy mismo?'),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: callScriptButtonStyle(const Color(0xFF008A98)),
              onPressed: () {
                onContinue();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Continuación al cierre registrada.'),
                  ),
                );
              },
              child: const Text('CONTINUAR AL CIERRE'),
            ),
          ),
        ],
      ),
    ),
  );
}
