import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:flutter/material.dart';

class CallInProgressBar extends StatelessWidget {
  const CallInProgressBar({
    super.key,
    required this.name,
    required this.elapsed,
    required this.onFinish,
    this.onReturn,
    this.onDiscard,
  });

  final String name;
  final Duration elapsed;
  final VoidCallback onFinish;
  final VoidCallback? onReturn;
  final VoidCallback? onDiscard;

  String get _time {
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

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
      color: palette.brandFill,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(gap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.circle, color: palette.onBrand),
              SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EN LLAMADA · $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.onBrand,
                        fontFamily: 'BebasNeue',
                      ),
                    ),
                    Text(_time, style: TextStyle(color: palette.onBrand)),
                  ],
                ),
              ),
              if (onReturn != null)
                IconButton(
                  tooltip: 'Volver a la llamada',
                  onPressed: onReturn,
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                ),
              if (onDiscard != null)
                IconButton(
                  tooltip: 'Descartar llamada',
                  onPressed: () => _confirmDiscard(context),
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                ),
              FilledButton.tonalIcon(
                onPressed: onFinish,
                icon: const Icon(Icons.call_end),
                label: const Text('FINALIZAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
