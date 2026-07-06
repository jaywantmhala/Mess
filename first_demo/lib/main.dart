import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const coral = Color(0xFFF07070);
    const coralDark = Color(0xFFE05555);

    return MaterialApp(
      title: 'ZenQube Dining',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: coral,
          primary: coral,
          onPrimary: Colors.white,
          secondary: coralDark,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: const Color(0xFF1A1A2E),
          background: const Color(0xFFF9FAFB),
          onBackground: const Color(0xFF1A1A2E),
          error: const Color(0xFFEF4444),
        ),
        // Input fields default to outlined style
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: coral, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
          ),
        ),
        // ElevatedButton defaults
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: coral,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: coral.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        // AppBar defaults (light, minimal)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          centerTitle: false,
        ),
        // Divider
        dividerColor: const Color(0xFFE5E7EB),
      ),
      home: const WelcomeScreen(),
    );
  }
}
