// lib/screens/welcome_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late AnimationController _contentCtrl;
  late AnimationController _floatCtrl;

  late Animation<double> _heroFade;
  late Animation<double> _heroScale;
  late Animation<Offset> _contentSlide;
  late Animation<double> _contentFade;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();

    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000));

    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroScale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _heroCtrl, curve: Curves.elasticOut));

    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
            CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));
    _contentFade =
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);

    _float = Tween<double>(begin: 0, end: 2 * math.pi).animate(_floatCtrl);

    // Staggered entry
    _heroCtrl.forward();
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) _contentCtrl.forward();
    });
    // Infinite float loop
    _floatCtrl.repeat();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _contentCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  void _goLogin() => Navigator.push(
      context, _slideRoute(const LoginScreen()));

  void _goSignup() => Navigator.push(
      context, _slideRoute(const SignupScreen()));

  Route _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, anim, __) => page,
      transitionDuration: const Duration(milliseconds: 380),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
                begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;
    final isWide = w >= 600;
    final hPad = Responsive.hPad(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // ── Background blobs ──────────────────────────────────────
          Positioned(
            top: -h * 0.08,
            right: -w * 0.2,
            child: _GlowBlob(
              size: w * 0.7,
              color: AppColors.primary.withOpacity(0.10),
            ),
          ),
          Positioned(
            bottom: h * 0.1,
            left: -w * 0.15,
            child: _GlowBlob(
              size: w * 0.5,
              color: AppColors.accent.withOpacity(0.08),
            ),
          ),

          // ── Content ───────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Responsive.maxWidth(context)),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // ── Hero icon ──────────────────────────────────
                      FadeTransition(
                        opacity: _heroFade,
                        child: ScaleTransition(
                          scale: _heroScale,
                          child: AnimatedBuilder(
                            animation: _float,
                            builder: (_, child) {
                              final dy =
                                  math.sin(_float.value) * 6.0;
                              return Transform.translate(
                                offset: Offset(0, dy),
                                child: child,
                              );
                            },
                            child: _HeroIllustration(isWide: isWide),
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.05),

                      // ── Typography ─────────────────────────────────
                      SlideTransition(
                        position: _contentSlide,
                        child: FadeTransition(
                          opacity: _contentFade,
                          child: Column(
                            children: [
                              // Badge pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.auto_awesome_rounded,
                                        size: 13,
                                        color: AppColors.primary),
                                    SizedBox(width: 6),
                                    Text(
                                      'Vendor Partner Portal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'ZenQube\nVendor',
                                textAlign: TextAlign.center,
                                style: AppText.displayLarge.copyWith(
                                  fontSize: isWide ? 44 : 38,
                                  foreground: Paint()
                                    ..shader = const LinearGradient(
                                      colors: [
                                        AppColors.primaryDeep,
                                        AppColors.primary,
                                        AppColors.accent,
                                      ],
                                    ).createShader(
                                      const Rect.fromLTWH(0, 0, 300, 80),
                                    ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Manage your hotels, verify locations,\nand attract more guests — all in one place.',
                                textAlign: TextAlign.center,
                                style: AppText.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

                      // ── Buttons ────────────────────────────────────
                      FadeTransition(
                        opacity: _contentFade,
                        child: Column(
                          children: [
                            AppPrimaryButton(
                              label: 'Sign In',
                              icon: Icons.login_rounded,
                              onPressed: _goLogin,
                            ),
                            const SizedBox(height: 14),
                            AppOutlinedButton(
                              label: 'Create Account',
                              icon: Icons.person_add_rounded,
                              onPressed: _goSignup,
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'By continuing, you agree to our Terms & Privacy Policy',
                              textAlign: TextAlign.center,
                              style: AppText.caption.copyWith(fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: mq.padding.bottom + 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Decorative blob ──────────────────────────────────────────────────────────
class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// ── Hero Illustration ────────────────────────────────────────────────────────
class _HeroIllustration extends StatelessWidget {
  final bool isWide;

  const _HeroIllustration({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final size = isWide ? 180.0 : 150.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring
        Container(
          width: size + 48,
          height: size + 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withOpacity(0.06),
                AppColors.primary.withOpacity(0.0),
              ],
            ),
          ),
        ),
        // Mid ring
        Container(
          width: size + 20,
          height: size + 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primarySurface,
          ),
        ),
        // Icon container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.heroGradient,
            boxShadow: AppShadows.elevated,
          ),
          child: Icon(
            Icons.store_mall_directory_rounded,
            size: size * 0.44,
            color: Colors.white,
          ),
        ),
        // Floating badge: top-right
        Positioned(
          top: 12,
          right: 0,
          child: _FloatingBadge(
            icon: Icons.hotel_rounded,
            label: 'Hotels',
            color: AppColors.accent,
          ),
        ),
        // Floating badge: bottom-left
        Positioned(
          bottom: 12,
          left: 0,
          child: _FloatingBadge(
            icon: Icons.verified_rounded,
            label: 'Verified',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FloatingBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
