import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:flutter/material.dart';

/// Chip de un término reciente, con acción para volver a buscarlo o eliminarlo.
class RecentSearchChip extends StatelessWidget {
  const RecentSearchChip({
    super.key,
    required this.query,
    this.onTap,
    this.onDelete,
  });

  final String query;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return InputChip(
      label: Text(
        query,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'SulphurPoint',
          fontSize: 13,
          color: palette.chipForeground,
        ),
      ),
      onPressed: onTap,
      onDeleted: onDelete,
      deleteIcon: Icon(
        Icons.close_rounded,
        size: 18,
        color: palette.chipForeground,
        semanticLabel: 'Eliminar búsqueda',
      ),
      deleteButtonTooltipMessage: 'Eliminar búsqueda',
      backgroundColor: palette.chipFill,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 5),
    );
  }
}
