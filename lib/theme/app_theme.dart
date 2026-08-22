import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color constants from HabitQuest_PRD.md §6.2 (dark + neon "premium gaming" palette).
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0F0F1A);
  static const Color surface = Color(0xFF1A1A2E);

  // Primary / brand — purple
  static const Color purpleStart = Color(0xFF8B5CF6);
  static const Color purpleEnd = Color(0xFFC084FC);

  // Secondary — XP, gold, rewards
  static const Color amberStart = Color(0xFFFBBF24);
  static const Color amberEnd = Color(0xFFF59E0B);

  // Danger — HP loss, missed habit (kept soft, not harsh/stressful)
  static const Color dangerStart = Color(0xFFF87171);
  static const Color dangerEnd = Color(0xFFEF4444);

  // Success — habit completed
  static const Color successStart = Color(0xFF34D399);
  static const Color successEnd = Color(0xFF10B981);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
}

/// Corner radius scale from §6.4 ("Rounded corners throughout, e.g. 16px for cards").
class AppRadius {
  AppRadius._();

  static const double card = 16.0;
}

/// Named gradients for the four accent colors, plus reusable decoration
/// helpers so buttons and progress bars stay visually consistent (§6.2/§6.4).
class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.purpleStart, AppColors.purpleEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient gold = LinearGradient(
    colors: [AppColors.amberStart, AppColors.amberEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient danger = LinearGradient(
    colors: [AppColors.dangerStart, AppColors.dangerEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [AppColors.successStart, AppColors.successEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Decoration for a gradient-filled button, with a soft glow matching
  /// the gradient's leading color (§6.4 "glow effects behind key UI elements").
  static BoxDecoration buttonDecoration(
    LinearGradient gradient, {
    double radius = AppRadius.card,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: gradient.colors.first.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  /// Decoration for the filled portion of a gradient progress bar.
  static BoxDecoration progressBarDecoration(
    LinearGradient gradient, {
    double radius = 8,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

/// Typography from §6.3 — Poppins for headings, Inter (clean/readable) for body.
class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingLarge => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingMedium => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      );
}

/// Centralized ThemeData for the app's MaterialApp.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.purpleStart,
        secondary: AppColors.amberStart,
        error: AppColors.dangerEnd,
        surface: AppColors.surface,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        headlineLarge: AppTypography.headingLarge,
        headlineMedium: AppTypography.headingMedium,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        labelSmall: AppTypography.caption,
      ),
    );
  }
}
