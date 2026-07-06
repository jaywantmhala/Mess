import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/zenqube_logo.dart';

class LoadingScreen extends StatefulWidget {
  final VoidCallback onLoadingComplete;

  const LoadingScreen({
    super.key,
    required this.onLoadingComplete,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  double _progress = 0.0;
  String _statusText = 'Booting ZenQube Portal...';
  Timer? _timer;
  late AnimationController _fadeController;
  late AnimationController _gridController;

  final List<Map<String, dynamic>> _loadingStages = [
    {'min': 0.0, 'max': 0.15, 'text': 'Booting ZenQube Portal...'},
    {'min': 0.15, 'max': 0.40, 'text': 'Connecting to dining databases...'},
    {'min': 0.40, 'max': 0.70, 'text': 'Caching weekly menu plans...'},
    {'min': 0.70, 'max': 0.90, 'text': 'Synchronizing smart meal tokens...'},
    {'min': 0.90, 'max': 0.99, 'text': 'Finalizing secure connection...'},
    {'min': 1.0, 'max': 1.0, 'text': 'Welcome to ZenQube Dining!'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _startLoading();
  }

  void _startLoading() {
    // Web-style simulated loader with variable speed increments
    const period = Duration(milliseconds: 80);
    _timer = Timer.periodic(period, (timer) {
      if (!mounted) return;

      setState(() {
        double increment = 0.01;
        // Introduce simulated loading spikes/pauses
        if (_progress < 0.2) {
          increment = 0.025; // initial fast loading
        } else if (_progress >= 0.2 && _progress < 0.35) {
          increment = 0.008; // slow down
        } else if (_progress >= 0.35 && _progress < 0.6) {
          increment = 0.018; // medium speed
        } else if (_progress >= 0.6 && _progress < 0.75) {
          increment = 0.005; // heavy pause (simulating DB query)
        } else if (_progress >= 0.75 && _progress < 0.95) {
          increment = 0.022; // speed up again
        } else {
          increment = 0.012; // slow down near completion
        }

        _progress = math.min(_progress + increment, 1.0);

        // Update status text based on progress
        for (var stage in _loadingStages) {
          if (_progress >= stage['min'] && _progress <= stage['max']) {
            _statusText = stage['text'];
            break;
          }
        }

        if (_progress >= 1.0) {
          _timer?.cancel();
          _statusText = 'Welcome to ZenQube Dining!';
          // Grace period for completion before triggering navigation
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              _fadeController.forward().then((_) {
                widget.onLoadingComplete();
              });
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF010610),
      body: Stack(
        children: [
          // 1. Moving tech-grid background
          AnimatedBuilder(
            animation: _gridController,
            builder: (context, child) {
              return Positioned.fill(
                child: CustomPaint(
                  painter: TechGridPainter(
                    animationProgress: _gridController.value,
                  ),
                ),
              );
            },
          ),
          
          // 2. Glowing ambient circles in background
          Positioned(
            top: size.height * 0.15,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9000FF).withOpacity(0.08),
              ),
              child: const SizedBox(),
            ),
          ),
          Positioned(
            bottom: size.height * 0.1,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C6FF).withOpacity(0.08),
              ),
              child: const SizedBox(),
            ),
          ),

          // 3. Main content (Center Logo, Loading Progress, Details)
          FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 0.92).animate(
                CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      // Glowing, pulsating vector logo
                      ZenQubeLogo(
                        size: 200,
                        showText: true,
                        animate: true,
                        progress: _progress,
                      ),
                      const Spacer(flex: 2),
                      
                      // Progress Bar & Percentage
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SYSTEM BOOT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.4),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                '${(_progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF00C6FF),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Custom linear progress indicator
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  widthFactor: _progress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF9000FF),
                                          Color(0xFF00C6FF),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00C6FF).withOpacity(0.4),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Status Description (Animated switcher for text)
                      SizedBox(
                        height: 40,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.2),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _statusText,
                            key: ValueKey<String>(_statusText),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 3),
                      
                      // Footer info
                      Text(
                        'SECURE CONNECTION SSL/AES 256',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.2),
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 30),
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

// Background painter that draws a scrolling cyber-grid
class TechGridPainter extends CustomPainter {
  final double animationProgress;

  TechGridPainter({required this.animationProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 1.0;

    final gridSpacing = 40.0;
    // Calculate vertical offset based on scroll progress
    final offsetY = (animationProgress * gridSpacing) % gridSpacing;
    final offsetX = (animationProgress * gridSpacing * 0.5) % gridSpacing;

    // Draw vertical lines
    for (double x = offsetX; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = offsetY; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw crosshair dots at intersections for high-tech feeling
    final dotPaint = Paint()
      ..color = const Color(0xFF00C6FF).withOpacity(0.04)
      ..style = PaintingStyle.fill;

    for (double x = offsetX; x < size.width; x += gridSpacing * 2) {
      for (double y = offsetY; y < size.height; y += gridSpacing * 2) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TechGridPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress;
  }
}
