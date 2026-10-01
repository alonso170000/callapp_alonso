import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:flutter/material.dart';

import 'package:callerapp_frontend/presentation/models/call_script_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/call_script_components.dart';

class ProspectFollowUpCallScript extends StatelessWidget {
  final VoidCallback onContinue;
  final String prospectName;

  const ProspectFollowUpCallScript({
    super.key,
    required this.onContinue,
    this.prospectName = 'prospecto',
  });

  Widget _speech(String text) =>
      CallScriptSpeech(text: text.replaceAll('{prospectName}', prospectName));

  Widget _benefitList(CallScriptBenefitGroup group, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(group.title, style: const TextStyle(fontSize: 14)),
      const SizedBox(height: 12),
      CallScriptBenefits(items: group.items, color: color),
    ],
  );

  Widget _category(CallScriptBenefitGroup group) => CallScriptServiceCard(
    title: group.title,
    items: group.items,
    separator: ',',
  );

  @override
  Widget build(BuildContext context) => ProspectDetailPanel(
    title: 'Llamada 2',
    color: AppColors.scriptPanel,
    nested: true,
    initiallyExpanded: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.scriptBackground,
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
              color: AppColors.scriptHeading,
            ),
          ),
          const SizedBox(height: 12),
          _speech(demoFollowUpGreeting),
          const SizedBox(height: 12),
          const CallScriptNote(
            text:
                '¿Qué preguntas tiene?\n'
                '(Resuelve dudas antes de pasar a la corrida financiera).',
          ),
          const SizedBox(height: 12),
          _speech(demoFollowUpProjectIntroduction),
          const SizedBox(height: 12),
          CallScriptColumns(
            children: [
              _benefitList(demoFollowUpIncludes, AppColors.scriptIncludes),
              _benefitList(demoFollowUpBenefits, AppColors.scriptBenefits),
            ],
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '“Inversión inteligente en un proyecto completo”',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.scriptHeading,
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
          _speech(demoFollowUpEcology),
          const SizedBox(height: 12),
          _speech(demoFollowUpClosingQuestion),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: callScriptButtonStyle(AppColors.scriptBlue),
              onPressed: () {
                onContinue();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Continuación al cierre registrada en esta vista.',
                    ),
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
