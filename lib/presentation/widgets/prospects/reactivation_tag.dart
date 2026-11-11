import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:flutter/material.dart';

class ReactivationTag extends StatelessWidget {
  final bool compact;

  const ReactivationTag({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('reactivation-tag'),
    padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10, vertical: 2),
    color: AppColors.prospectTagReactivation,
    child: Text(
      'REACTIVACIÓN',
      style: TextStyle(
        fontFamily: 'BebasNeue',
        fontSize: 16,
        height: 1.1,
        color: AppColors.prospectTagReactivationInk,
      ),
    ),
  );
}
