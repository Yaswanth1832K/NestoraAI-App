import 'package:flutter/material.dart';

/// Application color palette.
abstract final class AppColors {
  AppColors._();

  // Primary brand palette (Vibrant Purple & Indigo)
  static const Color primary = Color(0xFF6C63FF); 
  static const Color primaryDark = Color(0xFF5B7CFA);
  static const Color primaryLight = Color(0xFF8F89FF);
  static const Color primaryGlow = Color(0xFF6C63FF);

  // Accent Colors (Colorful highlights)
  static const Color accentOrange = Color(0xFFFF8A00);
  static const Color accentTeal = Color(0xFF00C2A8);
  static const Color accentPink = Color(0xFFFF5C8A);
  static const Color accentBlue = Color(0xFF3B82F6);

  // Surface & Neutrals
  static const Color backgroundLight = Color(0xFFF8F9FF); 
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLight2 = Color(0xFFF0F2FF);
  
  static const Color backgroundDark = Color(0xFF070708); // Thicker Black
  static const Color surfaceDark = Color(0xFF101114);
  static const Color surfaceDark2 = Color(0xFF181A1F);

  static const Color textPrimaryLight = Color(0xFF1E293B);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF2D3748);

  // Standard Gradients
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF5B7CFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF8A00), Color(0xFFFD3D6E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF00C2A8), Color(0xFF007ADF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Spacing Scale
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s48 = 48.0;

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}
