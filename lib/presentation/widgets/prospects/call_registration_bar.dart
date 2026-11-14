import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:flutter/material.dart';

/// Recordatorio discreto para que el vendedor registre el resultado de una
/// llamada que ya se realizó fuera de la app. No muestra cronómetro ni
/// acciones de "finalizar" porque la llamada no se origina en CallerApp.
class CallRegistrationBar extends StatelessWidget {
  const CallRegistrationBar({
    super.key,
    required this.name,
    required this.onRegister,
    this.onDiscard,
  });

  final String name;
  final VoidCallback onRegister;
  final VoidCallback? onDiscard;

  Future<void> _confirmDiscard(BuildContext context) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Descartar llamada'),
        content: const Text('¿Deseas descartar esta llamada sin registrarla?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('DESCARTAR'),
          ),
        ],
      ),
    );
    if (discard == true) onDiscard?.call();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final gap = AppStyles.spacingSmall(context);
    return Material(
      color: palette.callbar,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(gap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.phone_in_talk, color: palette.onBrand),
              SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LLAMADA CON ${name.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.onBrand,
                        fontFamily: 'BebasNeue',
                      ),
                    ),
                    Text(
                      'Registra el resultado cuando termines.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.onBrand, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (onDiscard != null)
                IconButton(
                  tooltip: 'Descartar llamada',
                  onPressed: () => _confirmDiscard(context),
                  icon: Icon(Icons.delete_outline, color: palette.onBrand),
                ),
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed: onRegister,
                icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
                label: const Text(
                  'REGISTRAR',
                  style: TextStyle(fontFamily: 'BebasNeue'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.onBrand,
                  foregroundColor: palette.callbar,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
