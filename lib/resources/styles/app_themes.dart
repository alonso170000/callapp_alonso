import 'package:flutter/material.dart';

import '../colors/colors.dart';
import 'picker_theme.dart';

class AppThemes {
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF112521) : AppColors.homeBackground;
    final foreground = dark ? const Color(0xFFE1F5EE) : AppColors.textDarkColor;
    final accent = dark ? const Color(0xFF91E5D6) : AppColors.primaryColor;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      brightness: brightness,
    ).copyWith(surface: surface, onSurface: foreground, primary: accent);
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: AppColors.primaryColor,
      scaffoldBackgroundColor: surface,
      fontFamily: 'SulphurPoint',
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: foreground,
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
      dialogTheme: DialogThemeData(backgroundColor: surface),
      datePickerTheme: dark
          ? appDatePickerTheme.copyWith(
              backgroundColor: surface,
              rangePickerBackgroundColor: surface,
              dayStyle: TextStyle(color: foreground),
              weekdayStyle: TextStyle(color: foreground),
              yearStyle: TextStyle(color: foreground),
              dayForegroundColor: WidgetStatePropertyAll(foreground),
              yearForegroundColor: WidgetStatePropertyAll(foreground),
              confirmButtonStyle: TextButton.styleFrom(foregroundColor: accent),
              cancelButtonStyle: TextButton.styleFrom(foregroundColor: accent),
            )
          : appDatePickerTheme,
      timePickerTheme: dark
          ? appTimePickerTheme.copyWith(
              backgroundColor: surface,
              dialBackgroundColor: const Color(0xFF243F38),
              dialHandColor: accent,
              dialTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? const Color(0xFF112521)
                    : foreground,
              ),
              helpTextStyle: TextStyle(
                color: foreground,
                fontFamily: 'SulphurPoint',
              ),
              hourMinuteTextColor: foreground,
              hourMinuteColor: const Color(0xFF243F38),
              dayPeriodColor: const Color(0xFF243F38),
              dayPeriodTextColor: foreground,
              confirmButtonStyle: TextButton.styleFrom(foregroundColor: accent),
              cancelButtonStyle: TextButton.styleFrom(foregroundColor: accent),
            )
          : appTimePickerTheme,
    );
  }
}
