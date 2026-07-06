import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'home_shell.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const kCoralPrimary = Color(0xFFE8614A);
const kCoralLight   = Color(0xFFFF9A7A);
const kBgPage       = Color(0xFFF9FAFB);
const kTextDark     = Color(0xFF1A1A2E);
const kTextMuted    = Color(0xFF6B7280);
const kBorderColor  = Color(0xFFE5E7EB);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe      = false;
  bool _obscurePassword = true;
  bool _isLoading       = false;

  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final result = await AuthService.instance.login(
      email:    _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      _showSnack('Welcome back, ${result.customer?.fullName ?? ''}! 👋', isError: false);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeShell(),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ));
    } else {
      _showSnack(result.message, isError: true);
    }
  }

  void _goToSignUp() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, _, _) => const SignUpScreen(),
      transitionsBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white, size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 4),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: kBgPage,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 480.0 : double.infinity),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Coral Header ─────────────────────────────────────────
                    _AuthHeader(
                      title: 'Welcome Back 👋',
                      subtitle: 'Sign in to continue your\ndining journey',
                      isWide: isWide,
                    ),

                    // ── Form Card ────────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 40 : 22,
                        vertical: 32,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Back button
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.arrow_back_ios_rounded, size: 14, color: kTextMuted),
                                  const SizedBox(width: 4),
                                  Text('Back', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Section title
                            const Text('Sign In', style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w800,
                              color: kTextDark, letterSpacing: -0.5,
                            )),
                            const SizedBox(height: 4),
                            Text(
                              'Enter your credentials to access your account',
                              style: TextStyle(fontSize: 13.5, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 32),

                            // Email
                            _FieldLabel('Email Address'),
                            const SizedBox(height: 8),
                            _OutlinedField(
                              controller: _emailController,
                              hint: 'you@example.com',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Email is required';
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password
                            _FieldLabel('Password'),
                            const SizedBox(height: 8),
                            _OutlinedField(
                              controller: _passwordController,
                              hint: '••••••••',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              obscure: _obscurePassword,
                              onToggleObscure: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Password is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Remember me + Forgot
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 20, height: 20,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5),
                                          color: _rememberMe ? kCoralPrimary : Colors.white,
                                          border: Border.all(
                                            color: _rememberMe ? kCoralPrimary : kBorderColor,
                                            width: 1.8,
                                          ),
                                        ),
                                        child: _rememberMe
                                            ? const Icon(Icons.check, size: 13, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Remember me',
                                        style: TextStyle(fontSize: 13, color: kTextMuted)),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Text('Forgot Password?',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: kCoralPrimary)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),

                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _onLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kCoralPrimary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: kCoralPrimary.withValues(alpha: 0.6),
                                  elevation: 4,
                                  shadowColor: kCoralPrimary.withValues(alpha: 0.35),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22, height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2.5))
                                    : const Text('Login',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Divider
                            Row(children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                              ),
                              const Expanded(child: Divider()),
                            ]),
                            const SizedBox(height: 24),

                            // Sign up link
                            Center(
                              child: GestureDetector(
                                onTap: _goToSignUp,
                                child: RichText(
                                  text: TextSpan(
                                    text: "Don't have an account?  ",
                                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                    children: const [TextSpan(
                                      text: 'Sign up',
                                      style: TextStyle(color: kCoralPrimary, fontWeight: FontWeight.w700),
                                    )],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared auth header widget
// ─────────────────────────────────────────────────────────────────────────────
class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isWide;
  const _AuthHeader({required this.title, required this.subtitle, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isWide ? 40 : 28,
        MediaQuery.of(context).padding.top + (isWide ? 40 : 52),
        isWide ? 40 : 28,
        isWide ? 40 : 48,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8614A), Color(0xFFFF9A7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(top: -30, right: -20,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(bottom: -20, left: -30,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo mark
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(child: Text('🍽', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(height: 24),
              Text(title, style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800,
                color: Colors.white, height: 1.2, letterSpacing: -0.3,
              )),
              const SizedBox(height: 8),
              Text(subtitle, style: TextStyle(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.85), height: 1.5,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared field label
// ─────────────────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
    fontSize: 13.5, fontWeight: FontWeight.w600, color: kTextDark,
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared outlined text field
// ─────────────────────────────────────────────────────────────────────────────
class _OutlinedField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _OutlinedField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 14.5, color: kTextDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
        prefixIcon: Icon(icon, size: 19, color: Colors.grey[400]),
        suffixIcon: isPassword
            ? GestureDetector(
                onTap: onToggleObscure,
                child: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 19, color: Colors.grey[400],
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorderColor, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kCoralPrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        ),
        errorStyle: const TextStyle(fontSize: 11.5),
      ),
    );
  }
}
