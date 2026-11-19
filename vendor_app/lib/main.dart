import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'services/driver_auth_service.dart';
import 'services/fcm_service.dart';
import 'services/app_update_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_shell.dart';
import 'screens/driver_home_shell.dart';
import 'theme/app_theme.dart';
import 'utils/api_client.dart';

import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppUpdateService.instance.initialize(navigatorKey: navigatorKey);
  await FcmService.instance.initialize();

  // System UI styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final activeRole = prefs.getString('active_role');

  final isVendorLoggedIn = await AuthService.instance.isLoggedIn();
  final isDriverLoggedIn = await DriverAuthService.instance.isLoggedIn();

  // Handle global unauthenticated / session expired event
  ApiClient.instance.onUnauthenticated.listen((_) async {
    final navState = navigatorKey.currentState;
    final ctx = navigatorKey.currentContext;
    await AuthService.instance.logout();
    await DriverAuthService.instance.logout();
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

  runApp(MyApp(
    activeRole: activeRole,
    isVendorLoggedIn: isVendorLoggedIn,
    isDriverLoggedIn: isDriverLoggedIn,
  ));

  // Check for Google Play in-app updates after UI finishes mounting
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AppUpdateService.instance.checkForUpdate();
  });
}

class MyApp extends StatelessWidget {
  final String? activeRole;
  final bool isVendorLoggedIn;
  final bool isDriverLoggedIn;

  const MyApp({
    super.key,
    this.activeRole,
    required this.isVendorLoggedIn,
    required this.isDriverLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    Widget initialScreen;
    if (activeRole == 'driver' && isDriverLoggedIn) {
      initialScreen = const DriverHomeShell();
    } else if (activeRole == 'vendor' && isVendorLoggedIn) {
      initialScreen = const HomeShell();
    } else if (isDriverLoggedIn) {
      initialScreen = const DriverHomeShell();
    } else if (isVendorLoggedIn) {
      initialScreen = const HomeShell();
    } else {
      initialScreen = const WelcomeScreen();
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: "Hungrily Vendor",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: initialScreen,
    );
  }
}
