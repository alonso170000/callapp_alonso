import 'package:callerapp_frontend/resources/colors/prospect_tag_colors.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/services/phone_number.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_avatar_badge.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';

class ProspectCard extends StatelessWidget {
  final ProspectRecord prospect;
  final VoidCallback? onTap;
  final Future<void> Function(bool message)? onContact;
  const ProspectCard({
    super.key,
    required this.prospect,
    this.onTap,
    this.onContact,
  });

  Future<void> _contact(BuildContext context, bool message) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                prospect.name.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                message ? 'Datos para enviar un mensaje' : 'Datos para llamar',
                style: const TextStyle(
                  fontFamily: 'SulphurPoint',
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(prospect.phone),
              if (message) SelectableText(prospect.email),
              const SizedBox(height: 12),
              Text(
                prospect.id == null
                    ? 'Contacto de ejemplo'
                    : 'Datos de contacto',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton.icon(
                onPressed: prospect.phone.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(text: prospect.phone),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Número copiado')),
                          );
                        }
                      },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar teléfono'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = prospect.appointment ?? prospect.nextContact;
    final now = businessNow();
    final today = DateUtils.dateOnly(now);
    final dateColor = date != null && DateUtils.dateOnly(date).isBefore(today)
        ? const Color.fromARGB(255, 255, 159, 164)
        : const Color(0xFFA8F5E4);
    final timeColor = date != null && date.isBefore(now)
        ? const Color.fromARGB(255, 255, 159, 164)
        : const Color(0xFFA8F5E4);
    String two(int value) => value.toString().padLeft(2, '0');
    final temperatureColor = ProspectTagColors.priority(prospect.temperature);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.of(context).brandFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProspectAvatarBadge(prospect: prospect),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prospect.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 23,
                          height: 1.05,
                          color: AppColors.homeWarmText,
                        ),
                      ),
                      Text(
                        prospect.id != null && prospect.lastCallAt == null
                            ? 'Sin llamadas registradas'
                            : prospect.lastCallAt != null &&
                                  prospect.daysSinceContact == 0
                            ? 'Llamada · Hoy'
                            : prospect.daysSinceContact == 0
                            ? 'Sin contacto'
                            : 'Llamada · Hace ${prospect.daysSinceContact} ${prospect.daysSinceContact == 1 ? 'día' : 'días'}',
                        style: const TextStyle(
                          fontFamily: 'SulphurPoint',
                          fontSize: 12,
                          color: Color(0xFFB0E4DB),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _action(
                  context,
                  message: true,
                  color: const Color(0xFF64FF98),
                  icon: Iconsax.message_copy,
                ),
                const SizedBox(width: 0),
                _action(
                  context,
                  message: false,
                  color: const Color(0xFFFFE18A),
                  icon: Iconsax.call_copy,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              prospect.note,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'SulphurPoint',
                fontSize: 14,
                height: 1.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _tag(
                  prospect.status == 'Atrasados'
                      ? 'ATRASADO'
                      : prospect.status.toUpperCase(),
                  prospect.statusColor,
                ),
                _tag(
                  prospect.temperature.toUpperCase(),
                  temperatureColor,
                  foreground: Colors.white,
                ),
                if (date != null)
                  _tag(
                    '${two(date.day)}-${two(date.month)}-${date.year}',
                    dateColor,
                  ),
                if (date != null)
                  _tag(
                    '${two(date.hour % 12 == 0 ? 12 : date.hour % 12)}:${two(date.minute)} ${date.hour < 12 ? 'AM' : 'PM'}',
                    timeColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required bool message,
    required Color color,
    required IconData icon,
  }) {
    return IconButton(
      tooltip: message
          ? 'Mensaje a ${prospect.name}'
          : 'Llamar a ${prospect.name}',
      onPressed:
          (message
              ? prospect.phone.isEmpty && prospect.email.isEmpty
              : !PhoneNumber.isDialable(prospect.phone))
          ? null
          : () async {
              final action = onContact;
              if (action != null) {
                await action(message);
              } else {
                await _contact(context, message);
              }
            },
      style: IconButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.textDarkColor,
        minimumSize: const Size(34, 34),
        maximumSize: const Size(34, 34),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      icon: Icon(icon, size: 19),
    );
  }

  Widget _tag(String text, Color color, {Color foreground = Colors.black}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      color: color,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'BebasNeue',
          fontSize: 16,
          height: 1.1,
          color: foreground,
        ),
      ),
    );
  }
}
