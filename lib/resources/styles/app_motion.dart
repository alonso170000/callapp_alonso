import 'package:flutter/animation.dart';

class AppMotion {
  static const Duration pressIn = Duration(milliseconds: 90);
  static const Duration pressOut = Duration(milliseconds: 190);
  static const double pressScale = 0.96;
  static const Curve pressInCurve = Curves.easeOutCubic;
  static const Curve pressOutCurve = Curves.easeOutBack;
}
