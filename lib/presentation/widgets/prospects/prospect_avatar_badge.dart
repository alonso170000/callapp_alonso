import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:flutter/material.dart';

/// Avatar de un prospecto.
///
/// Muestra la foto real del servicio cuando el prospecto viene de la API y
/// tiene `avatarUrl`; si no, cae en el icono genérico. Los contactos de
/// demostración (sin `id`) siguen usando el asset de ejemplo.
class ProspectAvatarBadge extends StatelessWidget {
  final ProspectRecord prospect;
  final double radius;

  const ProspectAvatarBadge({
    super.key,
    required this.prospect,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final fallback = Icon(
      Icons.person,
      color: AppColors.homeWarmText,
      size: diameter / 1.5,
    );
    final avatarUrl = prospect.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: prospect.avatarColor,
      child: prospect.id == null
          ? Image.asset(
              'lib/resources/images/Frame.png',
              width: diameter - 8,
              height: diameter - 8,
              excludeFromSemantics: true,
            )
          : ClipOval(
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? fallback
                  : Image.network(
                      avatarUrl,
                      width: diameter - 4,
                      height: diameter - 4,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallback,
                    ),
            ),
    );
  }
}
