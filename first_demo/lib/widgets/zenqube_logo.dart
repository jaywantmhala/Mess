import 'dart:math' as math;
import 'package:flutter/material.dart';

class ZenQubeLogo extends StatefulWidget {
  final double size;
  final bool showText;
  final bool animate;
  final double progress; // manual loading progress (0.0 to 1.0)

  const ZenQubeLogo({
    super.key,
    this.size = 180.0,
    this.showText = true,
    this.animate = true,
    this.progress = 1.0,
  });

  @override
  State<ZenQubeLogo> createState() => _ZenQubeLogoState();
}

class _ZenQubeLogoState extends State<ZenQubeLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ZenQubeLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatOffset = widget.animate ? math.sin(_controller.value * 2 * math.pi) * 4.0 : 0.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, floatOffset),
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: ZenQubeLogoPainter(
                    animationValue: _controller.value,
                    progress: widget.progress,
                  ),
                ),
              ),
            ),
            if (widget.showText) ...[
              const SizedBox(height: 20),
              // Brand text matching the logo type
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF1E3C72),
                    Color(0xFF2A5298),
                    Color(0xFF00C6FF),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                child: const Text(
                  'ZENQUBE',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: Colors.white,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '- SOLUTIONS PVT. LTD. -',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.5,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class ZenQubeLogoPainter extends CustomPainter {
  final double animationValue;
  final double progress;

  ZenQubeLogoPainter({
    required this.animationValue,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final outerRingThickness = radius * 0.08;
    final innerCircleRadius = radius - outerRingThickness;
    final cubeRadius = innerCircleRadius * 0.65;

    // 1. Draw Outer Ring Shadow & Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00C6FF).withOpacity(0.15 * progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.15);
    canvas.drawCircle(center, radius, glowPaint);

    // 2. Draw Outer Ring Gradient Line
    // The gradient rotates slowly
    final ringSweepAngle = 2 * math.pi * progress;
    final ringStartAngle = -math.pi / 2 + (animationValue * 2 * math.pi * 0.1);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerRingThickness
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: const [
          Color(0xFF9000FF), // Purple
          Color(0xFF00C6FF), // Cyan
          Color(0xFF0072FF), // Blue
          Color(0xFF9000FF), // Purple
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
        transform: GradientRotation(ringStartAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius - outerRingThickness / 2));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - outerRingThickness / 2),
      -math.pi / 2,
      ringSweepAngle,
      false,
      ringPaint,
    );

    // 3. Draw Inner Circle Background (Dark Navy/Black gradient)
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFF0D1B2A),
          Color(0xFF010811),
        ],
        center: const Alignment(-0.2, -0.2),
        radius: 0.9,
      ).createShader(Rect.fromCircle(center: center, radius: innerCircleRadius));
    canvas.drawCircle(center, innerCircleRadius - 1.5, bgPaint);

    // 4. Draw Inner Circle Border (Sleek dark outline)
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity(0.1);
    canvas.drawCircle(center, innerCircleRadius - 1.5, borderPaint);

    // Save canvas state before drawing the 3D Hexagon Cube
    canvas.save();

    // 5. Draw 3D Hexagonal Cube (ZenQube)
    // Points of hexagon (pointy top orientation)
    // Vertices relative to center:
    // P0 (top): (0, -R)
    // P1 (top-right): (R*cos30, -R*sin30)
    // P2 (bottom-right): (R*cos30, R*sin30)
    // P3 (bottom): (0, R)
    // P4 (bottom-left): (-R*cos30, R*sin30)
    // P5 (top-left): (-R*cos30, -R*sin30)
    final double cos30 = math.cos(math.pi / 6); // sqrt(3)/2
    final double sin30 = math.sin(math.pi / 6); // 0.5

    final p0 = Offset(center.dx, center.dy - cubeRadius);
    final p1 = Offset(center.dx + cubeRadius * cos30, center.dy - cubeRadius * sin30);
    final p2 = Offset(center.dx + cubeRadius * cos30, center.dy + cubeRadius * sin30);
    final p3 = Offset(center.dx, center.dy + cubeRadius);
    final p4 = Offset(center.dx - cubeRadius * cos30, center.dy + cubeRadius * sin30);
    final p5 = Offset(center.dx - cubeRadius * cos30, center.dy - cubeRadius * sin30);

    // Draw background glass glow behind cube
    final cubeGlow = Paint()
      ..color = const Color(0xFF9000FF).withOpacity(0.12 * progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cubeRadius * 0.4);
    canvas.drawCircle(center, cubeRadius, cubeGlow);

    // Draw the 3 facets of the cube (Top, Left, Right)
    final pathTop = Path()..moveTo(center.dx, center.dy)..lineTo(p5.dx, p5.dy)..lineTo(p0.dx, p0.dy)..lineTo(p1.dx, p1.dy)..close();
    final pathLeft = Path()..moveTo(center.dx, center.dy)..lineTo(p5.dx, p5.dy)..lineTo(p4.dx, p4.dy)..lineTo(p3.dx, p3.dy)..close();
    final pathRight = Path()..moveTo(center.dx, center.dy)..lineTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close();

    // Paints for each face (glassy 3D effects with cyan, purple, blue)
    final paintTop = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF6B48FF).withOpacity(0.85),
          const Color(0xFF00D2FF).withOpacity(0.60),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromCircle(center: center, radius: cubeRadius));

    final paintLeft = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF1E3C72).withOpacity(0.80),
          const Color(0xFF9000FF).withOpacity(0.70),
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromCircle(center: center, radius: cubeRadius));

    final paintRight = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0072FF).withOpacity(0.80),
          const Color(0xFF00F2FE).withOpacity(0.85),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: cubeRadius));

    canvas.drawPath(pathTop, paintTop);
    canvas.drawPath(pathLeft, paintLeft);
    canvas.drawPath(pathRight, paintRight);

    // Draw structural lines/outlines of the cube
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.25);
    
    canvas.drawPath(pathTop, linePaint);
    canvas.drawPath(pathLeft, linePaint);
    canvas.drawPath(pathRight, linePaint);

    // 6. Draw the glowing 3D "Z" inside the Hexagon
    final zThickness = cubeRadius * 0.22;
    
    // Key control points for Z:
    final z0 = Offset(center.dx - cubeRadius * 0.65 * cos30, center.dy - cubeRadius * 0.65 * sin30);
    final z1 = Offset(center.dx + cubeRadius * 0.65 * cos30, center.dy - cubeRadius * 0.65 * sin30);
    final z3 = Offset(center.dx + zThickness * 0.5 * cos30, center.dy - zThickness * 0.5 * sin30);
    final z5 = Offset(center.dx - cubeRadius * 0.65 * cos30, center.dy + cubeRadius * 0.65 * sin30);
    final z6 = Offset(center.dx + cubeRadius * 0.65 * cos30, center.dy + cubeRadius * 0.65 * sin30);
    final z7 = Offset(z6.dx - zThickness * cos30, z6.dy - zThickness * sin30);
    final z8 = Offset(center.dx - zThickness * 0.5 * cos30, center.dy + zThickness * 0.5 * sin30);
    final z9 = Offset(z0.dx + zThickness * cos30, z0.dy + zThickness * sin30);

    final zPath = Path()
      ..moveTo(z0.dx, z0.dy)
      ..lineTo(z1.dx, z1.dy)
      ..lineTo(z8.dx, z8.dy) 
      ..lineTo(z6.dx, z6.dy)
      ..lineTo(z7.dx, z7.dy)
      ..lineTo(z5.dx, z5.dy)
      ..lineTo(z3.dx, z3.dy) 
      ..lineTo(z9.dx, z9.dy)
      ..close();

    final zPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white,
          const Color(0xFF00F2FE),
          const Color(0xFF9000FF),
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: cubeRadius));

    final zShadowPaint = Paint()
      ..color = const Color(0xFF00F2FE).withOpacity(0.6 * progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cubeRadius * 0.15);
    canvas.drawPath(zPath, zShadowPaint);

    canvas.drawPath(zPath, zPaint);

    final zStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withOpacity(0.9);
    canvas.drawPath(zPath, zStrokePaint);

    final highlightPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(center, 3.0, highlightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ZenQubeLogoPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.progress != progress;
  }
}
