import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class HomeCardArrow extends StatelessWidget {
  const HomeCardArrow({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SizedBox.square(
      dimension: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: palette.cardArrowFill,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          Icon(
            FluentIcons.arrow_square_up_right_24_filled,
            color: palette.cardArrowForeground,
            size: 52,
          ),
        ],
      ),
    );
  }
}

class HomeTappableCard extends StatelessWidget {
  final Color color;
  final Widget child;
  final double? height;
  final VoidCallback? onTap;

  const HomeTappableCard({
    super.key,
    required this.color,
    required this.child,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: child),
      ),
    );
  }
}
