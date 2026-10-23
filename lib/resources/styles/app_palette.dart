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
    required this.cardArrowFill,
    required this.cardArrowForeground,
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
    required this.headerBadgeFill,
    required this.headerBadgeForeground,
    required this.headerChipFill,
    required this.headerChipForeground,
    required this.headerForeground,
    required this.insertFollowUpFill,
    required this.insertFollowUpInk,
    required this.insertDiscoveryFill,
    required this.insertDiscoveryInk,
    required this.insertScriptsFill,
    required this.insertScriptsInk,
    required this.insertDataFill,
    required this.insertDataInk,
    required this.insertHistoryFill,
    required this.insertHistoryInk,
    required this.panelArrowFill,
    required this.panelArrowForeground,
    required this.panelSyncIcon,
    required this.panelSyncIconNested,
    required this.panelSyncAlert,
    required this.insertChipInk,
    required this.panelHeaderInk,
    required this.nestedSurfaceFill,
    required this.discoverySurfaceFill,
    required this.dataSurfaceFill,
    required this.historySurfaceFill,
    required this.historySurfaceInk,
    required this.fieldErrorInk,
    required this.errorSurfaceFill,
    required this.noticeSurfaceFill,
    required this.noticeSurfaceInk,
    required this.historyCardFill,
    required this.historyCardInk,
    required this.scriptSurfaceFill,
    required this.scriptSurfaceInk,
    required this.textColor,
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

  /// Flechas de las tarjetas de Inicio. El icono dibuja un cuadro relleno con
  /// la flecha recortada, por lo que [cardArrowFill] es el color que se ve en
  /// la flecha y [cardArrowForeground] el del cuadro.
  final Color cardArrowFill;
  final Color cardArrowForeground;

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

  /// Cromo del encabezado del detalle del prospecto (franja de marca).
  final Color headerBadgeFill;
  final Color headerBadgeForeground;
  final Color headerChipFill;
  final Color headerChipForeground;
  final Color headerForeground;

  /// Tarjetas de cada sección del detalle. El relleno es el color de la
  /// sección y [insert*Ink] el texto que va encima.
  final Color insertFollowUpFill;
  final Color insertFollowUpInk;
  final Color insertDiscoveryFill;
  final Color insertDiscoveryInk;
  final Color insertScriptsFill;
  final Color insertScriptsInk;
  final Color insertDataFill;
  final Color insertDataInk;
  final Color insertHistoryFill;
  final Color insertHistoryInk;

  /// Botón de plegado de los paneles del detalle.
  final Color panelArrowFill;
  final Color panelArrowForeground;

  /// Texto del chip de sección cuando está seleccionado.
  final Color insertChipInk;

  /// Tinta de los títulos de los paneles anidados, que siempre van sobre un
  /// encabezado de color saturado en ambos modos.
  final Color panelHeaderInk;

  /// Superficies internas de los paneles anidados de cada sección.
  final Color nestedSurfaceFill;
  final Color discoverySurfaceFill;
  final Color dataSurfaceFill;
  final Color historySurfaceFill;
  final Color historySurfaceInk;

  /// Texto de error de los formularios.
  final Color fieldErrorInk;

  /// Avisos dentro de los formularios (error y recordatorio cálido).
  final Color errorSurfaceFill;
  final Color noticeSurfaceFill;
  final Color noticeSurfaceInk;

  /// Tarjetas dentro de la superficie del historial de contactos.
  final Color historyCardFill;
  final Color historyCardInk;

  /// "Papel" de los guiones de llamada y la tinta de sus títulos.
  final Color scriptSurfaceFill;
  final Color scriptSurfaceInk;

  /// Icono de estado de sincronización de los paneles.
  final Color panelSyncIcon;
  final Color panelSyncIconNested;
  final Color panelSyncAlert;
  final Color textColor;

  static const AppPalette light = AppPalette(
    cardInk: Colors.black,
    brandFill: AppColors.primaryColor,
    onBrand: AppColors.accentColor,
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
    cardArrowFill: AppColors.textDarkColor,
    cardArrowForeground: AppColors.whiteColor,
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
    headerBadgeFill: Color(0xFF004C49),
    headerBadgeForeground: AppColors.homeWarmText,
    headerChipFill: Color(0xFF004F4B),
    headerChipForeground: Color(0xFFA9DCD3),
    headerForeground: AppColors.homeBackground,
    insertFollowUpFill: Color(0xFF96E3F4),
    insertFollowUpInk: Colors.black,
    insertDiscoveryFill: Color(0xFF95FF90),
    insertDiscoveryInk: Colors.black,
    insertScriptsFill: Color(0xFFFFF18A),
    insertScriptsInk: Colors.black,
    insertDataFill: Color(0xFFFF929C),
    insertDataInk: Colors.black,
    insertHistoryFill: Color(0xFFCE82F3),
    insertHistoryInk: Colors.black,
    panelArrowFill: AppColors.whiteColor,
    panelArrowForeground: Color(0xFF172D33),
    panelSyncIcon: Color(0xFF398AA0),
    panelSyncIconNested: Color(0xFF48A7BC),
    panelSyncAlert: Color(0xFFB80009),
    insertChipInk: Color(0xFF185465),
    panelHeaderInk: AppColors.whiteColor,
    nestedSurfaceFill: Color(0xFFB2EFFA),
    discoverySurfaceFill: Color(0xFFADFAC4),
    dataSurfaceFill: Color(0xFFFFCED1),
    historySurfaceFill: Color(0xFFE3B3FF),
    historySurfaceInk: Colors.black,
    fieldErrorInk: Color(0xFF8B1116),
    errorSurfaceFill: Color(0xFFFFD6D8),
    noticeSurfaceFill: AppColors.accentColor,
    noticeSurfaceInk: Color(0xFF195768),
    historyCardFill: Color(0xFFF0D1FF),
    historyCardInk: Color(0xFF713080),
    scriptSurfaceFill: AppColors.scriptBackground,
    scriptSurfaceInk: AppColors.scriptHeading,
    textColor: AppColors.textDarkColor,
  );

  static const AppPalette dark = AppPalette(
    cardInk: Colors.black,
    brandFill: Color(0xFF0B4F48),
    onBrand: AppColors.accentColor,
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
    navSelectedForeground: Color(0xFF115048),
    cardArrowFill: AppColors.whiteColor,
    cardArrowForeground: AppColors.darkSurface,
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
    headerBadgeFill: Color(0xFF06322D),
    headerBadgeForeground: Color(0xFFFFD98A),
    headerChipFill: Color(0xFF06322D),
    headerChipForeground: Color(0xFFA9DCD3),
    headerForeground: Color(0xFFD6EFE8),
    insertFollowUpFill: Color.fromARGB(255, 20, 72, 85),
    insertFollowUpInk: Color(0xFFCDEFFA),
    insertDiscoveryFill: Color(0xFF8DE58A),
    insertDiscoveryInk: Color(0xFF123B1B),
    insertScriptsFill: Color(0xFFE8D96F),
    insertScriptsInk: Color(0xFF403A12),
    insertDataFill: Color(0xFFE9828B),
    insertDataInk: Color(0xFF4A171C),
    insertHistoryFill: Color(0xFFC278E6),
    insertHistoryInk: Color(0xFF351441),
    panelArrowFill: Color(0x2EFFFFFF),
    panelArrowForeground: Color(0xFF91E5D6),
    panelSyncIcon: Color(0xFF8FD8CB),
    panelSyncIconNested: Color(0xFF8FD8CB),
    panelSyncAlert: Color(0xFF8B1116),
    insertChipInk: Color(0xFF06211D),
    panelHeaderInk: Color(0xFFF2FFFC),
    nestedSurfaceFill: Color.fromARGB(255, 132, 209, 228),
    discoverySurfaceFill: Color(0xFFA4E7B7),
    dataSurfaceFill: Color(0xFFF0B9BE),
    historySurfaceFill: Color(0xFF33203E),
    historySurfaceInk: Color(0xFFEFD3FA),
    fieldErrorInk: Color(0xFF8B1116),
    errorSurfaceFill: Color(0xFF3A1F22),
    noticeSurfaceFill: Color(0xFF3A3320),
    noticeSurfaceInk: Color(0xFFFFE6A8),
    historyCardFill: Color(0xFF3D2551),
    historyCardInk: Color(0xFFEFD3FA),
    scriptSurfaceFill: Color(0xFF2F2A12),
    scriptSurfaceInk: Color(0xFFF0E2A6),
    textColor: AppColors.textDarkColor,
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
    Color? cardArrowFill,
    Color? cardArrowForeground,
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
    Color? headerBadgeFill,
    Color? headerBadgeForeground,
    Color? headerChipFill,
    Color? headerChipForeground,
    Color? headerForeground,
    Color? insertFollowUpFill,
    Color? insertFollowUpInk,
    Color? insertDiscoveryFill,
    Color? insertDiscoveryInk,
    Color? insertScriptsFill,
    Color? insertScriptsInk,
    Color? insertDataFill,
    Color? insertDataInk,
    Color? insertHistoryFill,
    Color? insertHistoryInk,
    Color? panelArrowFill,
    Color? panelArrowForeground,
    Color? panelSyncIcon,
    Color? panelSyncIconNested,
    Color? panelSyncAlert,
    Color? insertChipInk,
    Color? panelHeaderInk,
    Color? nestedSurfaceFill,
    Color? discoverySurfaceFill,
    Color? dataSurfaceFill,
    Color? historySurfaceFill,
    Color? historySurfaceInk,
    Color? fieldErrorInk,
    Color? errorSurfaceFill,
    Color? noticeSurfaceFill,
    Color? noticeSurfaceInk,
    Color? historyCardFill,
    Color? historyCardInk,
    Color? scriptSurfaceFill,
    Color? scriptSurfaceInk,
    Color? textColor,
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
    cardArrowFill: cardArrowFill ?? this.cardArrowFill,
    cardArrowForeground: cardArrowForeground ?? this.cardArrowForeground,
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
    headerBadgeFill: headerBadgeFill ?? this.headerBadgeFill,
    headerBadgeForeground: headerBadgeForeground ?? this.headerBadgeForeground,
    headerChipFill: headerChipFill ?? this.headerChipFill,
    headerChipForeground: headerChipForeground ?? this.headerChipForeground,
    headerForeground: headerForeground ?? this.headerForeground,
    insertFollowUpFill: insertFollowUpFill ?? this.insertFollowUpFill,
    insertFollowUpInk: insertFollowUpInk ?? this.insertFollowUpInk,
    insertDiscoveryFill: insertDiscoveryFill ?? this.insertDiscoveryFill,
    insertDiscoveryInk: insertDiscoveryInk ?? this.insertDiscoveryInk,
    insertScriptsFill: insertScriptsFill ?? this.insertScriptsFill,
    insertScriptsInk: insertScriptsInk ?? this.insertScriptsInk,
    insertDataFill: insertDataFill ?? this.insertDataFill,
    insertDataInk: insertDataInk ?? this.insertDataInk,
    insertHistoryFill: insertHistoryFill ?? this.insertHistoryFill,
    insertHistoryInk: insertHistoryInk ?? this.insertHistoryInk,
    panelArrowFill: panelArrowFill ?? this.panelArrowFill,
    panelArrowForeground: panelArrowForeground ?? this.panelArrowForeground,
    panelSyncIcon: panelSyncIcon ?? this.panelSyncIcon,
    panelSyncIconNested: panelSyncIconNested ?? this.panelSyncIconNested,
    panelSyncAlert: panelSyncAlert ?? this.panelSyncAlert,
    insertChipInk: insertChipInk ?? this.insertChipInk,
    panelHeaderInk: panelHeaderInk ?? this.panelHeaderInk,
    nestedSurfaceFill: nestedSurfaceFill ?? this.nestedSurfaceFill,
    discoverySurfaceFill: discoverySurfaceFill ?? this.discoverySurfaceFill,
    dataSurfaceFill: dataSurfaceFill ?? this.dataSurfaceFill,
    historySurfaceFill: historySurfaceFill ?? this.historySurfaceFill,
    historySurfaceInk: historySurfaceInk ?? this.historySurfaceInk,
    fieldErrorInk: fieldErrorInk ?? this.fieldErrorInk,
    errorSurfaceFill: errorSurfaceFill ?? this.errorSurfaceFill,
    noticeSurfaceFill: noticeSurfaceFill ?? this.noticeSurfaceFill,
    noticeSurfaceInk: noticeSurfaceInk ?? this.noticeSurfaceInk,
    historyCardFill: historyCardFill ?? this.historyCardFill,
    historyCardInk: historyCardInk ?? this.historyCardInk,
    scriptSurfaceFill: scriptSurfaceFill ?? this.scriptSurfaceFill,
    scriptSurfaceInk: scriptSurfaceInk ?? this.scriptSurfaceInk,
    textColor: textColor ?? this.textColor,
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
      cardArrowFill: mix(cardArrowFill, other.cardArrowFill),
      cardArrowForeground: mix(cardArrowForeground, other.cardArrowForeground),
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
      headerBadgeFill: mix(headerBadgeFill, other.headerBadgeFill),
      headerBadgeForeground: mix(
        headerBadgeForeground,
        other.headerBadgeForeground,
      ),
      headerChipFill: mix(headerChipFill, other.headerChipFill),
      headerChipForeground: mix(
        headerChipForeground,
        other.headerChipForeground,
      ),
      headerForeground: mix(headerForeground, other.headerForeground),
      insertFollowUpFill: mix(insertFollowUpFill, other.insertFollowUpFill),
      insertFollowUpInk: mix(insertFollowUpInk, other.insertFollowUpInk),
      insertDiscoveryFill: mix(insertDiscoveryFill, other.insertDiscoveryFill),
      insertDiscoveryInk: mix(insertDiscoveryInk, other.insertDiscoveryInk),
      insertScriptsFill: mix(insertScriptsFill, other.insertScriptsFill),
      insertScriptsInk: mix(insertScriptsInk, other.insertScriptsInk),
      insertDataFill: mix(insertDataFill, other.insertDataFill),
      insertDataInk: mix(insertDataInk, other.insertDataInk),
      insertHistoryFill: mix(insertHistoryFill, other.insertHistoryFill),
      insertHistoryInk: mix(insertHistoryInk, other.insertHistoryInk),
      panelArrowFill: mix(panelArrowFill, other.panelArrowFill),
      panelArrowForeground: mix(
        panelArrowForeground,
        other.panelArrowForeground,
      ),
      panelSyncIcon: mix(panelSyncIcon, other.panelSyncIcon),
      panelSyncIconNested: mix(panelSyncIconNested, other.panelSyncIconNested),
      panelSyncAlert: mix(panelSyncAlert, other.panelSyncAlert),
      insertChipInk: mix(insertChipInk, other.insertChipInk),
      panelHeaderInk: mix(panelHeaderInk, other.panelHeaderInk),
      nestedSurfaceFill: mix(nestedSurfaceFill, other.nestedSurfaceFill),
      discoverySurfaceFill: mix(
        discoverySurfaceFill,
        other.discoverySurfaceFill,
      ),
      dataSurfaceFill: mix(dataSurfaceFill, other.dataSurfaceFill),
      historySurfaceFill: mix(historySurfaceFill, other.historySurfaceFill),
      historySurfaceInk: mix(historySurfaceInk, other.historySurfaceInk),
      fieldErrorInk: mix(fieldErrorInk, other.fieldErrorInk),
      errorSurfaceFill: mix(errorSurfaceFill, other.errorSurfaceFill),
      noticeSurfaceFill: mix(noticeSurfaceFill, other.noticeSurfaceFill),
      noticeSurfaceInk: mix(noticeSurfaceInk, other.noticeSurfaceInk),
      historyCardFill: mix(historyCardFill, other.historyCardFill),
      historyCardInk: mix(historyCardInk, other.historyCardInk),
      scriptSurfaceFill: mix(scriptSurfaceFill, other.scriptSurfaceFill),
      scriptSurfaceInk: mix(scriptSurfaceInk, other.scriptSurfaceInk),
      textColor: mix(textColor, other.textColor),
    );
  }
}
