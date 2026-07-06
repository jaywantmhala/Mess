import 'dart:math' as math;
import 'package:flutter/material.dart';

// Primary coral color matching the design
const Color kCoralPrimary = Color(0xFFF07070);
const Color kCoralLight = Color(0xFFF49090);
const Color kCoralBg = Color(0xFFF5A0A0);

/// Draws the organic topography contour lines on a coral canvas
class TopographyBackground extends StatelessWidget {
  final Widget? child;
  final double topFraction;

  const TopographyBackground({
    super.key,
    this.child,
    this.topFraction = 0.60,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Coral background
        Positioned.fill(
          child: Container(color: kCoralPrimary),
        ),

        // 2. Topography contour lines painted on top
        Positioned.fill(
          child: CustomPaint(
            painter: TopographyPainter(),
          ),
        ),

        // 3. White wave at the bottom
        Positioned.fill(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * topFraction),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 4. Wave clipper between coral and white
        Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.of(context).size.height * topFraction - 80,
          child: ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: 120,
              color: Colors.white,
            ),
          ),
        ),

        ?child,
      ],
    );
  }
}

/// Wave-shaped clipper for the bottom white panel
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, 50);
    path.cubicTo(
      size.width * 0.15, -10,
      size.width * 0.35, 80,
      size.width * 0.55, 40,
    );
    path.cubicTo(
      size.width * 0.72, 10,
      size.width * 0.85, 80,
      size.width, 30,
    );
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant WaveClipper oldClipper) => false;
}

/// Painter that draws organic topographic contour lines
class TopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw multiple organic contour curves
    // Each "contour" is a closed bezier path centered at different positions
    _drawContourSet(canvas, size, paint, Offset(size.width * 0.35, size.height * 0.25), 5);
    _drawContourSet(canvas, size, paint, Offset(size.width * 0.78, size.height * 0.18), 4);
    _drawContourSet(canvas, size, paint, Offset(size.width * 0.10, size.height * 0.55), 3);
    _drawContourSet(canvas, size, paint, Offset(size.width * 0.65, size.height * 0.55), 4);
    _drawContourSet(canvas, size, paint, Offset(size.width * 0.50, size.height * 0.08), 2);

    // Sparkle dots (small star-like glints)
    final sparkPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawSparkle(canvas, Offset(size.width * 0.15, size.height * 0.42), 7, sparkPaint);
    _drawSparkle(canvas, Offset(size.width * 0.82, size.height * 0.35), 6, sparkPaint);
    _drawSparkle(canvas, Offset(size.width * 0.60, size.height * 0.15), 5, sparkPaint);
  }

  void _drawContourSet(Canvas canvas, Size size, Paint paint, Offset center, int rings) {
    for (int i = 1; i <= rings; i++) {
      final scale = i * 45.0;
      final path = Path();

      // Create organic irregular ellipse using cubic bezier curves
      final rx = scale * 1.0;
      final ry = scale * 0.65;
      final variance = scale * 0.25;
      final rnd = math.Random(i * 7 + center.dx.toInt());

      final v1 = (rnd.nextDouble() - 0.5) * variance;
      final v2 = (rnd.nextDouble() - 0.5) * variance;
      final v3 = (rnd.nextDouble() - 0.5) * variance;
      final v4 = (rnd.nextDouble() - 0.5) * variance;

      path.moveTo(center.dx + rx + v1, center.dy + v2);
      path.cubicTo(
        center.dx + rx + v1, center.dy - ry * 0.5 + v3,
        center.dx + rx * 0.5 + v4, center.dy - ry + v1,
        center.dx + v2, center.dy - ry + v3,
      );
      path.cubicTo(
        center.dx - rx * 0.5 + v4, center.dy - ry + v2,
        center.dx - rx + v3, center.dy - ry * 0.5 + v1,
        center.dx - rx + v4, center.dy + v2,
      );
      path.cubicTo(
        center.dx - rx + v4, center.dy + ry * 0.5 + v3,
        center.dx - rx * 0.5 + v1, center.dy + ry + v4,
        center.dx + v3, center.dy + ry + v1,
      );
      path.cubicTo(
        center.dx + rx * 0.5 + v2, center.dy + ry + v4,
        center.dx + rx + v1, center.dy + ry * 0.5 + v3,
        center.dx + rx + v1, center.dy + v2,
      );

      canvas.drawPath(path, paint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2);
      final x1 = center.dx + math.cos(angle) * size;
      final y1 = center.dy + math.sin(angle) * size;
      canvas.drawLine(center, Offset(x1, y1), paint);
    }
    // Diagonal shorter lines
    final smallSize = size * 0.5;
    final diagPaint = Paint()
      ..color = paint.color.withOpacity(0.3)
      ..strokeWidth = paint.strokeWidth * 0.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) + math.pi / 4;
      final x1 = center.dx + math.cos(angle) * smallSize;
      final y1 = center.dy + math.sin(angle) * smallSize;
      canvas.drawLine(center, Offset(x1, y1), diagPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TopographyPainter oldDelegate) => false;
}
