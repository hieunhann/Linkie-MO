import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Primary Colors ──
  static const Color primaryTeal = Color(0xFF00BCD4);
  static const Color primaryTealLight = Color(0xFF00E5FF);
  static const Color primaryPink = Color(0xFFE91E8C);
  static const Color purple = Color(0xFF9C27B0);
  static const Color purpleDark = Color(0xFF6C3BAA);

  // ── Backgrounds ──
  static const Color bgDark = Color(0xFF0A0A1A);
  static const Color bgDarkAlt = Color(0xFF0D1117);
  static const Color bgDarkCard = Color(0xFF0F1221);
  static const Color cardBg = Color(0xFF1E2433);
  static const Color cardBgAlt = Color(0xFF273556);

  // ── Text Colors ──
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF); // gray-400
  static const Color textTertiary = Color(0xFF6B7280); // gray-500

  // ── Status Colors ──
  static const Color errorColor = Color(0xFFEF4444); // red-500
  static const Color errorColorLight = Color(0xFFF87171); // red-400
  static const Color successColor = Color(0xFF4ADE80); // green-400

  // ── Borders ──
  static Color borderLight = Colors.white.withOpacity(0.05);
  static Color borderMedium = Colors.white.withOpacity(0.10);
  static Color borderStrong = Colors.white.withOpacity(0.20);

  // ── Gradients ──
  static const LinearGradient gradientPink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPink, purple],
  );

  static const LinearGradient gradientTeal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00BCD4), Color(0xFF008BA3)],
  );

  static const LinearGradient gradientHeader = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF00BCD4),
      Color(0xFF6C3BAA),
      Color(0xFF1A1030),
    ],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient gradientVisionMission = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF06D4FF), Color(0xFFE347AF)],
  );

  // ── Theme Data ──
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryTeal,
      colorScheme: const ColorScheme.dark(
        primary: primaryTeal,
        secondary: primaryPink,
        surface: bgDarkCard,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
