import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'services/auth_service.dart';
import 'services/fcm_service.dart';
import 'services/meal_reminder_service.dart';
import 'services/app_update_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_shell.dart';
import 'utils/api_client.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppUpdateService.instance.initialize(navigatorKey: navigatorKey);
  await FcmService.instance.initialize();
  await MealReminderService.instance.initialize();
  final loggedIn = await AuthService.instance.isLoggedIn();

  // Handle global unauthenticated / session expired event
  ApiClient.instance.onUnauthenticated.listen((_) async {
    final navState = navigatorKey.currentState;
    final ctx = navigatorKey.currentContext;
    await AuthService.instance.logout();
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Text('Your session has expired. Please sign in again.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    navState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  });

  runApp(MyApp(loggedIn: loggedIn));

  // Check for Google Play in-app updates after UI finishes mounting
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AppUpdateService.instance.checkForUpdate();
  });
}

class MyApp extends StatelessWidget {
  final bool loggedIn;

  const MyApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    const coral = Color(0xFFF07070);
    const coralDark = Color(0xFFE05555);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: "Hungrily Foods",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: const CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          },
        ),
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          centerTitle: false,
        ),
        dividerColor: const Color(0xFFE5E7EB),
      ),
      home: loggedIn ? const HomeShell() : const WelcomeScreen(),
    );
  }
}
