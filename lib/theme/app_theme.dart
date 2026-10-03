import 'package:flutter/material.dart';

class AppTheme {
  // ─── CORE BRAND PALETTE ───
  static const Color primaryPurple = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF111827);
  static const Color backgroundLight = Color(0xFFF3F4F6);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);

  // ─── KANBAN & STATUS INTELLIGENCE ───
  static Color getStatusColor(String status) {
    final s = status.toLowerCase().trim();

    switch (s) {
      // 1. Leads Domain
      case 'identified':
        // Slate color representing potential lead
        return const Color(0xFF64748B);
      case 'pitched':
        // Primary brand color for active action
        return primaryPurple;
      case 'negotiating':
        // High-focus warning color for deals needing attention
        return warning;
      case 'won':
        return success;
      case 'lost':
        return error;

      // 2. Project & Pipeline Domain
      case 'active':
      case 'ongoing':
      case 'live':
        return primaryPurple;
      case 'completed':
        return success;
      case 'dropped':
      case 'cancelled':
      case 'inactive':
        return textLight;
      case 'trial':
        return info;

      // 3. Logistics Domain
      case 'shipped':
        return info;
      case 'delivered':
        return success;
      case 'pending':
        return warning;

      default:
        return textLight;
    }
  }

  // ─── COMPONENT THEMES ───
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        primary: primaryPurple,
        surface: Colors.white,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: primaryDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryPurple, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
