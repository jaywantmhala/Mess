import 'package:flutter/material.dart';

class LedgerItemModel {
  final String title;
  final String date;
  final String changeText;
  final String amountText;
  final bool isCredit; // positive balance change vs negative
  final IconData icon;

  LedgerItemModel({
    required this.title,
    required this.date,
    required this.changeText,
    required this.amountText,
    required this.isCredit,
    required this.icon,
  });
}

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  final List<LedgerItemModel> _transactions = [
    LedgerItemModel(
      title: 'Token Subscription Renewed',
      date: 'July 01, 2026',
      changeText: '+30 Breakfast, +30 Lunch',
      amountText: '₹2,400',
      isCredit: true,
      icon: Icons.add_card_rounded,
    ),
    LedgerItemModel(
      title: 'Dined at Zenith Gold Canteen',
      date: 'Today, 1:15 PM',
      changeText: '-1 Lunch Token',
      amountText: 'Deducted',
      isCredit: false,
      icon: Icons.restaurant_rounded,
    ),
    LedgerItemModel(
      title: 'Meal Refund: Dinner Cancelled',
      date: 'Yesterday, 6:00 PM',
      changeText: '+1 Dinner Token Refunded',
      amountText: '₹80',
      isCredit: true,
      icon: Icons.history_rounded,
    ),
    LedgerItemModel(
      title: 'Dined at Veg Oasis Mess',
      date: 'July 02, 8:30 AM',
      changeText: '-1 Breakfast Token',
      amountText: 'Deducted',
      isCredit: false,
      icon: Icons.flatware_rounded,
    ),
    LedgerItemModel(
      title: 'Guest Pass Purchased',
      date: 'June 29, 2026',
      changeText: '-1 Lunch Token',
      amountText: '₹120',
      isCredit: false,
      icon: Icons.qr_code_2_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              const Text(
                'Dining Ledger & Stats',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Track your meal consumption and active smart tokens.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 25),

              // 2. Token Counters Row (Circular Progress Indicators)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTokenProgressCard(
                    title: 'Breakfast',
                    remaining: 18,
                    total: 30,
                    color: const Color(0xFF00C6FF),
                  ),
                  _buildTokenProgressCard(
                    title: 'Lunch',
                    remaining: 24,
                    total: 30,
                    color: const Color(0xFF9000FF),
                  ),
                  _buildTokenProgressCard(
                    title: 'Dinner',
                    remaining: 15,
                    total: 30,
                    color: const Color(0xFFFF3366),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 3. Programmatic Custom Dining Chart
              const Text(
                'Weekly Dining Attendance (%)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 160,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF080F1E).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
                child: CustomPaint(
                  painter: DiningChartPainter(),
                ),
              ),
              const SizedBox(height: 28),

              // 4. Ledger Transaction List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF00C6FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                padding: const EdgeInsets.only(bottom: 90),
                itemBuilder: (context, index) {
                  final tx = _transactions[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF080F1E).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Icon Circle
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tx.isCredit
                                ? const Color(0xFF00FF87).withOpacity(0.1)
                                : const Color(0xFF00C6FF).withOpacity(0.1),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            tx.icon,
                            color: tx.isCredit ? const Color(0xFF00FF87) : const Color(0xFF00C6FF),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        
                        // Transaction text details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tx.changeText,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tx.date,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Transaction cost/refund badge
                        Text(
                          tx.isCredit ? '+${tx.amountText}' : tx.amountText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: tx.isCredit ? const Color(0xFF00FF87) : Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenProgressCard({
    required String title,
    required int remaining,
    required int total,
    required Color color,
  }) {
    final progressVal = remaining / total;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF080F1E).withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.04),
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 14),
            // Custom circular progress with centered text
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 55,
                  height: 55,
                  child: CircularProgressIndicator(
                    value: progressVal,
                    strokeWidth: 5.5,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: color,
                  ),
                ),
                Text(
                  '$remaining',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'of $total tokens',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to draw a modern glowing weekly attendance line chart
class DiningChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines
    final double gridRows = 4;
    for (int i = 0; i <= gridRows; i++) {
      final double y = size.height * (i / gridRows);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    // Weekly attendance percentages: Mon: 80%, Tue: 90%, Wed: 70%, Thu: 100%, Fri: 85%, Sat: 50%, Sun: 95%
    final List<double> values = [0.80, 0.90, 0.70, 1.0, 0.85, 0.40, 0.95];
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final double paddingX = 15.0;
    final double usableWidth = size.width - (paddingX * 2);
    final double stepX = usableWidth / (values.length - 1);

    final List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final double x = paddingX + (i * stepX);
      // In Flutter canvas, (0,0) is top-left, so we invert Y axis
      final double y = size.height * (1.0 - values[i]) * 0.8 + (size.height * 0.1);
      points.add(Offset(x, y));
    }

    // 1. Draw glowing gradient area under the curve
    final Path areaPath = Path()
      ..moveTo(points.first.dx, size.height);
    for (var pt in points) {
      areaPath.lineTo(pt.dx, pt.dy);
    }
    areaPath.lineTo(points.last.dx, size.height);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF00C6FF).withOpacity(0.20),
          const Color(0xFF00C6FF).withOpacity(0.00),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    // 2. Draw the connection path line
    final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      // Use cubic curves for smooth flowing path (optional, let's use standard line segments for sharp look)
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF9000FF),
          Color(0xFF00C6FF),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));
    canvas.drawPath(linePath, linePaint);

    // 3. Draw glow filter around points
    final pointShadowPaint = Paint()
      ..color = const Color(0xFF00C6FF).withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPointPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF00C6FF);

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      // Draw outer point glows
      canvas.drawCircle(pt, 5.0, pointShadowPaint);
      canvas.drawCircle(pt, 4.0, borderPointPaint);
      canvas.drawCircle(pt, 2.0, pointPaint);

      // Draw day label text below X axis
      textPainter.text = TextSpan(
        text: days[i],
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.4),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pt.dx - (textPainter.width / 2), size.height - textPainter.height + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DiningChartPainter oldDelegate) {
    return false;
  }
}
