import 'package:callerapp_frontend/presentation/widgets/app_press_bounce.dart';
import 'package:flutter/material.dart';

import '../../../resources/styles/styles.dart';

/// Encabezado de una sección del buscador, con una acción opcional a la derecha.
class SearchSectionHeader extends StatelessWidget {
  const SearchSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 22,
              height: 1,
              color: colorScheme.primary,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          AppPressBounce(
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: appButtonShape(),
                textStyle: appButtonTextStyle,
              ),
              child: Text(actionLabel!),
            ),
          ),
      ],
    );
  }
}
