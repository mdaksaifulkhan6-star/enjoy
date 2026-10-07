import 'package:flutter/material.dart';

/// Design tokens — extracted from the official ENJOY logo.
class AppColors {
  AppColors._();

  // Brand (from logo gradient)
  static const Color primary = Color(0xFFE6007E); // deep pink
  static const Color secondary = Color(0xFFFF8A00); // orange
  static const Color accent = Color(0xFFFFC400); // yellow

  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light mode
  static const Color bgLight = Color(0xFFFDF6F9);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF1A0A14);

  // Dark mode
  static const Color bgDark = Color(0xFF160A12);
  static const Color surfaceDark = Color(0xFF241019);
  static const Color textPrimaryDark = Color(0xFFF5E9EF);

  // Status
  static const Color online = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE53935);
}