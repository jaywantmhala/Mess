// lib/screens/driver_login_screen.dart
import 'package:flutter/material.dart';
import '../services/driver_auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'driver_signup_screen.dart';
import 'driver_home_shell.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _entryCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
            CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _fadeAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final res = await DriverAuthService.instance.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => const DriverHomeShell(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
        ),
        (route) => false,
      );
    } else {
      _showErrorDialog(res.message);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Driver Login Failed',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
          ],
        ),
        content: Text(message, style: AppText.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try Again',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.hPad(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Top accent blob
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.07),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: hPad - 8, vertical: 4),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: Responsive.maxWidth(context)),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                            horizontal: hPad, vertical: 8),
                        child: SlideTransition(
                          position: _slideAnim,
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      boxShadow: AppShadows.elevated,
                                    ),
                                    child: const Icon(
                                      Icons.delivery_dining_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text('Driver\nPortal',
                                      style: AppText.displayMedium),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Sign in to access your delivery dashboard.',
                                    style: AppText.bodyMedium,
                                  ),
                                  const SizedBox(height: 36),

                                  AppTextField(
                                    controller: _emailCtrl,
                                    label: 'Email Address',
                                    hint: 'driver@example.com',
                                    icon: Icons.email_outlined,
                                    keyboardType:
                                        TextInputType.emailAddress,
                                    textInputAction:
                                        TextInputAction.next,
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Email is required';
                                      if (!RegExp(
                                              r'^[^@]+@[^@]+\.[^@]+')
                                          .hasMatch(v))
                                        return 'Enter a valid email';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  AppTextField(
                                    controller: _passwordCtrl,
                                    label: 'Password',
                                    hint: 'Enter your password',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscurePassword,
                                    textInputAction:
                                        TextInputAction.done,
                                    suffixWidget: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.textHint,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscurePassword =
                                              !_obscurePassword),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Password is required';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 36),

                                  AppPrimaryButton(
                                    label: 'Sign In as Driver',
                                    icon: Icons.login_rounded,
                                    isLoading: _isLoading,
                                    onPressed:
                                        _isLoading ? null : _handleLogin,
                                  ),
                                  const SizedBox(height: 24),

                                  Center(
                                    child: GestureDetector(
                                      onTap: () =>
                                          Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const DriverSignupScreen()),
                                      ),
                                      child: RichText(
                                        text: TextSpan(
                                          text:
                                              "Don't have a driver account?  ",
                                          style: AppText.bodyMedium
                                              .copyWith(fontSize: 14),
                                          children: const [
                                            TextSpan(
                                              text: 'Register',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight:
                                                    FontWeight.w700,
                                                decoration: TextDecoration
                                                    .underline,
                                                decorationColor:
                                                    AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
