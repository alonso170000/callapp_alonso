import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

@immutable
class LiquidGlassStyle {
  final double borderRadius;
  final double blur;

  const LiquidGlassStyle({required this.borderRadius, required this.blur});

  static const navigation = LiquidGlassStyle(borderRadius: 32, blur: 4);
  static const button = LiquidGlassStyle(borderRadius: 32, blur: 4);
}

/// Superficie de vidrio creada únicamente con primitivas de Flutter.
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final LiquidGlassStyle style;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const LiquidGlass({
    super.key,
    required this.child,
    this.style = LiquidGlassStyle.navigation,
    this.width,
    this.height,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(style.borderRadius);

    Widget glass = SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: radius),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: style.blur,
                    sigmaY: style.blur,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.navigationGradient,
                      borderRadius: radius,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(borderRadius: radius),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      glass = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: glass,
      );
    }

    return Semantics(button: onTap != null, label: semanticLabel, child: glass);
  }
}