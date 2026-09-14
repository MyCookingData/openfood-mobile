import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette issue de variables CSS
  static const Color bg = Color(0xFF080D09);
  static const Color surface = Color(0xFF111A13);
  static const Color surface2 = Color(0xFF182019);
  static const Color surface3 = Color(0xFF1F2920);
  
  static const Color green = Color(0xFF1E8B3A);
  static const Color greenL = Color(0xFF28A846);
  static const Color greenXl = Color(0xFF3DC962);
  
  static const Color red = Color(0xFFE03020);
  static const Color redL = Color(0xFFF04535);
  
  static const Color cream = Color(0xFFEFF7F0);
  static const Color muted = Color(0xFF6B8570);
  static const Color muted2 = Color(0xFF9DB8A2);
  static const Color gold = Color(0xFFF5C842);

  // Bordures calculées (rgba 40,160,70 = #28A046)
  static final Color border = const Color(0xFF28A046).withValues(alpha: 0.10);
  static final Color border2 = const Color(0xFF28A046).withValues(alpha: 0.20);

  // Styles de texte spécifiques (Bricolage pour les gros titres)
  static TextStyle get titleStyle => GoogleFonts.bricolageGrotesque(
    fontWeight: FontWeight.w800,
    color: cream,
  );
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: greenXl,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: cream,
      ),
      // Police par défaut: Plus Jakarta Sans
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: cream,
        displayColor: cream,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: cream),
      ),
    );
  }
}

