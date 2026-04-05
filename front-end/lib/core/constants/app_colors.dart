import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF00AA6C);
  static const Color primaryDeep = Color(0xFF004F32);
  static const Color secondary = Color(0xFF34E0A1);
  static const Color accentGold = Color(0xFFF2B203);
  static const Color background = Color(0xFFF6F6F0);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFEFF6F2);
  static const Color border = Color(0xFFDCE6DF);
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textMuted = Color(0xFF667085);
  static const Color error = Color(0xFFD92D20);

  static const Color freshnessGreen = Color(0xFF10B981);
  static const Color freshnessOrange = Color(0xFFF59E0B);
  static const Color freshnessRed = Color(0xFFEF4444);
  static const Color freshnessGray = Color(0xFF9CA3AF);

  AppColors._();

  static Color getMarkerColor(int freshnessScore) {
    if (freshnessScore < 0) {
      return freshnessGray;
    } else if (freshnessScore >= 70) {
      return freshnessGreen;
    } else if (freshnessScore >= 40) {
      return freshnessOrange;
    } else if (freshnessScore >= 0) {
      return freshnessRed;
    } else {
      return freshnessGray;
    }
  }
}
