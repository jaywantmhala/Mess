// lib/services/order_notification_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/order.dart';
import 'order_service.dart';
import '../screens/order_status_screen.dart';

// ─── Data Model ────────────────────────────────────────────────────────────

class OrderStatusNotificationData {
  final int orderId;
  final String status;
  final String hotelName;
  final double grandTotal;
  final double walletDeducted;
  final int itemCount;
  final DateTime createdAt;

  OrderStatusNotificationData({
    required this.orderId,
    required this.status,
    required this.hotelName,
    required this.grandTotal,
    required this.walletDeducted,
    required this.itemCount,
    required this.createdAt,
  });

  String get title {
    switch (status) {
      case 'created_order':
        return 'Order Placed! 🎉';
      case 'accepted':
        return 'Order Accepted! ✅';
      case 'preparing':
        return 'Chef is Cooking! 👨‍🍳';
      case 'ready':
        return 'Out for Delivery! 🛵';
      case 'completed':
        return 'Delivered! 🎊';
      default:
        return 'Order Updated!';
    }
  }

  String get subtitle {
    switch (status) {
      case 'created_order':
        return 'Your order from $hotelName has been received.';
      case 'accepted':
        return '$hotelName confirmed your order.';
      case 'preparing':
        return 'Your fresh meal is being prepared!';
      case 'ready':
        return 'Your tiffin is on its way to you!';
      case 'completed':
        return 'Enjoy your meal! 😋';
      default:
        return 'Status updated for order #$orderId.';
    }
  }

  // 0-based step index (0..4)
  int get stepIndex {
    switch (status) {
      case 'created_order':
        return 0;
      case 'accepted':
        return 1;
      case 'preparing':
        return 2;
      case 'ready':
        return 3;
      case 'completed':
        return 4;
      default:
        return 0;
    }
  }

  static const List<StepInfo> steps = [
    StepInfo(label: 'Placed', icon: Icons.receipt_long_rounded),
    StepInfo(label: 'Accepted', icon: Icons.check_circle_rounded),
    StepInfo(label: 'Cooking', icon: Icons.outdoor_grill_rounded),
    StepInfo(label: 'On Way', icon: Icons.electric_moped_rounded),
    StepInfo(label: 'Delivered', icon: Icons.celebration_rounded),
  ];
}

class StepInfo {
  final String label;
  final IconData icon;
  const StepInfo({required this.label, required this.icon});
}

// ─── Singleton Manager ──────────────────────────────────────────────────────

class OrderNotificationManager {
  OrderNotificationManager._();
  static final OrderNotificationManager instance = OrderNotificationManager._();

  OverlayEntry? _overlayEntry;
  final ValueNotifier<OrderStatusNotificationData?> currentNotification =
      ValueNotifier<OrderStatusNotificationData?>(null);

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _autoDismissTimer;

  Future<void> playStatusSound() async {
    try {
      await _audioPlayer.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.notification,
          audioFocus: AndroidAudioFocus.gainTransient,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      debugPrint('Error playing status update sound: $e');
    }
  }

  Future<void> showOrUpdateNotification(
      BuildContext context, int orderId, String status) async {
    try {
      final details = await OrderService.instance.getDetails(orderId: orderId);
      final data = OrderStatusNotificationData(
        orderId: orderId,
        status: status,
        hotelName: details.hotel.hotelName,
        grandTotal: details.grandTotal,
        walletDeducted: details.walletDeducted,
        itemCount: details.items.fold(0, (sum, item) => sum + item.quantity),
        createdAt: DateTime.tryParse(details.createdAt) ?? DateTime.now(),
      );

      // If user is already viewing this order's status screen, just play sound.
      if (OrderStatusScreen.activeTrackingOrderId == orderId) {
        await playStatusSound();
        return;
      }

      await playStatusSound();
      _resetAutoDismissTimer();

      if (_overlayEntry != null) {
        // ✅ Update existing notification in place — no new notification spawned
        currentNotification.value = data;
      } else {
        currentNotification.value = data;
        _overlayEntry = OverlayEntry(
          builder: (ctx) => ValueListenableBuilder<OrderStatusNotificationData?>(
            valueListenable: currentNotification,
            builder: (ctx, notifData, _) {
              if (notifData == null) return const SizedBox.shrink();
              return Positioned(
                top: MediaQuery.of(ctx).padding.top + 10,
                left: 12,
                right: 12,
                child: Material(
                  color: Colors.transparent,
                  child: HungrilyNotificationCard(
                    data: notifData,
                    onDismiss: dismissNotification,
                    onViewOrder: () {
                      dismissNotification();
                      final orderItem = OrderHistoryItem(
                        orderId: notifData.orderId,
                        hotelName: notifData.hotelName,
                        status: notifData.status,
                        grandTotal: notifData.grandTotal,
                        walletDeducted: notifData.walletDeducted,
                        itemCount: notifData.itemCount,
                        createdAt: notifData.createdAt,
                      );
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderStatusScreen(initialOrder: orderItem),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );

        if (context.mounted) {
          Overlay.of(context).insert(_overlayEntry!);
        }
      }
    } catch (e) {
      debugPrint('Error showing order notification: $e');
    }
  }

  void _resetAutoDismissTimer() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 18), dismissNotification);
  }

  void dismissNotification() {
    _autoDismissTimer?.cancel();
    currentNotification.value = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

// ─── Notification Card Widget ───────────────────────────────────────────────

class HungrilyNotificationCard extends StatefulWidget {
  final OrderStatusNotificationData data;
  final VoidCallback onDismiss;
  final VoidCallback onViewOrder;

  const HungrilyNotificationCard({
    super.key,
    required this.data,
    required this.onDismiss,
    required this.onViewOrder,
  });

  @override
  State<HungrilyNotificationCard> createState() =>
      _HungrilyNotificationCardState();
}

class _HungrilyNotificationCardState extends State<HungrilyNotificationCard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: const Interval(0.0, 0.6)),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant HungrilyNotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.stepIndex != widget.data.stepIndex) {
      // Animate the card briefly on update
      _slideController.forward(from: 0.6);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    const surfaceColor = Color(0xFF16213E);
    const accentOrange = Color(0xFFFF6B35); // Hungrily brand orange
    const accentGreen = Color(0xFF2D6A4F); // Hungrily brand green

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1E2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentOrange.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentOrange.withOpacity(0.25),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top shimmer accent line
            _ShimmerAccentLine(animation: _shimmerAnim, color: accentOrange),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header: Logo + App name + Dismiss
                  _buildHeader(accentOrange, surfaceColor),
                  const SizedBox(height: 14),

                  // ── Status title + subtitle
                  _buildStatusTitle(accentOrange, accentGreen),
                  const SizedBox(height: 16),

                  // ── Order stepper
                  _buildStepper(accentOrange, accentGreen),
                  const SizedBox(height: 16),

                  // ── Order summary chip row
                  _buildOrderSummaryRow(accentOrange),
                  const SizedBox(height: 16),

                  // ── Action button
                  _buildTrackButton(accentOrange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color accentOrange, Color surfaceColor) {
    return Row(
      children: [
        // Hungrily logo in a rounded container
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: accentOrange.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/hungrily_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hungrily',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Order #${widget.data.orderId}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Live badge
        ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accentOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentOrange.withOpacity(0.6), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentOrange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: accentOrange, blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: accentOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Dismiss X button
        GestureDetector(
          onTap: widget.onDismiss,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded, color: Colors.white54, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTitle(Color accentOrange, Color accentGreen) {
    final isCompleted = widget.data.status == 'completed';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                (isCompleted ? accentGreen : accentOrange).withOpacity(0.25),
                (isCompleted ? accentGreen : accentOrange).withOpacity(0.05),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: (isCompleted ? const Color(0xFF52B788) : accentOrange)
                  .withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Icon(
            OrderStatusNotificationData
                .steps[widget.data.stepIndex.clamp(0, 4)].icon,
            color: isCompleted ? const Color(0xFF52B788) : accentOrange,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.data.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.data.subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepper(Color accentOrange, Color accentGreen) {
    final steps = OrderStatusNotificationData.steps;
    final currentStep = widget.data.stepIndex;
    final isCompleted = widget.data.status == 'completed';
    final activeColor = isCompleted ? const Color(0xFF52B788) : accentOrange;

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final lineIndex = i ~/ 2;
          final isDone = lineIndex < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                gradient: isDone
                    ? LinearGradient(colors: [activeColor, activeColor])
                    : null,
                color: isDone ? null : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isDone = stepIndex < currentStep;
        final isActive = stepIndex == currentStep;
        final step = steps[stepIndex];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              width: isActive ? 36 : 28,
              height: isActive ? 36 : 28,
              decoration: BoxDecoration(
                color: isDone
                    ? activeColor.withOpacity(0.85)
                    : isActive
                        ? activeColor
                        : Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone || isActive
                      ? activeColor
                      : Colors.white.withOpacity(0.18),
                  width: isActive ? 2.5 : 1.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: activeColor.withOpacity(0.55),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isDone
                    ? Icon(Icons.check_rounded,
                        color: Colors.white, size: isActive ? 18 : 14)
                    : Icon(step.icon,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        size: isActive ? 18 : 13),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              step.label,
              style: TextStyle(
                color: isDone || isActive
                    ? Colors.white.withOpacity(0.9)
                    : Colors.white.withOpacity(0.3),
                fontSize: 9.5,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildOrderSummaryRow(Color accentOrange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryChip(
            icon: Icons.restaurant_rounded,
            label: widget.data.hotelName,
            color: accentOrange,
            maxWidth: 100,
          ),
          _divider(),
          _SummaryChip(
            icon: Icons.shopping_bag_rounded,
            label: '${widget.data.itemCount} item${widget.data.itemCount == 1 ? '' : 's'}',
            color: const Color(0xFF64B5F6),
          ),
          _divider(),
          _SummaryChip(
            icon: Icons.currency_rupee_rounded,
            label: widget.data.grandTotal.toStringAsFixed(0),
            color: const Color(0xFF81C784),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withOpacity(0.1),
      );

  Widget _buildTrackButton(Color accentOrange) {
    return GestureDetector(
      onTap: widget.onViewOrder,
      child: AnimatedBuilder(
        animation: _shimmerAnim,
        builder: (context, child) {
          return Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentOrange,
                  const Color(0xFFFF8C42),
                  accentOrange,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: accentOrange.withOpacity(0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          );
        },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Track My Order',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer accent top line ────────────────────────────────────────────────

class _ShimmerAccentLine extends StatelessWidget {
  final Animation<double> animation;
  final Color color;

  const _ShimmerAccentLine({required this.animation, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Container(
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (animation.value - 0.4).clamp(0.0, 1.0),
                animation.value.clamp(0.0, 1.0),
                (animation.value + 0.4).clamp(0.0, 1.0),
              ],
              colors: [
                color.withOpacity(0.2),
                color,
                color.withOpacity(0.2),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Summary Chip ───────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double? maxWidth;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(height: 3),
        SizedBox(
          width: maxWidth,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
