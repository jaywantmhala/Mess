// lib/screens/driver_login_screen.dart
import 'package:flutter/material.dart';
import '../services/driver_auth_service.dart';
import 'driver_signup_screen.dart';
import 'driver_home_shell.dart';
import 'login_screen.dart';

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
  bool _acceptPolicy = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Design Tokens matching 100% reference photo
  static const Color _brandOrange  = Color(0xFFF58220);
  static const Color _gradientEnd  = Color(0xFFE65100);
  static const Color _bgWarm       = Color(0xFFF6F8FA);
  static const Color _white        = Colors.white;
  static const Color _ink          = Color(0xFF1A1A2E);
  static const Color _greySub      = Color(0xFF8A8FA8);
  static const Color _cardBorder   = Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the Policy and Terms to proceed.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

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
        title: const Text('Driver Sign In Failed',
            style: TextStyle(fontWeight: FontWeight.w900, color: _ink)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try Again',
                style: TextStyle(color: _brandOrange, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWarm,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Stack(
          children: [
            // ── 1. Top Orange Header Gradient Banner ────────────────────────
            Container(
              height: 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_brandOrange, _gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // ── 2. Top Header Content & 3D Scooter Illustration ─────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand Logo Image
                          Image.asset(
                            'assets/images/hungrily_logo.png',
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, _, __) => Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: _white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.two_wheeler_rounded, color: _brandOrange, size: 30),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Driver Partner Portal',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _white.withOpacity(0.95),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Driver Sign In',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: _white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "Let's get you back on the road ",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: _white.withOpacity(0.90),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text('🛵', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 3D Scooter Driver Image at Top Right
                    Image.asset(
                      'assets/images/scooter_driver.png',
                      height: 175,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, _, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. Floating White Curved Form Card ───────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 205, left: 18, right: 18, bottom: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Email Field ────────────────────────────────────
                          const Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0E6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.mail_outline_rounded, color: _brandOrange, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your driver email',
                                    hintStyle: TextStyle(color: Color(0xFFA0A5BA), fontSize: 14, fontWeight: FontWeight.w400),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Email is required';
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFF0EBE5)),
                          const SizedBox(height: 20),

                          // ── Password Field ─────────────────────────────────
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0E6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.lock_outline_rounded, color: _brandOrange, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your password',
                                    hintStyle: TextStyle(color: Color(0xFFA0A5BA), fontSize: 14, fontWeight: FontWeight.w400),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Password is required';
                                    return null;
                                  },
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFFA0A5BA),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFF0EBE5)),
                          const SizedBox(height: 18),

                          // ── Terms Checkbox Row ─────────────────────────────
                          Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _acceptPolicy,
                                  activeColor: _brandOrange,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  side: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
                                  onChanged: (v) => setState(() => _acceptPolicy = v ?? false),
                                ),
                              ),
                              const SizedBox(width: 10),
                              RichText(
                                text: const TextSpan(
                                  text: 'I accept the ',
                                  style: TextStyle(fontSize: 13, color: _ink, fontWeight: FontWeight.w500),
                                  children: [
                                    TextSpan(
                                      text: 'Policy',
                                      style: TextStyle(color: _brandOrange, fontWeight: FontWeight.w800),
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Terms',
                                      style: TextStyle(color: _brandOrange, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Driver Sign In Button ──────────────────────────
                          GestureDetector(
                            onTap: _isLoading ? null : _handleLogin,
                            child: Container(
                              height: 54,
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
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(color: _white, strokeWidth: 2.5),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Text(
                                            'Sign In as Driver',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                              color: _white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, color: _white, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Or Continue With Divider ───────────────────────
                          Row(
                            children: const [
                              Expanded(child: Divider(color: Color(0xFFEAEAEA))),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'or continue with',
                                  style: TextStyle(fontSize: 12, color: _greySub, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(child: Divider(color: Color(0xFFEAEAEA))),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── 3 Social Buttons ───────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialCircle(
                                child: const Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              _buildSocialCircle(
                                child: const Icon(Icons.phone_iphone_rounded, color: _brandOrange, size: 22),
                              ),
                              const SizedBox(width: 20),
                              _buildSocialCircle(
                                child: const Icon(Icons.two_wheeler_rounded, color: _brandOrange, size: 22),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Don't Have A Driver Account? Register ─────────
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const DriverSignupScreen()),
                              ),
                              child: RichText(
                                text: const TextSpan(
                                  text: "Don't have a driver account? ",
                                  style: TextStyle(color: _greySub, fontSize: 13.5, fontWeight: FontWeight.w500),
                                  children: [
                                    TextSpan(
                                      text: 'Register',
                                      style: TextStyle(
                                        color: _brandOrange,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Or Continue As Vendor ──────────────────────────
                          Row(
                            children: const [
                              Expanded(child: Divider(color: Color(0xFFEEEEEE))),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('or', style: TextStyle(fontSize: 11.5, color: _greySub)),
                              ),
                              Expanded(child: Divider(color: Color(0xFFEEEEEE))),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Center(
                            child: TextButton.icon(
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              ),
                              icon: const Text('🏨', style: TextStyle(fontSize: 16)),
                              label: const Text(
                                'Continue as Vendor / Mess',
                                style: TextStyle(
                                  color: _brandOrange,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSocialCircle({required Widget child}) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: _white,
        shape: BoxShape.circle,
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
