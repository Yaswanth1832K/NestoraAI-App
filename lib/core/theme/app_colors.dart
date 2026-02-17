import 'package:flutter/material.dart';

/// Application color palette.
abstract final class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFFFF385C); // Airbnb Red
  static const Color primaryDark = Color(0xFFD90B3E);
  static const Color primaryLight = Color(0xFFFF385C);

  // Neutral
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF000000); // Keep pure black for dark mode if needed
  static const Color surfaceDark = Color(0xFF1E1E1E);

  static const Color textPrimaryLight = Color(0xFF222222);
  static const Color textSecondaryLight = Color(0xFF717171);
  static const Color textPrimaryDark = Color(0xFFF7F7F7);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Semantic
  static const Color success = Color(0xFF008A05);
  static const Color error = Color(0xFFE12C60);
  static const Color warning = Color(0xFFE07E00);
}
