// lib/screens/order_delivered_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'home_shell.dart';

/// Full-screen congratulations screen shown instantly when order is delivered.
/// Plays success.mp3, shows a confetti-style celebration, and auto-redirects
/// to home after 3 seconds.
class OrderDeliveredScreen extends StatefulWidget {
  final String hotelName;
  final double grandTotal;

  const OrderDeliveredScreen({
    super.key,
    required this.hotelName,
    required this.grandTotal,
  });

  @override
  State<OrderDeliveredScreen> createState() => _OrderDeliveredScreenState();
}

class _OrderDeliveredScreenState extends State<OrderDeliveredScreen>
    with TickerProviderStateMixin {
  // ── Audio ───────────────────────────────────────────────────────────────────
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ── Animations ──────────────────────────────────────────────────────────────
  late AnimationController _checkCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _confettiCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _checkScale;
  late Animation<double> _fadeIn;
  late Animation<double> _pulse;

  // ── Countdown ───────────────────────────────────────────────────────────────
  int _secondsLeft = 3;
  Timer? _countdownTimer;
  bool _hasRedirected = false;

  // ── Confetti particles ───────────────────────────────────────────────────────
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Generate confetti
    for (int i = 0; i < 60; i++) {
      _particles.add(_ConfettiParticle.random(_random));
    }

    // Check mark pop
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _checkScale = CurvedAnimation(
      parent: _checkCtrl,
      curve: Curves.elasticOut,
    );

    // Fade in text
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    // Confetti fall
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Pulse on circle
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Play sound
    _audioPlayer.setVolume(1.0).then((_) {
      _audioPlayer
          .play(AssetSource('sounds/success.mp3'))
          .catchError((e) => debugPrint('Sound error: $e'));
    });

    // Sequence animations
    _checkCtrl.forward().then((_) => _fadeCtrl.forward());

    // Countdown
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
        _goHome();
      }
    });
  }

  void _goHome() {
    if (_hasRedirected) return;
    _hasRedirected = true;
    _countdownTimer?.cancel();
    _audioPlayer.dispose();
    if (!mounted) return;

    // Pop all screens and go to HomeShell (fresh)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _checkCtrl.dispose();
    _fadeCtrl.dispose();
    _confettiCtrl.dispose();
    _pulseCtrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            // ── Background gradient ────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F0C29), Color(0xFF1E1B4B), Color(0xFF302B63)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // ── Confetti layer ─────────────────────────────────────────────
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, _w) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiCtrl.value,
                  ),
                  size: MediaQuery.of(context).size,
                );
              },
            ),

            // ── Main content ───────────────────────────────────────────────
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Stars decorative row ──────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (i) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: AnimatedBuilder(
                              animation: _confettiCtrl,
                              builder: (_, _w) {
                                final delay = i * 0.15;
                                final t = ((_confettiCtrl.value - delay)
                                        .clamp(0.0, 1.0) *
                                    2 *
                                    pi);
                                final scale =
                                    0.85 + 0.15 * sin(t).abs();
                                return Transform.scale(
                                  scale: scale,
                                  child: Icon(
                                    Icons.star_rounded,
                                    color: const Color(0xFFFFD700),
                                    size: 28,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Animated check circle ────────────────────────
                      ScaleTransition(
                        scale: _checkScale,
                        child: ScaleTransition(
                          scale: _pulse,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF43E97B),
                                  Color(0xFF38F9D7)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF43E97B)
                                      .withOpacity(0.5),
                                  blurRadius: 50,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 75,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Headline ──────────────────────────────────────
                      FadeTransition(
                        opacity: _fadeIn,
                        child: Column(
                          children: [
                            const Text(
                              '🎉 Congratulations!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'Your order has been\ndelivered successfully!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFFD1FAE5),
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ── Order card ──────────────────────────
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _deliveryRow(
                                    Icons.restaurant_rounded,
                                    const Color(0xFFFFB347),
                                    widget.hotelName,
                                    'Restaurant',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 14),
                                    child: Divider(
                                        color: Colors.white24,
                                        height: 1),
                                  ),
                                  _deliveryRow(
                                    Icons.receipt_long_rounded,
                                    const Color(0xFF60A5FA),
                                    '₹${widget.grandTotal.toStringAsFixed(0)}',
                                    'Total paid',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 14),
                                    child: Divider(
                                        color: Colors.white24,
                                        height: 1),
                                  ),
                                  _deliveryRow(
                                    Icons.local_shipping_rounded,
                                    const Color(0xFF34D399),
                                    'Delivered',
                                    'Status',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // ── Countdown pill ──────────────────────
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 13),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                    color: Colors.white30, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.home_rounded,
                                      color: Colors.white70, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Going to Home in $_secondsLeft s...',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Go home now button ──────────────────
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: _goHome,
                                icon: const Icon(Icons.home_rounded,
                                    size: 22),
                                label: const Text(
                                  'Go to Home',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1E1B4B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deliveryRow(
      IconData icon, Color iconColor, String value, String label) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Confetti ──────────────────────────────────────────────────────────────────

class _ConfettiParticle {
  final double x; // 0..1 horizontal start
  final double startY; // -0.3..0 (above screen)
  final double speed; // 0.3..1.0
  final double size;
  final Color color;
  final double rotationSpeed;
  final double xDrift;

  const _ConfettiParticle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotationSpeed,
    required this.xDrift,
  });

  factory _ConfettiParticle.random(Random r) {
    const colors = [
      Color(0xFFFFD700),
      Color(0xFFFF6B6B),
      Color(0xFF43E97B),
      Color(0xFF60A5FA),
      Color(0xFFF472B6),
      Color(0xFFFBBF24),
      Color(0xFFA78BFA),
    ];
    return _ConfettiParticle(
      x: r.nextDouble(),
      startY: -r.nextDouble() * 0.4,
      speed: 0.25 + r.nextDouble() * 0.55,
      size: 6 + r.nextDouble() * 10,
      color: colors[r.nextInt(colors.length)],
      rotationSpeed: (r.nextDouble() - 0.5) * 6,
      xDrift: (r.nextDouble() - 0.5) * 0.3,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress; // 0..1 (repeating)

  const _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    for (final p in particles) {
      // Each particle has its own phase offset so they spread over time
      final phase = (progress * p.speed) % 1.0;
      final y = (p.startY + phase * 1.4) * size.height;
      if (y > size.height + 20) continue;

      final x = (p.x + sin(phase * pi * 4 + p.x * 10) * p.xDrift) *
          size.width;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotationSpeed * pi * 2);

      paint.color = p.color.withOpacity(
          (1.0 - (y / size.height).clamp(0.0, 1.0) * 0.6).clamp(0.0, 1.0));

      // Alternate rect vs circle
      if (particles.indexOf(p) % 3 == 0) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.55),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
