import 'package:flutter/material.dart';

class AppColors {
  // Primary Dual-Tone Theme: Deep Navy Blue & Warm Orange

  // Primary Colors - Navy Blue Family
  static const Color primaryDark = Color(0xFF1A237E); // Deep Navy
  static const Color primary = Color(0xFF3949AB); // Rich Blue
  static const Color primaryLight = Color(0xFF5C6BC0); // Medium Blue
  static const Color primaryLighter = Color(0xFFE8EAF6); // Very Light Blue

  // Secondary Colors - Warm Orange Family
  static const Color secondary = Color(0xFFFF6F00); // Warm Orange
  static const Color secondaryLight = Color(0xFFFF8F00); // Light Orange
  static const Color secondaryLighter = Color(0xFFFFF3E0); // Very Light Orange

  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC); // Off-white background
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Light grey

  // Text Colors
  static const Color textDark = Color(0xFF1E293B); // Dark slate
  static const Color textMedium = Color(0xFF475569); // Medium slate
  static const Color textLight = Color(0xFF94A3B8); // Light slate

  // Status Colors
  static const Color success = Color(0xFF16A34A); // Green
  static const Color warning = Color(0xFFEAB308); // Yellow
  static const Color error = Color(0xFFDC2626); // Red
  static const Color info = Color(0xFF0EA5E9); // Cyan

  // Gradient Combinations
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  // Shadow Colors
  static final Color shadowLight = Colors.black.withOpacity(0.08);
  static final Color shadowMedium = Colors.black.withOpacity(0.12);
  static final Color shadowDark = Colors.black.withOpacity(0.16);

  // Professional Color Schemes for Different Categories
  static const Map<String, Map<String, Color>> categoryColors = {
    'schedules': {
      'primary': primary,
      'background': primaryLighter,
      'text': primaryDark,
    },
    'categories': {
      'primary': secondary,
      'background': secondaryLighter,
      'text': primaryDark,
    },
    'summary': {
      'primary': primaryDark,
      'background': surfaceVariant,
      'text': textDark,
    },
  };

  // Professional box themes
  static BoxDecoration getProfessionalBoxDecoration({
    required String category,
    bool isActive = false,
    bool hasGradient = false,
  }) {
    final colors = categoryColors[category]!;

    return BoxDecoration(
      gradient: hasGradient
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors['primary']!.withOpacity(0.1),
                colors['primary']!.withOpacity(0.05),
              ],
            )
          : null,
      color: hasGradient ? null : colors['background'],
      borderRadius: BorderRadius.circular(16),
      border: isActive
          ? Border.all(color: colors['primary']!, width: 2)
          : Border.all(color: colors['primary']!.withOpacity(0.1), width: 1),
      boxShadow: [
        BoxShadow(
          color: shadowLight,
          offset: const Offset(0, 2),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: shadowMedium,
          offset: const Offset(0, 1),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ],
    );
  }
}
