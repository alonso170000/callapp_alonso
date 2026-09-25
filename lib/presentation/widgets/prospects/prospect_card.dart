import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class ProspectCard extends StatelessWidget {
  final ProspectRecord prospect;
  final VoidCallback? onTap;
  const ProspectCard({super.key, required this.prospect, this.onTap});

  Future<void> _contact(BuildContext context, bool message) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.homeBackground,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                prospect.name.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 28,
                  color: AppColors.primaryColor,
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
              const Text(
                'Contacto de ejemplo',
                style: TextStyle(color: Colors.black54),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: prospect.phone));
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
    final date = prospect.appointment;
    String two(int value) => value.toString().padLeft(2, '0');
    final temperatureColor = switch (prospect.temperature) {
      'Caliente' => const Color(0xFFFF535C),
      'Tibio' => const Color(0xFFFFCC44),
      _ => const Color(0xFF25C3E0),
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: prospect.avatarColor,
                  child: Image.asset(
                    'lib/resources/images/Frame.png',
                    width: 28,
                    height: 28,
                    excludeFromSemantics: true,
                  ),
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
                          fontSize: 21,
                          height: 1.05,
                          color: AppColors.homeWarmText,
                        ),
                      ),
                      Text(
                        'Llamada · Hace ${prospect.daysSinceContact} ${prospect.daysSinceContact == 1 ? 'día' : 'días'}',
                        style: const TextStyle(
                          fontFamily: 'SulphurPoint',
                          fontSize: 10,
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
                const SizedBox(width: 2),
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
                fontSize: 13,
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
                _tag(
                  '${two(date.day)}-${two(date.month)}-${date.year}',
                  const Color(0xFFA8F5E4),
                ),
                _tag(
                  '${two(date.hour % 12 == 0 ? 12 : date.hour % 12)}:${two(date.minute)} ${date.hour < 12 ? 'AM' : 'PM'}',
                  prospect.status == 'Atrasados'
                      ? const Color(0xFFFFA3A6)
                      : const Color(0xFFA8F5E4),
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
      onPressed: () => _contact(context, message),
      style: IconButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.primaryColor,
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
          fontSize: 13,
          height: 1.1,
          color: foreground,
        ),
      ),
    );
  }
}
