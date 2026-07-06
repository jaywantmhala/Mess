// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

// ─── Brand Palette ────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Primary vibrant food red
  static const primary = Color(0xFFE23744);
  static const primaryDeep = Color(0xFFCB202D);
  static const primaryLight = Color(0xFFFF6975);
  static const primarySurface = Color(0xFFFCEAEB);

  // Accent
  static const accent = Color(0xFFF9A825);
  static const accentSurface = Color(0xFFFFF6E5);

  // Neutrals
  static const ink = Color(0xFF0F0F1A);
  static const inkSoft = Color(0xFF1E1E2E);
  static const inkMid = Color(0xFF3A3A4E);
  static const textSecondary = Color(0xFF6E6E85);
  static const textHint = Color(0xFFA0A0B8);

  // Surfaces
  static const surface = Color(0xFFFAFBFF);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF4F5FF);

  // Borders
  static const border = Color(0xFFE8E8F0);
  static const borderFocus = primary;

  // Status
  static const success = Color(0xFF10B981);
  static const successSurface = Color(0xFFECFDF5);
  static const error = Color(0xFFEF4444);
  static const errorSurface = Color(0xFFFEF2F2);
  static const warning = Color(0xFFF59E0B);

  // Gradient
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDeep],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
    colors: [Color(0xFFE23744), Color(0xFFD32F2F), Color(0xFFC62828)],
  );

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE23744), Color(0xFFFF6975)],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
        borderSide: const BorderSide(color: AppColors.borderFocus, width: 2.0),
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
      color: Color(0x0C0F0F1A),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x080F0F1A),
      blurRadius: 8,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static const elevated = [
    BoxShadow(
      color: Color(0x14FF6B6B),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static const navbar = [
    BoxShadow(
      color: Color(0x180F0F1A),
      blurRadius: 32,
      offset: Offset(0, -4),
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
        // Uses system default font (Roboto on Android, SF Pro on iOS)
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
              fontFamily: 'Outfit',
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

  static bool isPhone(BuildContext ctx) => MediaQuery.of(ctx).size.width < 600;
  static bool isTablet(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 600 &&
      MediaQuery.of(ctx).size.width < 1024;
  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 1024;

  /// Horizontal padding: phone → 20, tablet → 10% of width, desktop → 15% of width
  static double hPad(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    if (w < 600) return 20.0;
    if (w < 1024) return w * 0.1;
    return w * 0.15;
  }

  /// Max-content width for large screens
  static double maxWidth(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    return w > 640 ? 640.0 : w;
  }
}
