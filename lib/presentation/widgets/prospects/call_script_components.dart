import 'package:flutter/material.dart';

ButtonStyle callScriptButtonStyle(Color color) => FilledButton.styleFrom(
  backgroundColor: color,
  foregroundColor: Colors.white,
  minimumSize: const Size(0, 44),
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  textStyle: const TextStyle(fontFamily: 'BebasNeue', fontSize: 18),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  side: BorderSide(color: color),
);

/// Shared reading surfaces for the initial and follow-up call scripts.
class CallScriptSpeech extends StatelessWidget {
  final String text;
  const CallScriptSpeech({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF8B8329),
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
      color: const Color(0xFFF3E6A0),
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
              color: Color(0xFF574600),
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

/// Keep long benefit lists readable on phones instead of squeezing columns.
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
