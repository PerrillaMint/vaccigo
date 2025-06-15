// lib/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary colors extracted from your logo
  static const Color primary = Color(0xFF2C5F66);      // Navy blue - main brand color
  static const Color secondary = Color(0xFF7DD3D8);    // Turquoise - accent color
  static const Color accent = Color(0xFFFFA726);       // Orange - highlight color
  static const Color light = Color(0xFFB8E6EA);        // Light turquoise
  
  // Backgrounds
  static const Color background = Color(0xFFF8FCFD);   // Very light blue-white
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F9FA);
  
  // Text colors
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Color(0xFF2C5F66);
  static const Color onSurface = Color(0xFF2C5F66);
  static const Color textPrimary = Color(0xFF2C5F66);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, light],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFFFFB74D)],
  );
}
