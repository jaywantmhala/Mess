// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'home_shell.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Password strength
  int _passwordStrength = 0; // 0-4

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

    _passwordCtrl.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final p = _passwordCtrl.text;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(p)) score++;
    setState(() => _passwordStrength = score);
  }

  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final res = await AuthService.instance.signUp(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      confirmPassword: _confirmCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => const HomeShell(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
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
            const Text('Registration Failed',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
          ],
        ),
        content: Text(message, style: AppText.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
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
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: hPad - 8, vertical: 4),
                  child: Row(children: [_BackButton()]),
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
                                  // ── Header ────────────────────────────
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
                                        Icons.person_add_rounded,
                                        color: Colors.white,
                                        size: 26),
                                  ),
                                  const SizedBox(height: 20),
                                  Text('Create\nAccount',
                                      style: AppText.displayMedium),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Register as a vendor and start listing your properties.',
                                    style: AppText.bodyMedium,
                                  ),
                                  const SizedBox(height: 32),

                                  // ── Full Name ─────────────────────────
                                  AppTextField(
                                    controller: _nameCtrl,
                                    label: 'Full Name',
                                    hint: 'John Doe',
                                    icon: Icons.person_outline_rounded,
                                    textInputAction: TextInputAction.next,
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Full name is required';
                                      if (v.length < 2)
                                        return 'Name must be at least 2 characters';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),

                                  // ── Email ─────────────────────────────
                                  AppTextField(
                                    controller: _emailCtrl,
                                    label: 'Email Address',
                                    hint: 'name@example.com',
                                    icon: Icons.email_outlined,
                                    keyboardType:
                                        TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
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
                                  const SizedBox(height: 18),

                                  // ── Password ──────────────────────────
                                  AppTextField(
                                    controller: _passwordCtrl,
                                    label: 'Password',
                                    hint: 'Min. 8 chars, 1 letter & 1 number',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.next,
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
                                      if (v.length < 8)
                                        return 'Must be at least 8 characters';
                                      if (!RegExp(r'[A-Za-z]')
                                              .hasMatch(v) ||
                                          !RegExp(r'[0-9]').hasMatch(v))
                                        return 'Must contain a letter and a number';
                                      return null;
                                    },
                                  ),

                                  // Password strength indicator
                                  if (_passwordCtrl.text.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    _PasswordStrengthBar(
                                        strength: _passwordStrength),
                                  ],
                                  const SizedBox(height: 18),

                                  // ── Confirm Password ──────────────────
                                  AppTextField(
                                    controller: _confirmCtrl,
                                    label: 'Confirm Password',
                                    hint: 'Re-enter your password',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscureConfirm,
                                    textInputAction: TextInputAction.done,
                                    suffixWidget: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.textHint,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscureConfirm = !_obscureConfirm),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Please confirm your password';
                                      if (v != _passwordCtrl.text)
                                        return 'Passwords do not match';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 32),

                                  // ── Create Button ─────────────────────
                                  AppPrimaryButton(
                                    label: 'Create Account',
                                    icon: Icons.person_add_rounded,
                                    isLoading: _isLoading,
                                    onPressed:
                                        _isLoading ? null : _handleSignup,
                                  ),
                                  const SizedBox(height: 24),

                                  Center(
                                    child: GestureDetector(
                                      onTap: () =>
                                          Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const LoginScreen()),
                                      ),
                                      child: RichText(
                                        text: TextSpan(
                                          text:
                                              'Already have an account?  ',
                                          style: AppText.bodyMedium
                                              .copyWith(fontSize: 14),
                                          children: const [
                                            TextSpan(
                                              text: 'Sign In',
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
                                  const SizedBox(height: 40),
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

class _PasswordStrengthBar extends StatelessWidget {
  final int strength;

  const _PasswordStrengthBar({required this.strength});

  Color get _color {
    switch (strength) {
      case 0:
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return const Color(0xFF3B82F6);
      default:
        return AppColors.success;
    }
  }

  String get _label {
    switch (strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      default:
        return 'Strong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final active = i < strength;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: active ? _color : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Password strength: $_label',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _color,
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.maybePop(context),
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
    );
  }
}
