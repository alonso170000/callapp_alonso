import 'package:flutter/material.dart';

import '../../resources/styles/app_motion.dart';

/// Añade una animación decorativa de pulsación sin alterar el layout.
class AppPressBounce extends StatefulWidget {
  const AppPressBounce({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = AppMotion.pressScale,
  });

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<AppPressBounce> createState() => _AppPressBounceState();
}

class _AppPressBounceState extends State<AppPressBounce> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled ||
        MediaQuery.maybeDisableAnimationsOf(context) == true) {
      return widget.child;
    }

    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: _pressed ? AppMotion.pressIn : AppMotion.pressOut,
        curve: _pressed ? AppMotion.pressInCurve : AppMotion.pressOutCurve,
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}
