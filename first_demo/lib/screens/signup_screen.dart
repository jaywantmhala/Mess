// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_shell.dart';
import 'phone_auth_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey                   = GlobalKey<FormState>();
  final _nameController            = TextEditingController();
  final _emailController           = TextEditingController();
  final _phoneController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _isLoading       = false;
  bool _agreeTerms      = false;

  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  // Design Tokens matching 100% reference photo
  static const Color _brandOrange  = Color(0xFFF58220);
  static const Color _gradientEnd  = Color(0xFFE65100);
  static const Color _bgWarm       = Color(0xFFFDFBF7);
  static const Color _white        = Colors.white;
  static const Color _ink          = Color(0xFF1A1A2E);
  static const Color _greySub      = Color(0xFF6B7280);
  static const Color _fieldBorder  = Color(0xFFE5E7EB);
  static const Color _iconBoxBg    = Color(0xFFFFF0E6);

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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agreeTerms) {
      _showSnack('Please agree to the Terms of Service & Privacy Policy', isError: true);
      return;
    }
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final result = await AuthService.instance.signUp(
      fullName:        _nameController.text.trim(),
      email:           _emailController.text.trim(),
      password:        _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      phoneNumber:     _phoneController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      _showSnack('Account created! Welcome, ${result.customer?.fullName ?? ''}! 🎉', isError: false);
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

  void _goToPhoneAuth() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, _, _) => const PhoneAuthScreen(),
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
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 600;

    return Scaffold(
      backgroundColor: _bgWarm,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 540 : double.infinity),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Column(
                  children: [
                    // ── 1. Hero Section: Logo, Title & Round Shape Food Dish ───
                    Stack(
                      children: [
                        // Soft Peach organic backdrop shape on top right
                        Positioned(
                          right: -20,
                          top: -15,
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFECE5).withOpacity(0.65),
                            ),
                          ),
                        ),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Side: Brand Logo, Welcome Tag & Main Title
                            Expanded(
                              flex: 11,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Original Hungrily Logo
                                  Image.asset(
                                    'assets/images/logo.png',
                                    height: 110,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, _, __) => Image.asset(
                                      'assets/images/hungrily_logo.png',
                                      height: 110,
                                      fit: BoxFit.contain,
                                      errorBuilder: (c2, __, ___) => const SizedBox.shrink(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Welcome to Pill Tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF0E6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.favorite_rounded, size: 13, color: _brandOrange),
                                        SizedBox(width: 5),
                                        Text(
                                          'Join Hungrily',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: _brandOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Right Side: Round Shape Circular Food Dish & 3 Floating Badges
                            Expanded(
                              flex: 10,
                              child: SizedBox(
                                height: 220,
                                child: Stack(
                                  children: [
                                    // Round Shape Pink Circle Food Dish Container
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        width: 195,
                                        height: 195,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFFFFECE5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.06),
                                              blurRadius: 14,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            'assets/images/food_bowl_3d.png',
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, _, __) => const Icon(
                                              Icons.ramen_dining_rounded,
                                              size: 80,
                                              color: _brandOrange,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Badge 1: Top Left - "Find Nearby Restaurants"
                                    Positioned(
                                      top: 5,
                                      left: 0,
                                      child: _buildFoodBadge(
                                        icon: Icons.location_on_rounded,
                                        iconColor: _brandOrange,
                                        title: 'Find Nearby',
                                        subtitle: 'Mess',
                                      ),
                                    ),

                                    // Badge 2: Mid Left - "Fresh & Tasty Everyday"
                                    Positioned(
                                      bottom: 40,
                                      left: 0,
                                      child: _buildFoodBadge(
                                        icon: Icons.dinner_dining_rounded,
                                        iconColor: _brandOrange,
                                        title: 'Fresh & Tasty',
                                        subtitle: 'Everyday',
                                      ),
                                    ),

                                    // Badge 3: Bottom Right - "Top Rated Restaurants"
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: _buildFoodBadge(
                                        icon: Icons.star_rounded,
                                        iconColor: const Color(0xFFF59E0B),
                                        title: 'Top Rated',
                                        subtitle: 'Mess',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── 4. Floating White Curved Form Card ───────────────────────────
                    FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: Container(
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.065),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card Header Row: Icon + Create your account
                              Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: _iconBoxBg,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.person_add_alt_1_rounded, color: _brandOrange, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Create your account',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: _ink,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Fill in your details to get started',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: _greySub,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              // ── Full Name Field ────────────────────────────────
                              const Text(
                                'Full Name',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildFormFieldContainer(
                                child: TextFormField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your full name',
                                    hintStyle: TextStyle(color: Color(0xFFA0A5BA), fontSize: 14, fontWeight: FontWeight.w400),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Full name is required';
                                    if (v.trim().length < 2) return 'Name must be at least 2 characters';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 18),

                              // ── Email Address Field ────────────────────────────
                              const Text(
                                'Email Address',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildFormFieldContainer(
                                child: TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your email',
                                    hintStyle: TextStyle(color: Color(0xFFA0A5BA), fontSize: 14, fontWeight: FontWeight.w400),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Email is required';
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Enter a valid email';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 18),

                              // ── Phone Number Field ────────────────────────────
                              const Text(
                                'Phone Number',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildFormFieldContainer(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your phone number',
                                    hintStyle: TextStyle(color: Color(0xFFA0A5BA), fontSize: 14, fontWeight: FontWeight.w400),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Phone number is required';
                                    if (v.trim().length < 7 || v.trim().length > 20) return 'Enter a valid phone number';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 18),

                              // ── Password Field ─────────────────────────────────
                              const Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildFormFieldContainer(
                                child: TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your password',
                                    hintStyle: TextStyle(color: Color(0xFFA0A5BA), fontSize: 14, fontWeight: FontWeight.w400),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Password is required';
                                    if (v.length < 6) return 'Minimum 6 characters';
                                    return null;
                                  },
                                ),
                                trailing: GestureDetector(
                                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: const Color(0xFFA0A5BA),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // ── Confirm Password Field ─────────────────────────
                              const Text(
                                'Confirm Password',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildFormFieldContainer(
                                child: TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirm,
                                  textInputAction: TextInputAction.done,
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
                                  decoration: const InputDecoration(
                                    hintText: 'Confirm your password',
                                    hintStyle: TextStyle(color: Color(0xFFA0A5BA), fontSize: 14, fontWeight: FontWeight.w400),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Please confirm your password';
                                    if (v != _passwordController.text) return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                                trailing: GestureDetector(
                                  onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(
                                      _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: const Color(0xFFA0A5BA),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // ── Terms & Privacy Checkbox ───────────────────────
                              GestureDetector(
                                onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: _agreeTerms,
                                        activeColor: _brandOrange,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                        side: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
                                        onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'I agree to the Terms of Service & Privacy Policy',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),

                              // ── Create Account Button ─────────────────────────
                              GestureDetector(
                                onTap: _isLoading ? null : _onSignUp,
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
                                                'Create Account',
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
                               const SizedBox(height: 16),

                               // ── Sign Up / Login with Phone Number (WhatsApp OTP) ─────────
                               GestureDetector(
                                 onTap: _goToPhoneAuth,
                                 child: Container(
                                   height: 50,
                                   width: double.infinity,
                                   decoration: BoxDecoration(
                                     color: const Color(0xFF25D366),
                                     borderRadius: BorderRadius.circular(16),
                                     boxShadow: [
                                       BoxShadow(
                                         color: const Color(0xFF25D366).withOpacity(0.3),
                                         blurRadius: 8,
                                         offset: const Offset(0, 3),
                                       ),
                                     ],
                                   ),
                                   child: Row(
                                     mainAxisAlignment: MainAxisAlignment.center,
                                     children: const [
                                       Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 20),
                                       SizedBox(width: 8),
                                       Text(
                                         'Sign Up / Login with Phone OTP',
                                         style: TextStyle(
                                           fontSize: 15,
                                           fontWeight: FontWeight.w800,
                                           color: Colors.white,
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                               ),
                               const SizedBox(height: 16),

                              // ── Already have an account? Sign in Banner ────────
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF5F0),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: const Color(0xFFFFE8DD), width: 1.2),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: RichText(
                                          text: const TextSpan(
                                            text: 'Already have an account? ',
                                            style: TextStyle(fontSize: 13.5, color: _ink, fontWeight: FontWeight.w500),
                                            children: [
                                              TextSpan(
                                                text: 'Sign in  →',
                                                style: TextStyle(
                                                  color: _brandOrange,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.login_rounded, color: _brandOrange, size: 22),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── Footer 3 Badges ────────────────────────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildFooterBadge(Icons.shield_outlined, 'Safe & Secure'),
                                  Container(width: 1, height: 16, color: const Color(0xFFE5E7EB)),
                                  _buildFooterBadge(Icons.verified_outlined, '100% Verified'),
                                  Container(width: 1, height: 16, color: const Color(0xFFE5E7EB)),
                                  _buildFooterBadge(Icons.headset_mic_outlined, '24/7 Support'),
                                ],
                              ),
                            ],
                          ),
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
    );
  }

  Widget _buildFoodBadge({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: _greySub,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormFieldContainer({
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _fieldBorder, width: 1.2),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
      child: Row(
        children: [
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                ),
              ),
              child: child,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }



  Widget _buildFooterBadge(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _brandOrange),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _greySub,
          ),
        ),
      ],
    );
  }
}
