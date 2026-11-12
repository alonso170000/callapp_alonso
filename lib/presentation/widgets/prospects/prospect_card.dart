import 'package:callerapp_frontend/resources/colors/prospect_tag_colors.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/contact_medium.dart';
import 'package:callerapp_frontend/presentation/models/prospect_action.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_avatar_badge.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/reactivation_tag.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_tag.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';

class ProspectCard extends StatelessWidget {
  final ProspectRecord prospect;
  final VoidCallback? onTap;
  final ProspectAction action;
  final Future<void> Function(ContactMedium medium)? onContact;
  const ProspectCard({
    super.key,
    required this.prospect,
    this.action = const ProspectAction(medium: ContactMedium.llamada),
    this.onTap,
    this.onContact,
  });

  Future<void> _contact(BuildContext context, ContactMedium medium) async {
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
                medium == ContactMedium.llamada
                    ? 'Datos para llamar'
                    : 'Datos para ${medium.actionLabel.toLowerCase()}',
                style: const TextStyle(
                  fontFamily: 'SulphurPoint',
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(prospect.phone),
              if (medium == ContactMedium.correo)
                SelectableText(prospect.email),
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
                ProspectAvatarBadge(
                  prospect: prospect,
                  borderColor: prospect.isClient
                      ? AppColors.prospectClientAvatarBorder
                      : null,
                ),
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
                _action(context),
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
                ProspectStatusTag(status: prospect.status),
                _tag(
                  prospect.temperature.toUpperCase(),
                  temperatureColor,
                  foreground: Colors.white,
                ),
                if (prospect.isReactivation) const ReactivationTag(),
                if (prospect.isClient)
                  ProspectTag(
                    label: 'CLIENTE',
                    background: ProspectTagColors.client,
                    foreground: ProspectTagColors.clientForeground,
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

  Widget _action(BuildContext context) {
    final medium = action.medium;
    final suffix = action.hasActivity
        ? ' · Seguimiento ${action.isOverdue ? 'atrasado' : 'agendado'}'
        : '';
    final icon = switch (medium) {
      ContactMedium.llamada => Iconsax.call_copy,
      ContactMedium.whatsapp || ContactMedium.facebook => Iconsax.message_copy,
      ContactMedium.correo => Iconsax.send_2_copy,
    };
    return IconButton(
      tooltip: '${medium.actionLabel} a ${prospect.name}$suffix',
      onPressed: !medium.isAvailable(prospect)
          ? null
          : () async {
              final action = onContact;
              if (action != null) {
                await action(medium);
              } else {
                await _contact(context, medium);
              }
            },
      style: IconButton.styleFrom(
        backgroundColor: medium == ContactMedium.llamada
            ? AppColors.prospectActionCall
            : AppColors.prospectActionMessage,
        foregroundColor: AppColors.textDarkColor,
        minimumSize: const Size(40, 40),
        maximumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      icon: Icon(icon, size: 22),
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
