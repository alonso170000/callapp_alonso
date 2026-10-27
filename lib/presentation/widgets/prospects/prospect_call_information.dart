import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';

class ProspectCallInformation extends StatelessWidget {
  final ProspectRecord prospect;

  const ProspectCallInformation({super.key, required this.prospect});

  String _duration(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60);
    return '${minutes}min ${seconds}s';
  }

  Widget _field(BuildContext context, String label, Widget value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 17,
            color: AppPalette.of(context).textColor,
          ),
        ),
        const SizedBox(height: 5),
        value,
      ],
    ),
  );

  Widget _value(BuildContext context, String text, {bool compact = false}) =>
      Container(
        width: compact ? null : double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF398FA3),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.prospectFormFieldText,
            fontSize: 21,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final duration = prospect.lastCallDuration;
    final callAt = prospect.lastCallAt;
    return ProspectDetailPanel(
      title: 'Información de la llamada',
      color: const Color(0xFF195768),
      nested: true,
      initiallyExpanded: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
        decoration: BoxDecoration(
          color: AppPalette.of(context).nestedSurfaceFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: callAt == null
            ? Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Sin llamada registrada.',
                  style: TextStyle(
                    fontSize: 17,
                    color: AppPalette.of(context).textColor,
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(
                    context,
                    'Duración de llamada',
                    _value(
                      context,
                      duration == null ? 'No registrada' : _duration(duration),
                    ),
                  ),
                  _field(
                    context,
                    'Estado de llamada',
                    _value(
                      context,
                      prospect.lastCallStatus ?? prospect.lastContactResult,
                    ),
                  ),
                  _field(
                    context,
                    'Fecha/hora',
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _value(
                          context,
                          MaterialLocalizations.of(context)
                              .formatCompactDate(callAt),
                          compact: true,
                        ),
                        _value(
                          context,
                          TimeOfDay.fromDateTime(callAt).format(context),
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
