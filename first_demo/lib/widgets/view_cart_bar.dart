// lib/widgets/view_cart_bar.dart
import 'package:flutter/material.dart';

/// Sticky bottom "View Cart" bar, Swiggy/Zomato style.
/// Shows [itemCount] items and [totalPrice], navigates on tap.
class ViewCartBar extends StatelessWidget {
  final int itemCount;
  final double totalPrice;
  final VoidCallback onTap;

  const ViewCartBar({
    super.key,
    required this.itemCount,
    required this.totalPrice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1DA462), Color(0xFF128A4E)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1DA462).withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left: item count bubble
              Container(
                margin: const EdgeInsets.all(8),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$itemCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),

              // Center: label
              Expanded(
                child: Text(
                  itemCount == 1 ? '1 Item added' : '$itemCount Items added',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Right: View Cart + price
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Text(
                      'View Cart  ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
