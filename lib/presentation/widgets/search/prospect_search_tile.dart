import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_search.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_avatar_badge.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:flutter/material.dart';

/// Fila de resultado o de sugerencia del buscador global.
class ProspectSearchTile extends StatelessWidget {
  const ProspectSearchTile({
    super.key,
    required this.prospect,
    this.onTap,
    this.reason,
  });

  final ProspectRecord prospect;
  final VoidCallback? onTap;
  final ProspectSuggestionReason? reason;

  String? get _reasonLabel => switch (reason) {
    ProspectSuggestionReason.upcomingContact => 'Contacto pendiente',
    ProspectSuggestionReason.recentlyAssigned => 'Asignado recientemente',
    ProspectSuggestionReason.other => null,
    null => null,
  };

  String get _subtitle {
    final parts = [
      if (prospect.phone.trim().isNotEmpty) prospect.phone.trim(),
      if (prospect.email.trim().isNotEmpty) prospect.email.trim(),
    ];
    return parts.isEmpty ? prospect.status : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final label = _reasonLabel;
    return Semantics(
      button: onTap != null,
      label: 'Abrir prospecto ${prospect.name}',
      child: Material(
        color: palette.brandFill,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                ProspectAvatarBadge(prospect: prospect, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prospect.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 22,
                          height: 1,
                          color: palette.onBrand,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'SulphurPoint',
                          fontSize: 13,
                          color: palette.headerChipForeground,
                        ),
                      ),
                      if (label != null) ...[
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: palette.secondaryActionFill,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'SulphurPoint',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: palette.secondaryActionForeground,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.headerChipForeground,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
