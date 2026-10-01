import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class CallScriptBenefits extends StatelessWidget {
  final List<String> items;
  final Color color;

  const CallScriptBenefits({
    super.key,
    required this.items,
    this.color = AppColors.scriptBenefits,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
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
                      item,
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
  );
}

/// Shared reading surfaces for the initial and follow-up call scripts.
class CallScriptSpeech extends StatelessWidget {
  final String text;
  const CallScriptSpeech({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.scriptSpeech,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'SulphurPoint',
        fontSize: 15,
        height: 1.45,
      ),
    ),
  );
}

class CallScriptNote extends StatelessWidget {
  final String text;
  final bool discovery;
  const CallScriptNote({super.key, required this.text, this.discovery = false});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.scriptNote,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.scriptNoteText,
              fontFamily: 'SulphurPoint',
              fontSize: 14,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Tarjeta de servicios compartida por ambas llamadas.
class CallScriptServiceCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final String separator;

  const CallScriptServiceCard({
    super.key,
    required this.title,
    required this.items,
    this.separator = '',
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.scriptSpeech,
      borderRadius: BorderRadius.circular(7),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          color: AppColors.scriptServiceHeader,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'SulphurPoint',
              fontSize: 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++)
                Text(
                  '${items[i]}${i < items.length - 1 ? separator : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'SulphurPoint',
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Apila las secciones en móvil para mantener sus textos legibles.
class CallScriptColumns extends StatelessWidget {
  final List<Widget> children;
  const CallScriptColumns({super.key, required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children
          .map(
            (child) => SizedBox(
              width: constraints.maxWidth < 540
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12 * (children.length - 1)) /
                        children.length,
              child: child,
            ),
          )
          .toList(),
    ),
  );
}
