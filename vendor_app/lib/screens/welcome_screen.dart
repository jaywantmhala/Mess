// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'phone_auth_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Design Tokens matching 100% reference photo
  static const Color _brandOrange  = Color(0xFFF58220);
  static const Color _gradientEnd  = Color(0xFFE65100);
  static const Color _bgWarm       = Color(0xFFFBF9F6);
  static const Color _white        = Colors.white;
  static const Color _ink          = Color(0xFF1A1A2E);
  static const Color _greySub      = Color(0xFF6B7280);
  static const Color _greenVerified = Color(0xFF059669);
  static const Color _brandGreen   = Color(0xFF1E7039);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _goLogin() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const LoginScreen()));

  void _goSignup() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const SignupScreen()));

  void _goPhoneAuth() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const PhoneAuthScreen(role: 'vendor')));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWarm,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Top Accents Row (Dot Grid + Hotels Pill Badge) ────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dot Matrix Grid Accent (Top Left)
                      _buildDotGrid(),

                      // Top Right "Hotels" Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.hotel_rounded, size: 18, color: _greenVerified),
                            SizedBox(width: 6),
                            Text(
                              'Hotels',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: _greenVerified,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── 2. Hero Section: Logo + Verified Badge & 3D Hotel ───────
                  Row(
                    children: [
                      // Left side: Logo & Verified Capsule
                      Column(
                        children: [
                          Container(
                            width: 125,
                            height: 125,
                            decoration: const BoxDecoration(
                              color: _white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x11000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Image.asset(
                                'assets/images/hungrily_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (c, _, __) => const Icon(
                                  Icons.restaurant_rounded,
                                  color: _brandOrange,
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Verified Badge Overlay
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.verified_rounded, size: 16, color: _greenVerified),
                                SizedBox(width: 5),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _greenVerified,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),

                      // Right side: High-Res 3D Hotel Storefront Building
                      Expanded(
                        child: Image.asset(
                          'assets/images/hotel_storefront_3d.png',
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (c, _, __) => Image.asset(
                            'assets/images/hotel_illustration.png',
                            height: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (c2, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── 3. Middle Section: Vendor Portal Info & 3 Feature Cards ─
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Main Title & Description
                      Expanded(
                        flex: 11,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Vendor Partner Portal Pill Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0E6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.stars_rounded, size: 14, color: _brandOrange),
                                    SizedBox(width: 4),
                                    Text(
                                      'Vendor Partner Portal',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: _brandOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Main Title: Welcome to Hungrily Food's Vendor Portal
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                'Welcome to',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Hungrily ',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: _brandOrange,
                                        height: 1.25,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "Food's",
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: _brandGreen,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                'Vendor Portal',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: _ink,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Manage your hotels, verify locations, and attract more guests — all in one place.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: _greySub,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Right Column: Floating 3-Feature Cards Stack
                      Expanded(
                        flex: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              _buildFeatureRow(
                                icon: Icons.apartment_rounded,
                                iconBg: const Color(0xFFE6F4EA),
                                iconColor: const Color(0xFF10B981),
                                title: 'Manage Hotels',
                                subtitle: 'Add, edit & manage your hotel listings',
                              ),
                              const Divider(height: 16, color: Color(0xFFF3F4F6)),
                              _buildFeatureRow(
                                icon: Icons.location_on_rounded,
                                iconBg: const Color(0xFFFFF0E6),
                                iconColor: _brandOrange,
                                title: 'Verify Locations',
                                subtitle: 'Keep your locations accurate & trusted',
                              ),
                              const Divider(height: 16, color: Color(0xFFF3F4F6)),
                              _buildFeatureRow(
                                icon: Icons.trending_up_rounded,
                                iconBg: const Color(0xFFFEF3C7),
                                iconColor: const Color(0xFFD97706),
                                title: 'Grow Business',
                                subtitle: 'Attract more customers & increase orders',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── 4. Primary Action Buttons ──────────────────────────────
                  // 1. Sign In Button
                  GestureDetector(
                    onTap: _goLogin,
                    child: Container(
                      height: 64,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_brandOrange, _gradientEnd],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _brandOrange.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.login_rounded, color: _white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: _white,
                                  ),
                                ),
                                Text(
                                  'Access your vendor dashboard',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _white.withOpacity(0.88),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: _white, size: 28),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Create Account Button
                  GestureDetector(
                    onTap: _goSignup,
                    child: Container(
                      height: 64,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _brandOrange, width: 1.3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0E6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_add_alt_1_rounded, color: _brandOrange, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: _brandOrange,
                                  ),
                                ),
                                Text(
                                  "Join Hungrily Food's Partner Network",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _greySub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: _brandOrange, size: 28),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Login / Sign Up with Phone Number (WhatsApp OTP) Button
                  GestureDetector(
                    onTap: _goPhoneAuth,
                    child: Container(
                      height: 64,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF25D366).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Login / Sign Up with Phone',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Fast & secure login with WhatsApp OTP',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.92),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── 5. Footer Terms & Privacy Policy ───────────────────────
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                        ),
                        child: const Icon(Icons.verified_user_outlined, size: 16, color: _greenVerified),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        text: 'By continuing, you agree to our ',
                        style: TextStyle(fontSize: 12, color: _greySub, fontWeight: FontWeight.w500),
                        children: [
                          TextSpan(
                            text: 'Terms & Privacy Policy',
                            style: TextStyle(
                              color: _brandGreen,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDotGrid() {
    return Column(
      children: List.generate(
        3,
        (r) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            children: List.generate(
              4,
              (c) => Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(right: 5),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5B284),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: _greySub,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
