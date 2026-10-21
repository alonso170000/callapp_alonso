import 'package:flutter/material.dart';

import '../colors/colors.dart';

/// Colores semánticos que se adaptan al modo claro/oscuro sin perder la
/// identidad visual de la app (teal profundo, menta y pasteles).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.cardInk,
    required this.brandFill,
    required this.onBrand,
    required this.selectedFill,
    required this.selectedForeground,
    required this.todayFill,
    required this.todayBorder,
    required this.todayForeground,
    required this.calendarSurface,
    required this.activityDot,
    required this.activityDotSelected,
    required this.completedIcon,
    required this.pendingIcon,
    required this.navGradient,
    required this.navForeground,
    required this.navSelectedFill,
    required this.navSelectedForeground,
    required this.fieldFill,
    required this.fieldForeground,
    required this.fieldHint,
    required this.chipFill,
    required this.chipForeground,
    required this.chipSelectedFill,
    required this.chipSelectedForeground,
    required this.chipBorder,
    required this.secondaryActionFill,
    required this.secondaryActionForeground,
    required this.iconChipFill,
    required this.iconChipForeground,
    required this.warmBannerFill,
    required this.warmBannerForeground,
  });

  /// Texto oscuro que se usa sobre las tarjetas pastel en ambos modos.
  final Color cardInk;

  /// Relleno de marca (tarjetas y contenedores teal).
  final Color brandFill;
  final Color onBrand;

  /// Día seleccionado en los selectores de fecha.
  final Color selectedFill;
  final Color selectedForeground;

  /// Día de hoy cuando no está seleccionado.
  final Color todayFill;
  final Color todayBorder;
  final Color todayForeground;

  final Color calendarSurface;
  final Color activityDot;
  final Color activityDotSelected;
  final Color completedIcon;
  final Color pendingIcon;

  final LinearGradient navGradient;
  final Color navForeground;
  final Color navSelectedFill;
  final Color navSelectedForeground;

  final Color fieldFill;
  final Color fieldForeground;
  final Color fieldHint;

  final Color chipFill;
  final Color chipForeground;
  final Color chipSelectedFill;
  final Color chipSelectedForeground;
  final Color chipBorder;

  final Color secondaryActionFill;
  final Color secondaryActionForeground;

  final Color iconChipFill;
  final Color iconChipForeground;

  final Color warmBannerFill;
  final Color warmBannerForeground;

  static const AppPalette light = AppPalette(
    cardInk: Colors.black,
    brandFill: AppColors.primaryColor,
    onBrand: AppColors.whiteColor,
    selectedFill: AppColors.primaryColor,
    selectedForeground: AppColors.homeBackground,
    todayFill: AppColors.homeGreenToday,
    todayBorder: AppColors.homeGreenToday,
    todayForeground: AppColors.primaryColor,
    calendarSurface: Color(0xFFD2F2EA),
    activityDot: Color(0xFFFF4655),
    activityDotSelected: AppColors.homeWarmText,
    completedIcon: Color(0xFF55AD62),
    pendingIcon: Color(0xFF509892),
    navGradient: AppColors.navigationGradient,
    navForeground: AppColors.primaryColor,
    navSelectedFill: AppColors.primaryColor,
    navSelectedForeground: AppColors.accentColor,
    fieldFill: Color(0xFFC3E7DF),
    fieldForeground: AppColors.primaryColor,
    fieldHint: Color(0xFF316A64),
    chipFill: Color(0xFFABF5E7),
    chipForeground: AppColors.primaryColor,
    chipSelectedFill: AppColors.primaryColor,
    chipSelectedForeground: AppColors.accentColor,
    chipBorder: AppColors.primaryColor,
    secondaryActionFill: Color(0xFFACEFE2),
    secondaryActionForeground: Color(0xFF398C80),
    iconChipFill: AppColors.homeBackground,
    iconChipForeground: AppColors.primaryColor,
    warmBannerFill: Color(0xFFE9EECA),
    warmBannerForeground: AppColors.primaryColor,
  );

  static const AppPalette dark = AppPalette(
    cardInk: Colors.black,
    brandFill: Color(0xFF0B4F48),
    onBrand: Color(0xFFEAFBF6),
    selectedFill: Color(0xFF91E5D6),
    selectedForeground: Color(0xFF06211D),
    todayFill: Color(0xFF1E4A43),
    todayBorder: Color(0xFF91E5D6),
    todayForeground: Color(0xFFE1F5EE),
    calendarSurface: Color(0xFF16302B),
    activityDot: Color(0xFFFF8A93),
    activityDotSelected: Color(0xFF06211D),
    completedIcon: Color(0xFF7CE38B),
    pendingIcon: Color(0xFF8FD8CB),
    navGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF0C3B35), Color(0xFF115048)],
    ),
    navForeground: Color(0xFF91E5D6),
    navSelectedFill: Color(0xFF91E5D6),
    navSelectedForeground: Color(0xFF06211D),
    fieldFill: Color(0xFF173B35),
    fieldForeground: Color(0xFFE1F5EE),
    fieldHint: Color(0xFF93BFB6),
    chipFill: Color(0xFF173B35),
    chipForeground: Color(0xFFC6EFE5),
    chipSelectedFill: Color(0xFF91E5D6),
    chipSelectedForeground: Color(0xFF06211D),
    chipBorder: Color(0xFF3C6F66),
    secondaryActionFill: Color(0xFF14514A),
    secondaryActionForeground: Color(0xFFCFF7EE),
    iconChipFill: Color(0x2EFFFFFF),
    iconChipForeground: Color(0xFF91E5D6),
    warmBannerFill: Color(0xFF3A3320),
    warmBannerForeground: Color(0xFFFFE6A8),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? light;

  @override
  AppPalette copyWith({
    Color? cardInk,
    Color? brandFill,
    Color? onBrand,
    Color? selectedFill,
    Color? selectedForeground,
    Color? todayFill,
    Color? todayBorder,
    Color? todayForeground,
    Color? calendarSurface,
    Color? activityDot,
    Color? activityDotSelected,
    Color? completedIcon,
    Color? pendingIcon,
    LinearGradient? navGradient,
    Color? navForeground,
    Color? navSelectedFill,
    Color? navSelectedForeground,
    Color? fieldFill,
    Color? fieldForeground,
    Color? fieldHint,
    Color? chipFill,
    Color? chipForeground,
    Color? chipSelectedFill,
    Color? chipSelectedForeground,
    Color? chipBorder,
    Color? secondaryActionFill,
    Color? secondaryActionForeground,
    Color? iconChipFill,
    Color? iconChipForeground,
    Color? warmBannerFill,
    Color? warmBannerForeground,
  }) => AppPalette(
    cardInk: cardInk ?? this.cardInk,
    brandFill: brandFill ?? this.brandFill,
    onBrand: onBrand ?? this.onBrand,
    selectedFill: selectedFill ?? this.selectedFill,
    selectedForeground: selectedForeground ?? this.selectedForeground,
    todayFill: todayFill ?? this.todayFill,
    todayBorder: todayBorder ?? this.todayBorder,
    todayForeground: todayForeground ?? this.todayForeground,
    calendarSurface: calendarSurface ?? this.calendarSurface,
    activityDot: activityDot ?? this.activityDot,
    activityDotSelected: activityDotSelected ?? this.activityDotSelected,
    completedIcon: completedIcon ?? this.completedIcon,
    pendingIcon: pendingIcon ?? this.pendingIcon,
    navGradient: navGradient ?? this.navGradient,
    navForeground: navForeground ?? this.navForeground,
    navSelectedFill: navSelectedFill ?? this.navSelectedFill,
    navSelectedForeground: navSelectedForeground ?? this.navSelectedForeground,
    fieldFill: fieldFill ?? this.fieldFill,
    fieldForeground: fieldForeground ?? this.fieldForeground,
    fieldHint: fieldHint ?? this.fieldHint,
    chipFill: chipFill ?? this.chipFill,
    chipForeground: chipForeground ?? this.chipForeground,
    chipSelectedFill: chipSelectedFill ?? this.chipSelectedFill,
    chipSelectedForeground:
        chipSelectedForeground ?? this.chipSelectedForeground,
    chipBorder: chipBorder ?? this.chipBorder,
    secondaryActionFill: secondaryActionFill ?? this.secondaryActionFill,
    secondaryActionForeground:
        secondaryActionForeground ?? this.secondaryActionForeground,
    iconChipFill: iconChipFill ?? this.iconChipFill,
    iconChipForeground: iconChipForeground ?? this.iconChipForeground,
    warmBannerFill: warmBannerFill ?? this.warmBannerFill,
    warmBannerForeground: warmBannerForeground ?? this.warmBannerForeground,
  );

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      cardInk: mix(cardInk, other.cardInk),
      brandFill: mix(brandFill, other.brandFill),
      onBrand: mix(onBrand, other.onBrand),
      selectedFill: mix(selectedFill, other.selectedFill),
      selectedForeground: mix(selectedForeground, other.selectedForeground),
      todayFill: mix(todayFill, other.todayFill),
      todayBorder: mix(todayBorder, other.todayBorder),
      todayForeground: mix(todayForeground, other.todayForeground),
      calendarSurface: mix(calendarSurface, other.calendarSurface),
      activityDot: mix(activityDot, other.activityDot),
      activityDotSelected: mix(activityDotSelected, other.activityDotSelected),
      completedIcon: mix(completedIcon, other.completedIcon),
      pendingIcon: mix(pendingIcon, other.pendingIcon),
      navGradient: t < 0.5 ? navGradient : other.navGradient,
      navForeground: mix(navForeground, other.navForeground),
      navSelectedFill: mix(navSelectedFill, other.navSelectedFill),
      navSelectedForeground: mix(
        navSelectedForeground,
        other.navSelectedForeground,
      ),
      fieldFill: mix(fieldFill, other.fieldFill),
      fieldForeground: mix(fieldForeground, other.fieldForeground),
      fieldHint: mix(fieldHint, other.fieldHint),
      chipFill: mix(chipFill, other.chipFill),
      chipForeground: mix(chipForeground, other.chipForeground),
      chipSelectedFill: mix(chipSelectedFill, other.chipSelectedFill),
      chipSelectedForeground: mix(
        chipSelectedForeground,
        other.chipSelectedForeground,
      ),
      chipBorder: mix(chipBorder, other.chipBorder),
      secondaryActionFill: mix(secondaryActionFill, other.secondaryActionFill),
      secondaryActionForeground: mix(
        secondaryActionForeground,
        other.secondaryActionForeground,
      ),
      iconChipFill: mix(iconChipFill, other.iconChipFill),
      iconChipForeground: mix(iconChipForeground, other.iconChipForeground),
      warmBannerFill: mix(warmBannerFill, other.warmBannerFill),
      warmBannerForeground: mix(
        warmBannerForeground,
        other.warmBannerForeground,
      ),
    );
  }
}
