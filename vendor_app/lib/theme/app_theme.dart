// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

// ─── Brand Palette ────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Primary — Zomato/Swiggy fire red
  static const primary = Color(0xFFE23744);
  static const primaryDeep = Color(0xFFC0392B);
  static const primaryLight = Color(0xFFFF6B6B);
  static const primarySurface = Color(0xFFFFF0F0);

  // Warm orange accent — Swiggy-inspired
  static const accent = Color(0xFFFC8019);
  static const accentDeep = Color(0xFFE5701A);
  static const accentLight = Color(0xFFFFB347);
  static const accentSurface = Color(0xFFFFF3E8);

  // Neutrals
  static const ink = Color(0xFF1C1C1E);
  static const inkSoft = Color(0xFF2C2C2E);
  static const inkMid = Color(0xFF48484A);
  static const textSecondary = Color(0xFF6C6C70);
  static const textHint = Color(0xFFAEAEB2);

  // Surfaces
  static const surface = Color(0xFFF8F8F8);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF2F2F7);

  // Borders
  static const border = Color(0xFFE5E5EA);
  static const borderFocus = primary;

  // Status
  static const success = Color(0xFF34C759);
  static const successSurface = Color(0xFFEAFAF0);
  static const error = Color(0xFFFF3B30);
  static const errorSurface = Color(0xFFFFF0EF);
  static const warning = Color(0xFFFF9500);
  static const warningSurface = Color(0xFFFFF5E6);

  // ── Gradients ──────────────────────────────────────────────────────────────

  /// Main brand gradient — Zomato deep red → coral
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE23744), Color(0xFFC0392B)],
  );

  /// Hero header gradient — rich crimson diagonal
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
    colors: [Color(0xFFFF4C5B), Color(0xFFE23744), Color(0xFFC0392B)],
  );

  /// Orange accent gradient — Swiggy-inspired warm
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFC8019), Color(0xFFE5701A)],
  );

  /// Sunset — red → orange for hero banners
  static const sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE23744), Color(0xFFFC8019)],
  );

  /// Card tint gradient (subtle, white overlay for card depth)
  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFE23744)],
  );

  /// Stats gradient — teal for revenue / insights
  static const statsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
  );
}

// ─── Typography ───────────────────────────────────────────────────────────────
class AppText {
  AppText._();

  static const displayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -1.0,
    height: 1.15,
  );

  static const displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.7,
    height: 1.2,
  );

  static const headingLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.4,
  );

  static const headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.3,
  );

  static const headingSmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMid,
    height: 1.6,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.inkMid,
    letterSpacing: 0.1,
  );

  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
    letterSpacing: 0.2,
  );
}

// ─── Input Decoration ─────────────────────────────────────────────────────────
class AppInputDecoration {
  AppInputDecoration._();

  static InputDecoration field({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surfaceCard,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide:
            const BorderSide(color: AppColors.borderFocus, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.error, width: 2.0),
      ),
      errorStyle: const TextStyle(
        color: AppColors.error,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ─── Shadows ──────────────────────────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(
      color: Color(0x0A1C1C1E),
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x061C1C1E),
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static const elevated = [
    BoxShadow(
      color: Color(0x28E23744),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static const accentElevated = [
    BoxShadow(
      color: Color(0x30FC8019),
      blurRadius: 20,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  static const navbar = [
    BoxShadow(
      color: Color(0x141C1C1E),
      blurRadius: 24,
      offset: Offset(0, -3),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x081C1C1E),
      blurRadius: 8,
      offset: Offset(0, -1),
      spreadRadius: 0,
    ),
  ];
}

// ─── Global ThemeData ─────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceCard,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          iconTheme: IconThemeData(color: AppColors.ink),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.8),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      );
}

// ─── Responsive Helpers ───────────────────────────────────────────────────────
class Responsive {
  Responsive._();

  static bool isPhone(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width < 600;
  static bool isTablet(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 600 &&
      MediaQuery.of(ctx).size.width < 1024;
  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 1024;

  static double hPad(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    if (w < 600) return 20.0;
    if (w < 1024) return w * 0.1;
    return w * 0.15;
  }

  static double maxWidth(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    return w > 640 ? 640.0 : w;
  }
}
