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
  });

  final String name;
  final Duration elapsed;
  final VoidCallback onFinish;
  final VoidCallback? onReturn;

  String get _time {
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
                  icon: const Icon(Icons.open_in_new),
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
