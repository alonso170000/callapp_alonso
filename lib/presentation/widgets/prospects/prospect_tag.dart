import 'package:callerapp_frontend/resources/colors/prospect_tag_colors.dart';
import 'package:flutter/material.dart';

class ProspectTag extends StatelessWidget {
  const ProspectTag({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    color: background,
    child: Text(
      label,
      style: TextStyle(
        fontFamily: 'BebasNeue',
        fontSize: 16,
        height: 1.1,
        color: foreground,
      ),
    ),
  );
}

class ProspectStatusTag extends StatelessWidget {
  const ProspectStatusTag({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => ProspectTag(
    label: status == 'Atrasados' ? 'ATRASADO' : status.toUpperCase(),
    background: ProspectTagColors.status(status),
    foreground: ProspectTagColors.foreground(status),
  );
}
