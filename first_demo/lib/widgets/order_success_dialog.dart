import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// Professional Order Placement Success Modal Dialog
/// 100% matching screenshot design with 3-second auto-redirect.
class OrderSuccessDialog extends StatefulWidget {
  final int orderId;
  final String? addressLabel;
  final String? addressDetails;
  final VoidCallback onRedirect;

  const OrderSuccessDialog({
    super.key,
    required this.orderId,
    this.addressLabel,
    this.addressDetails,
    required this.onRedirect,
  });

  static Future<void> show({
    required BuildContext context,
    required int orderId,
    String? addressLabel,
    String? addressDetails,
    required VoidCallback onRedirect,
  }) {
    final audioPlayer = AudioPlayer();
    audioPlayer.setVolume(1.0).then((_) {
      audioPlayer.play(AssetSource('sounds/success.mp3')).catchError((e) {
        debugPrint('Failed to play success sound: $e');
      });
    });

    bool hasRedirected = false;
    Timer? timer;

    void triggerRedirect(BuildContext dialogCtx) {
      if (hasRedirected) return;
      hasRedirected = true;
      timer?.cancel();
      audioPlayer.dispose();
      Navigator.of(dialogCtx, rootNavigator: true).pop();
      onRedirect();
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        timer = Timer(const Duration(seconds: 3), () {
          triggerRedirect(dialogCtx);
        });
        return OrderSuccessDialog(
          orderId: orderId,
          addressLabel: addressLabel,
          addressDetails: addressDetails,
          onRedirect: () {
            triggerRedirect(dialogCtx);
          },
        );
      },
    );
  }

  @override
  State<OrderSuccessDialog> createState() => _OrderSuccessDialogState();
}

class _OrderSuccessDialogState extends State<OrderSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final orderTimeFormatted = _formatTime(now);
    final estDeliveryTimeFormatted = _formatTime(now.add(const Duration(minutes: 45)));

    final displayLabel = (widget.addressLabel != null && widget.addressLabel!.isNotEmpty)
        ? widget.addressLabel!
        : 'Home (B-102, 2nd Floor)';
    final displayAddress = (widget.addressDetails != null && widget.addressDetails!.isNotEmpty)
        ? widget.addressDetails!
        : '15, Laxmi Nagar, Near Sai Mandir, Wakad, Pune - 411057';

    final orderIdCode = '#ORD${widget.orderId > 0 ? widget.orderId : "876GHT2"}';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),

                    // Decorative Confetti & Success Checkmark
                    SizedBox(
                      height: 100,
                      width: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Scattered Confetti Shapes
                          ..._buildConfettiParticles(),

                          // Outer Halo Circle
                          Container(
                            width: 76,
                            height: 76,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // Inner Dark Green Circle with White Checkmark
                          Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x3316A34A),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title: Congratulations!
                    const Text(
                      'Congratulations!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      'Your order has been placed successfully',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Delivering to Location Container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Green Pin Badge
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8F5E9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFF16A34A),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Delivering to',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      displayLabel,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      displayAddress,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey.shade600,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(color: Colors.grey.shade200, height: 1, thickness: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.two_wheeler_rounded,
                                color: Color(0xFF16A34A),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade700,
                                  ),
                                  children: [
                                    const TextSpan(text: 'We will deliver your order around '),
                                    TextSpan(
                                      text: estDeliveryTimeFormatted,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF16A34A),
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
                    const SizedBox(height: 14),

                    // Order ID Container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // Green Receipt Icon Badge
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Color(0xFF16A34A),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ORDER ID',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  orderIdCode,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF16A34A),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                orderTimeFormatted,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Footer message with Green Heart
                    Column(
                      children: [
                        Text(
                          'Redirecting to live order tracking in 3 seconds...',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFF16A34A),
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),

                // Top Right Close Button (X)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: widget.onRedirect,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper to render festive confetti shapes matching the reference image
  List<Widget> _buildConfettiParticles() {
    return const [
      // Top Left Orange Ribbon
      Positioned(
        top: 10,
        left: 20,
        child: Icon(Icons.gesture, color: Color(0xFFEAB308), size: 14),
      ),
      // Left Blue Dot
      Positioned(
        top: 34,
        left: 10,
        child: Icon(Icons.circle, color: Color(0xFF3B82F6), size: 6),
      ),
      // Left Yellow Square
      Positioned(
        top: 48,
        left: 36,
        child: Icon(Icons.crop_square_rounded, color: Color(0xFFF59E0B), size: 8),
      ),
      // Left Purple Ribbon
      Positioned(
        top: 68,
        left: 54,
        child: Icon(Icons.commit, color: Color(0xFF8B5CF6), size: 10),
      ),
      // Left Green Ribbon
      Positioned(
        top: 85,
        left: 16,
        child: Icon(Icons.polyline_rounded, color: Color(0xFF22C55E), size: 12),
      ),
      // Top Right Green Square
      Positioned(
        top: 10,
        right: 48,
        child: Icon(Icons.crop_square_rounded, color: Color(0xFF22C55E), size: 6),
      ),
      // Top Right Orange Ribbon
      Positioned(
        top: 26,
        right: 22,
        child: Icon(Icons.gesture, color: Color(0xFFF97316), size: 12),
      ),
      // Right Purple Bar
      Positioned(
        top: 42,
        right: 12,
        child: Icon(Icons.rectangle, color: Color(0xFFA855F7), size: 8),
      ),
      // Right Blue Ribbon
      Positioned(
        top: 60,
        right: 32,
        child: Icon(Icons.grain_rounded, color: Color(0xFF3B82F6), size: 10),
      ),
      // Right Red Square
      Positioned(
        top: 80,
        right: 20,
        child: Icon(Icons.crop_square_rounded, color: Color(0xFFEF4444), size: 8),
      ),
    ];
  }
}
