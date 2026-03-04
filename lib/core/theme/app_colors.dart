import 'package:flutter/material.dart';

/// Application color palette.
abstract final class AppColors {
  AppColors._();

  // Primary brand palette
  // Primary brand palette (Auth Theme)
  static const Color primary = Color(0xFF7C5CBF); 
  static const Color primaryDark = Color(0xFF634BA9);
  static const Color primaryLight = Color(0xFF9B7FD4);
  static const Color primaryGlow = Color(0xFF9B7FD4);

  // Surface & Neutrals (Marketplace standard)
  static const Color backgroundLight = Color(0xFFF8FAFC); 
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLight2 = Color(0xFFF1F5F9);
  static const Color backgroundDark = Color(0xFF0D0D0D); 
  static const Color surfaceDark = Color(0xFF1C1C1C);
  static const Color surfaceDark2 = Color(0xFF252525);

  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF2D2D2D);

  // Spacing Scale (Strict: 8, 16, 24, 32, 48)
  static const double s8 = 8.0;
  static const double s12 = 12.0; // Missing
  static const double s16 = 16.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s48 = 48.0;

  // Semantic
  static const Color success = Color(0xFF008A05);
  static const Color error = Color(0xFFE12C60);
  static const Color warning = Color(0xFFE07E00);
}
