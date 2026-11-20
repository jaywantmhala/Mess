// lib/screens/customer_welcome_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class CustomerWelcomeScreen extends StatefulWidget {
  const CustomerWelcomeScreen({super.key});

  @override
  State<CustomerWelcomeScreen> createState() => _CustomerWelcomeScreenState();
}

class _CustomerWelcomeScreenState extends State<CustomerWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Design Tokens matching 100% reference photo
  static const Color _brandOrange  = Color(0xFFF58220);
  static const Color _gradientEnd  = Color(0xFFE65100);
  static const Color _bgWarm       = Color(0xFFFDFBF7);
  static const Color _white        = Colors.white;
  static const Color _ink          = Color(0xFF1A1A2E);
  static const Color _greySub      = Color(0xFF6B7280);
  static const Color _greenCheck   = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
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

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 600;

    return Scaffold(
      backgroundColor: _bgWarm,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 540 : double.infinity),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: IntrinsicHeight(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                            'Welcome to',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: _brandOrange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Main Title Text
                                    RichText(
                                      text: const TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Hungrily ',
                                            style: TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: _brandOrange,
                                            ),
                                          ),
                                          TextSpan(
                                            text: "Food's",
                                            style: TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: _ink,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Text(
                                      'Your Food Companion',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: _ink,
                                        height: 1.15,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Subtitle
                                    const Text(
                                      'Discover delicious food, explore top hotels near you and enjoy seamless ordering every day.',
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

                      // ── 2. "What You'll Get" Section Header ────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('• • • ', style: TextStyle(color: Color(0xFFF5B284), fontSize: 15, fontWeight: FontWeight.w900)),
                          Text(
                            "What You'll Get",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: _ink,
                            ),
                          ),
                          Text(' • • •', style: TextStyle(color: Color(0xFFF5B284), fontSize: 15, fontWeight: FontWeight.w900)),
                        ],
                      ),

                      // ── 3. 3-Card Feature Grid Matrix ──────────────────────────
                      Row(
                        children: [
                          // Card 1: Nearby Hotels
                          Expanded(
                            child: _buildFeatureCard(
                              icon: Icons.location_on_rounded,
                              iconBg: const Color(0xFFE6F4EA),
                              iconColor: _brandOrange,
                              title: 'Nearby Hotels',
                              subtitle: 'Find great mess near your location',
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Card 2: Daily Menus
                          Expanded(
                            child: _buildFeatureCard(
                              icon: Icons.menu_book_rounded,
                              iconBg: const Color(0xFFFFF0E6),
                              iconColor: _brandOrange,
                              title: 'Daily Menus',
                              subtitle: 'Explore daily menu & exciting offers',
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Card 3: Top Rated
                          Expanded(
                            child: _buildFeatureCard(
                              icon: Icons.military_tech_rounded,
                              iconBg: const Color(0xFFFEF3C7),
                              iconColor: const Color(0xFFD97706),
                              title: 'Top Rated',
                              subtitle: 'Choose from top rated & trusted hotels',
                            ),
                          ),
                        ],
                      ),

                      // ── 4. Primary Action Buttons ──────────────────────────────
                      Column(
                        children: [
                          // 1. Let's Get Started Button
                          GestureDetector(
                            onTap: _goLogin,
                            child: Container(
                              height: 52,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_brandOrange, _gradientEnd],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _brandOrange.withOpacity(0.32),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.dinner_dining_rounded, color: _white, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    "Let's Get Started",
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w900,
                                      color: _white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 2. Create Account Button
                          GestureDetector(
                            onTap: _goSignup,
                            child: Container(
                              height: 52,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: _white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _brandOrange, width: 1.3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.person_add_alt_1_rounded, color: _brandOrange, size: 21),
                                  SizedBox(width: 8),
                                  Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w900,
                                      color: _brandOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ── 5. Footer Social Proof & Security Row ──────────────────
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left: Loved by 10K+ Foodies
                            Row(
                              children: [
                                _buildAvatarStack(),
                                const SizedBox(width: 8),
                                RichText(
                                  text: const TextSpan(
                                    text: 'Loved by ',
                                    style: TextStyle(fontSize: 11.5, color: _greySub, fontWeight: FontWeight.w500),
                                    children: [
                                      TextSpan(
                                        text: '10K+ ',
                                        style: TextStyle(color: _brandOrange, fontWeight: FontWeight.w900),
                                      ),
                                      TextSpan(text: 'Foodies'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            // Right: Safe, Secure & Reliable
                            Row(
                              children: const [
                                Icon(Icons.check_circle_rounded, color: _greenCheck, size: 17),
                                SizedBox(width: 4),
                                Text(
                                  'Safe, Secure & Reliable',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: _greySub,
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      height: 135,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9.5,
              color: _greySub,
              fontWeight: FontWeight.w500,
              height: 1.15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack() {
    return SizedBox(
      width: 56,
      height: 22,
      child: Stack(
        children: const [
          Positioned(left: 0, child: _AvatarCircle(color: Color(0xFFFF6B6B))),
          Positioned(left: 11, child: _AvatarCircle(color: Color(0xFF4ECDC4))),
          Positioned(left: 22, child: _AvatarCircle(color: Color(0xFFFFD166))),
          Positioned(left: 33, child: _AvatarCircle(color: Color(0xFF1A535C))),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final Color color;
  const _AvatarCircle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 12),
    );
  }
}
