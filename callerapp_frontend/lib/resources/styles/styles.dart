import 'package:flutter/material.dart';

class AppStyles {
  static const double authContentTop = 120;
  static const double authCharacterTop = 42;
  static const double authCharacterSize = 130;
  static const double authHeaderFontSize = 42;
  static const double authPanelRadius = 26;
  static const double authPanelPadding = 20;

  // Altura y ancho de pantalla
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Función para hacer responsivo según altura
  static double h(BuildContext context, double value) {
    return screenHeight(context) * value;
  }

  // Función para hacer responsivo según ancho
  static double w(BuildContext context, double value) {
    return screenWidth(context) * value;
  }

  // --- Card ---
  static double cardMarginHorizontal(BuildContext context) {
    return w(context, 0.06);
  }

  static double cardPaddingHorizontal(BuildContext context) {
    return w(context, 0.055);
  }

  static double cardPaddingVertical(BuildContext context) {
    return h(context, 0.030);
  }

  static double cardBorderRadius(BuildContext context) {
    return w(context, 0.035);
  }

  // --- Buttons ---
  static double buttonHeight(BuildContext context) {
    return h(context, 0.065);
  }

  static double buttonBorderRadius(BuildContext context) {
    return w(context, 0.07);
  }

  // --- Circle Back Button ---
  static double circleButtonWidth(BuildContext context) {
    return w(context, 0.13);
  }

  static double circleButtonHeight(BuildContext context) {
    return w(context, 0.13);
  }

  static double circleButtonIconSize(BuildContext context) {
    return w(context, 0.11);
  }

  // --- TextField ---
  static double textFieldBorderRadius(BuildContext context) {
    return w(context, 0.03);
  }

  static double textFieldPaddingHorizontal(BuildContext context) {
    return w(context, 0.04);
  }

  static double textFieldPaddingVertical(BuildContext context) {
    return h(context, 0.018);
  }

  // --- Login / Register layouts ---
  static double logoWidth(BuildContext context) {
    return w(context, 0.25);
  }

  static double mainBannerLogoWidth(BuildContext context) {
    return w(context, 0.15).clamp(70.0, 170.0).toDouble();
  }

  static double googleButtonHeight(BuildContext context) {
    return h(context, 0.060);
  }

  static double googleButtonBorderRadius(BuildContext context) {
    return w(context, 0.025);
  }

  static const double dividerThickness = 1.0;

  static double dividerPaddingHorizontal(BuildContext context) {
    return w(context, 0.035);
  }

  static double checkboxSize(BuildContext context) {
    return w(context, 0.055);
  }

  // --- Back Button position ---
  static double backButtonPositionLeft(BuildContext context) {
    return w(context, 0.07);
  }

  static double backButtonPositionTop(BuildContext context) {
    return h(context, 0.04);
  }

  // --- Spacing sizes ---
  static double spacingTiny(BuildContext context) {
    return h(context, 0.007);
  }

  static double spacingSmall(BuildContext context) {
    return h(context, 0.010);
  }

  static double spacingMedium(BuildContext context) {
    return h(context, 0.016);
  }

  static double spacingLarge(BuildContext context) {
    return h(context, 0.020);
  }

  static double spacingExtraLarge(BuildContext context) {
    return h(context, 0.028);
  }

  static double spacingHuge(BuildContext context) {
    return h(context, 0.032);
  }

  static double spacingBottom(BuildContext context) {
    return h(context, 0.070);
  }

  // --- Text ---

  static double textLabel(BuildContext context) {
    return h(context, 0.015);
  }

  static double textButtom(BuildContext context) {
    return h(context, 0.02);
  }

  static double textTextfield(BuildContext context) {
    return h(context, 0.018);
  }
}