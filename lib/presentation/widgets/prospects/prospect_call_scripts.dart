import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/call_script_components.dart';

import 'package:callerapp_frontend/presentation/models/call_script_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';

export 'prospect_follow_up_call_script.dart';

class ProspectCallScripts extends StatefulWidget {
  final CallScript script;
  final String prospectName;

  const ProspectCallScripts({
    super.key,
    required this.script,
    required this.prospectName,
  });

  @override
  State<ProspectCallScripts> createState() => _ProspectCallScriptsState();
}

class _ProspectCallScriptsState extends State<ProspectCallScripts> {
  final List<CallScriptStep> _history = [];
  CallScriptStep get _current =>
      _history.isEmpty ? widget.script.steps.first : _history.last;

  void _advance(CallScriptStep step) => setState(() => _history.add(step));

  String _personalize(String text) =>
      text.replaceAll('{prospectName}', widget.prospectName.toUpperCase());

  Widget _speech(String text) => CallScriptSpeech(text: _personalize(text));

  @override
  Widget build(BuildContext context) {
    final current = _current;
    final hasCards = current.responses.any((response) => response.icon != null);
    final branchColor = switch (current.tone) {
      CallScriptTone.positive => AppColors.scriptPositive,
      CallScriptTone.negative => AppColors.scriptNegative,
      CallScriptTone.discovery => AppColors.scriptBlue,
      CallScriptTone.investment => AppColors.scriptCyan,
      CallScriptTone.neutral => null,
    };
    final index = widget.script.steps.indexOf(current);
    final canGoNext = index >= 0 && index < widget.script.steps.length - 1;

    return ProspectDetailPanel(
      title: widget.script.title,
      color: AppColors.scriptPanel,
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
            Row(
              children: [
                if (_history.isNotEmpty)
                  IconButton(
                    tooltip: 'Volver al paso anterior',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    iconSize: 20,
                    onPressed: () => setState(() => _history.removeLast()),
                    color: AppColors.scriptPanel,
                    icon: const Icon(Iconsax.arrow_left_copy),
                  ),
                Expanded(
                  child: Text(
                    current.title,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.3,
                      color: AppColors.scriptHeading,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (current.introduction != null) ...[
              _speech(current.introduction!),
              const SizedBox(height: 8),
            ],

            for (final point in current.bulletPoints)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Iconsax.tick_circle_copy,
                      color: AppColors.scriptBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(point, style: const TextStyle(fontSize: 15)),
                    ),
                  ],
                ),
              ),
            if (hasCards)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                child: Text(
                  _personalize(current.content),
                  style: const TextStyle(fontSize: 15),
                ),
              )
            else if (branchColor == null || current.instructionAfterContent)
              _speech(current.content),
            if (current.instruction.isNotEmpty) ...[
              const SizedBox(height: 8),
              CallScriptNote(
                text: current.instruction,
                discovery: current.tone == CallScriptTone.discovery,
              ),
            ],
            if (branchColor != null && !current.instructionAfterContent) ...[
              if (current.instruction.isNotEmpty) const SizedBox(height: 8),
              _speech(current.content),
            ],
            if (current.continuation != null) ...[
              const SizedBox(height: 8),
              _speech(current.continuation!),
            ],
            if (current.finalInstruction != null) ...[
              const SizedBox(height: 8),
              CallScriptNote(text: current.finalInstruction!),
            ],
            if (current.benefits.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.scriptBenefits,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: current.benefits
                      .map(
                        (benefit) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Iconsax.tick_circle_copy,
                                size: 17,
                                color: AppColors.scriptCheck,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: const TextStyle(
                                    fontFamily: 'SulphurPoint',
                                    fontSize: 14,
                                    color: AppColors.scriptBenefitText,
                                  ),
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
            if (current.services.isNotEmpty) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 6)),
              if (current.servicesIntroduction != null) ...[
                _speech(current.servicesIntroduction!),
                const SizedBox(height: 12),
              ],
              CallScriptColumns(
                children: current.services
                    .map(
                      (group) => CallScriptServiceCard(
                        title: group.title,
                        items: group.items,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (current.showContinue) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: callScriptButtonStyle(
                    AppColors.scriptBlue,
                  ),
                  onPressed: () {
                    if (current.nextStep case final next?) {
                      _advance(next);
                    } else {
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'El siguiente texto del guion aún no está disponible.',
                          ),
                        ),
                      );
                    }
                  },
                  label: const Text('SEGUIR LEYENDO'),
                  iconAlignment: IconAlignment.end,
                ),
              ),
            ],
            if (current.responses.isNotEmpty) ...[
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: current.responses.asMap().entries.map((entry) {
                    final response = entry.value;
                    final color =
                        hasCards || current.tone == CallScriptTone.discovery
                        ? AppColors.scriptBlue
                        : entry.key == 0
                        ? AppColors.scriptPositive
                        : AppColors.scriptNegative;
                    return SizedBox(
                      width: constraints.maxWidth < (hasCards ? 360 : 300)
                          ? constraints.maxWidth
                          : (constraints.maxWidth -
                                    10 * (current.responses.length - 1)) /
                                current.responses.length,
                      child: OutlinedButton(
                        style: callScriptButtonStyle(color),
                        onPressed: () {
                          if (response.nextStep case final next?) {
                            _advance(next);
                          } else {
                            ScaffoldMessenger.of(context)
                                .removeCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'El guion de ${response.label.toLowerCase()} aún no está disponible.',
                                ),
                              ),
                            );
                          }
                        },
                        child: response.icon == null
                            ? Text(response.label, textAlign: TextAlign.center)
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(switch (response.icon!) {
                                      CallScriptResponseIcon.investment =>
                                        Iconsax.chart_2_copy,
                                      CallScriptResponseIcon.housing =>
                                        Iconsax.home_2_copy,
                                      CallScriptResponseIcon.rental =>
                                        Iconsax.key_copy,
                                    }, size: 28),
                                    const SizedBox(height: 6),
                                    Text(response.label),
                                  ],
                                ),
                              ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else if (canGoNext) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: callScriptButtonStyle(AppColors.scriptBlue),
                  onPressed: () => _advance(widget.script.steps[index + 1]),
                  child: const Text('SIGUIENTE'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
