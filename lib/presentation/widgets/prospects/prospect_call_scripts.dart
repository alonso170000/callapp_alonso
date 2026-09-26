import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/call_script_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';

class ProspectCallScripts extends StatefulWidget {
  final CallScript script;

  const ProspectCallScripts({super.key, required this.script});

  @override
  State<ProspectCallScripts> createState() => _ProspectCallScriptsState();
}

class _ProspectCallScriptsState extends State<ProspectCallScripts> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final current = widget.script.steps[_step];
    final canGoBack = _step > 0;
    final canGoNext = _step < widget.script.steps.length - 1;

    return ProspectDetailPanel(
      title: widget.script.title,
      color: const Color(0xFF786B20),
      nested: true,
      initiallyExpanded: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 9, 8, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBC6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(current.title, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B8329),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                current.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'SulphurPoint',
                  fontSize: 15,
                  height: 1.22,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B8329),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 16),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      current.instruction,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'BebasNeue',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5C5C5C),
                      disabledBackgroundColor: const Color(0xFF8A8A8A),
                    ),
                    onPressed: canGoBack ? () => setState(() => _step--) : null,
                    child: const Text('ANTERIOR'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF008A98),
                      disabledBackgroundColor: const Color(0xFF73B9BE),
                    ),
                    onPressed: canGoNext ? () => setState(() => _step++) : null,
                    child: const Text('SIGUIENTE'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProspectFollowUpCallScript extends StatelessWidget {
  final VoidCallback onContinue;

  const ProspectFollowUpCallScript({super.key, required this.onContinue});

  Widget _speech(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFF8B8329),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'SulphurPoint',
        fontSize: 15,
        height: 1.22,
      ),
    ),
  );

  Widget _benefitList(CallScriptBenefitGroup group, Color color) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(group.title, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 5),
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
                          Icons.check_circle_outline,
                          size: 17,
                          color: Color(0xFF006B61),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
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
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            group.items.join(',\n'),
            style: const TextStyle(color: Colors.white, fontSize: 11),
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
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBC6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Llamada de Seguimiento (Día 2)',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 5),
          _speech(
            'Hola buen día Sr(a). Cesar Martinez Dorado, ¿Cómo está? '
            'Habla Miguel Jurado.\n\n'
            'Hablamos el día de ayer y le envié la información del desarrollo '
            'RUNA YUCATÁN, dígame... ¿Encontró alguna ubicación de su agrado?',
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B8329),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 18),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '¿Qué preguntas tiene?\n'
                    '(Resuelve dudas antes de pasar a la corrida financiera).',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'BebasNeue',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _speech(
            'Me gustaría comentarle de nuevo que no solo es un terreno; la '
            'inversión le incluye un proyecto completo con alta plusvalía y '
            'en armonía con el medio ambiente:',
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _benefitList(demoFollowUpIncludes, const Color(0xFF9BF5EB)),
              const SizedBox(width: 10),
              _benefitList(demoFollowUpBenefits, const Color(0xFFA9F6AC)),
            ],
          ),
          const SizedBox(height: 9),
          const Center(
            child: Text(
              '“Inversión inteligente en un proyecto completo”',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: demoFollowUpCategories
                .map(
                  (group) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: _category(group),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 9),
          _speech(
            'Contamos con 0% impacto ecológico y cultura verde. El uso de '
            'suelo es habitacional con límite de construcción del 50%, '
            'garantizando plusvalía y cero contaminación visual.',
          ),
          const SizedBox(height: 8),
          _speech('¿Desea que comencemos a construir su sueño hoy mismo?'),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF008A98),
              ),
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
