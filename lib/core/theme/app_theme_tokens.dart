import 'package:flutter/material.dart';

/// Design tokens. Flat surfaces, hairline borders, one accent color.
abstract final class AppColors {
  static const Color background = Color(0xFF0F1013);
  static const Color surface = Color(0xFF16181C);
  static const Color surfaceRaised = Color(0xFF1C1E23);
  static const Color surfaceHigh = Color(0xFF26292F);

  static const Color border = Color(0x14FFFFFF);
  static const Color borderStrong = Color(0x24FFFFFF);

  static const Color textPrimary = Color(0xFFECEDEF);
  static const Color textSecondary = Color(0xFFA7ABB4);
  static const Color textMuted = Color(0xFF7D828C);
  static const Color textFaint = Color(0xFF4B4F57);

  static const Color primary = Color(0xFF5B8CFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF3CC47C);
  static const Color warning = Color(0xFFE8B04B);
  static const Color danger = Color(0xFFEF5A6F);

  static const List<String> goalPalette = [
    '#5B8CFF', // Blue
    '#3CC47C', // Green
    '#E8B04B', // Amber
    '#EE7D4A', // Orange
    '#EF5A6F', // Red
    '#A983F2', // Purple
    '#39B8C2', // Teal
    '#9AA3B2', // Slate
  ];
}

abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 18;
}

abstract final class AppMotion {
  static const Curve standard = Curves.easeOutCubic;
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 360);
}
