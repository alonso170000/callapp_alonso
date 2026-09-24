import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color.fromARGB(5, 100, 95, 1);
  static const Color secondaryColor = Color(0x00F8DB9D);
  static const Color accentColor = Color.fromARGB(255, 67, 154, 150);
  static const Color transparentColor = Color(0x00000000);

  static const Color backgroundColor = Color(0xFF121212);
  static const Color textPrimaryColor = Color(0xFFFFFFFF);
  static const Color textSecondaryColor = Color.fromARGB(255, 229, 229, 229);

  static const Color googleRed = Color(0xFFDB4437);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color textDarkColor = Color(0xDD000000);
  static const Color textMutedColor = Color(0x73000000);

  // Paleta principal para la pantalla Home.
  static const Color homeBackground = Color(0xFFDDF9F1);
  static const Color homeDeepTeal = Color(0xFF00756B);
  static const Color homeWarmText = Color(0xFFFFD982);
  static const Color homeGreenCard = Color(0xFF85F5A6);
  static const Color homeYellowCard = Color(0xFFFFF47A);
  static const Color homeOrangeSection = Color(0xFFFFD391);
  static const Color homeBlueSection = Color(0xFF64D7EA);
  static const Color homeRedSection = Color(0xFFFF9CA2);
  static const Color homeBadge = Color(0xFFF2FF81);

  // Colores compartidos por las pantallas de autenticación.
  static const Color authCyan = Color(0xFF1DEBFF);
  static const Color authPurple = Color(0xFF8D1CFF);
  static const Color authPanelTop = Color(0xFF4B006D);
  static const Color authPanelBottom = Color(0xFF030916);
  static const Color authFieldLabel = Color(0xFFBD8DDA);
  static const Color authButtonShadow = Color(0xFF6BB2F6);

  static const LinearGradient authBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF02050A), Color(0xFF10001F), Color(0xFF020916)],
  );

  static const LinearGradient authPanelGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [authPanelTop, authPanelBottom],
  );

  static const LinearGradient authPanelBorderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [authPurple, authCyan, Color(0xFF000000)],
  );

  static const LinearGradient authFieldFocusedGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [authCyan, authPurple],
  );

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF8400B4), Color(0xFF6BB2F6)],
  );

  static const LinearGradient verticalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6BB2F6), Color(0xFF8400B4)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6BB2F6), Color(0xFF8400B4)],
  );

  static const LinearGradient genreGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color.fromARGB(0, 0, 0, 0), Color(0xFF6BB2F6)],
  );

  static const LinearGradient verTrailer = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color.fromARGB(255, 255, 255, 255), Color(0xFF6BB2F6)],
  );

  static const RadialGradient buttomGradient = RadialGradient(
    center: Alignment(0.3, 0.2),
    radius: 0.8,
    colors: [
      Color.fromARGB(255, 255, 242, 196),
      Color.fromARGB(255, 255, 247, 25),
    ],
  );

  static const LinearGradient homeScreenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.fromARGB(255, 0, 0, 0),
      Color.fromARGB(255, 18, 6, 49),
      Color.fromARGB(255, 0, 36, 47),
    ],
  );

  static const LinearGradient cardOpinionGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color.fromARGB(79, 0, 0, 0), Color.fromARGB(55, 80, 0, 107)],
  );

  static const LinearGradient navigationBorderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.fromARGB(108, 255, 255, 255),
      Color.fromARGB(0, 0, 0, 0),
      Color.fromARGB(108, 255, 255, 255),
    ],
  );
  static const LinearGradient navigationGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xBB8EEBD7), Color(0x9983DCCB)],
  );
}
