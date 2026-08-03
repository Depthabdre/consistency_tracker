import 'package:flutter/material.dart';

class AppTheme {
  // Ultra-Sleek Dark Focus Palette
  static const Color backgroundStart = Color(0xFF202020);
  static const Color backgroundEnd = Color(0xFF2A2B2D);
  static const Color surfaceCard = Color(0xFF323232);
  static const Color borderOutline = Color(0xFF3F3F3F);
  static const Color accentCyan = Color(0xFF53B5EA);     // Primary Focus Cyan
  static const Color accentIndigo = Color(0xFF6366F1);   // Secondary Indigo
  static const Color successGreen = Color(0xFF34D399);   // Mint Success
  static const Color warningOrange = Color(0xFFF59E0B);
  
  static const Color textPrimary = Color(0xFFE2E2E2);
  static const Color textSecondary = Color(0xFFD0D0D0);
  static const Color textMuted = Color(0xFFA0A0A0);

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundStart, backgroundEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundStart,
      primaryColor: accentCyan,
      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        secondary: accentIndigo,
        surface: surfaceCard,
        error: Color(0xFFF43F5E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderOutline, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderOutline, width: 1.2),
        ),
      ),
    );
  }
}
