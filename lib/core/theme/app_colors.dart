import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF1C0101); // Deep Red/Black
  static const Color backgroundGradientStart = Color(
    0xFF2A0303,
  ); // Slightly lighter red for gradient top
  static const Color backgroundGradientEnd = Color(
    0xFF000000,
  ); // Pure black for bottom

  static const Color surface = Color(0xFF2C2C2C);
  static const Color surfaceLight = Color(0xFF333333);

  // Accents
  static const Color primary = Color(0xFFE50914); // Netflix Red / Strong Red
  static const Color primaryDark = Color(0xFF8B0000);
  static const Color heavyOrange = Color(
    0xFFB74E08,
  ); // For buttons like "Karıştır"

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);

  // UI Elements
  static const Color divider = Color(0xFF2A2A2A);
  static const Color error = Color(0xFFFF3B30);
}
