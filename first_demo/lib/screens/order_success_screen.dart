// lib/screens/order_success_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/active_order_service.dart';
import 'order_status_screen.dart';
import 'home_shell.dart';

/// Full-screen order success page matching 100% exact reference design.
class OrderSuccessScreen extends StatefulWidget {
  final int orderId;
  final String? addressDetails;
  final VoidCallback? onOrderPlaced;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    this.addressDetails,
    this.onOrderPlaced,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with TickerProviderStateMixin {
  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _checkController;
  late AnimationController _pulseController;
  late Animation<double> _checkScale;
  late Animation<double> _pulse;

  // ── Countdown ──────────────────────────────────────────────────────────────
  int _secondsLeft = 3;
  Timer? _countdownTimer;
  bool _hasRedirected = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    // Check mark pop animation
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    // Subtle pulse on the circular glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Play success sound
    _audioPlayer.setVolume(1.0).then((_) {
      _audioPlayer
          .play(AssetSource('sounds/success.mp3'))
          .catchError((e) => debugPrint('Sound error: $e'));
    });

    _checkController.forward();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _redirect();
      }
    });
  }

  void _redirect() {
    if (_hasRedirected) return;
    _hasRedirected = true;
    _countdownTimer?.cancel();
    _audioPlayer.dispose();
    widget.onOrderPlaced?.call();

    if (!mounted) return;
    final activeOrder = ActiveOrderService.instance.activeOrderNotifier.value;
    if (activeOrder != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderStatusScreen(initialOrder: activeOrder),
        ),
      );
    } else {
      _goHome();
    }
  }

  void _goHome() {
    if (_hasRedirected) return;
    _hasRedirected = true;
    _countdownTimer?.cancel();
    _audioPlayer.dispose();
    widget.onOrderPlaced?.call();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  void _copyOrderId(String orderCode) {
    Clipboard.setData(ClipboardData(text: orderCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ID $orderCode copied to clipboard!'),
        backgroundColor: const Color(0xFF064E3B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _checkController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderCode = '#ORD${widget.orderId > 0 ? widget.orderId : '26'}';
    final address = (widget.addressDetails?.isNotEmpty == true &&
            !widget.addressDetails!.contains('Fetching'))
        ? widget.addressDetails!
        : 'Office no 20, B Wing, city Vista apartments, Fountain Road, Ashoka Nagar, Kharadi, Pune, Maharashtra 411014, India';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFAF7), // Warm off-white
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── 1. Top Illustration + 3D Orange Check Badge ───────────
                  _buildTopIllustration(),
                  const SizedBox(height: 12),

                  // ── 2. Main Title ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        '🎉 ',
                        style: TextStyle(fontSize: 20),
                      ),
                      Text(
                        'Order Placed Successfully!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF064E3B), // Deep forest green
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        ' 🎉',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── 3. Subtitle ────────────────────────────────────────────
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        const TextSpan(text: 'Your order '),
                        TextSpan(
                          text: orderCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                        const TextSpan(
                          text: ' has been confirmed\nand is being prepared for you.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 4. Main Details Card ───────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Row 1: Order ID + Copy Button ────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Color(0xFFEA580C),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ORDER ID',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF6B7280),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    orderCode,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _copyOrderId(orderCode),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFFFFEDD5), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.copy_rounded,
                                        size: 14, color: Color(0xFFEA580C)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Copy',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFEA580C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: Color(0xFFF3F4F6), height: 1),
                        ),

                        // ── Row 2: Delivery Address ──────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: Color(0xFFEA580C),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DELIVERY TO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF6B7280),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    address,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                      height: 1.35,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF334155),
                              size: 22,
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: Color(0xFFF3F4F6), height: 1),
                        ),

                        // ── Row 3: Estimated Time & Status Badge ─────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFFEA580C),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'ESTIMATED TIME',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF6B7280),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '30 – 45 minutes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Status Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.delivery_dining_rounded,
                                    color: Color(0xFF15803D),
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'On the way',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 5. Redirecting Banner ──────────────────────────────────
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4), // Mint tint
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.explore_rounded,
                              color: Color(0xFF15803D),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                const TextSpan(text: 'Redirecting to live tracking in '),
                                TextSpan(
                                  text: '${_secondsLeft > 0 ? _secondsLeft : 1} s...',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFEA580C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Circular Progress Counter
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _secondsLeft / 3,
                                strokeWidth: 2.5,
                                backgroundColor: const Color(0xFFE2E8F0),
                                color: const Color(0xFFF97316),
                              ),
                              Text(
                                '${_secondsLeft > 0 ? _secondsLeft : 1}s',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 6. Track Order Live Button ─────────────────────────────
                  GestureDetector(
                    onTap: _redirect,
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6A00), Color(0xFFEE4000)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6A00).withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Icon(
                              Icons.map_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            Text(
                              'Track Order Live',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _goHome,
                    icon: const Icon(Icons.home_rounded, color: Color(0xFFF58220)),
                    label: const Text(
                      'Go to Home Screen',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF58220),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: Color(0xFFF58220), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── 7. SMS & Notification Footnote ─────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF15803D),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'You will receive an SMS and notifications shortly',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Top Illustration Header with confetti & 3D orange check mark badge
  Widget _buildTopIllustration() {
    return SizedBox(
      width: 280,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Scooter & Food Cloche Outlines
          Positioned(
            left: 10,
            bottom: 10,
            child: Icon(
              Icons.two_wheeler_rounded,
              size: 56,
              color: const Color(0xFFF3F4F6).withOpacity(0.8),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Icon(
              Icons.soup_kitchen_rounded,
              size: 56,
              color: const Color(0xFFF3F4F6).withOpacity(0.8),
            ),
          ),

          // Floating Confetti Shapes
          Positioned(
            top: 10,
            left: 40,
            child: _confettiDot(const Color(0xFF15803D), 8),
          ),
          Positioned(
            top: 24,
            right: 50,
            child: _confettiDot(const Color(0xFFF97316), 7),
          ),
          Positioned(
            bottom: 30,
            left: 70,
            child: _confettiDot(const Color(0xFFEA580C), 6),
          ),
          Positioned(
            bottom: 25,
            right: 70,
            child: _confettiDot(const Color(0xFF15803D), 8),
          ),

          // ── Center 3D Orange Circle with Checkmark ──────────────────────────
          ScaleTransition(
            scale: _checkScale,
            child: ScaleTransition(
              scale: _pulse,
              child: Container(
                width: 105,
                height: 105,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA043), Color(0xFFF97316)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF97316).withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFA6400), Color(0xFFE65100)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confettiDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(size / 3),
      ),
    );
  }
}
