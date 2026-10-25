import 'package:flutter/material.dart';

class BottomOrderBar extends StatelessWidget {
  final int totalQuantity;
  final double totalAmount;
  final String selectedAddress;
  final VoidCallback onViewCartPressed;

  const BottomOrderBar({
    super.key,
    required this.totalQuantity,
    required this.totalAmount,
    required this.selectedAddress,
    required this.onViewCartPressed,
  });

  static const double _freeDeliveryThreshold = 200.0;

  @override
  Widget build(BuildContext context) {
    if (totalQuantity == 0) return const SizedBox.shrink();

    final double remainingForFree =
        (_freeDeliveryThreshold - totalAmount).clamp(0.0, _freeDeliveryThreshold);
    final bool isFreeDeliveryUnlocked = remainingForFree <= 0;
    final double progress =
        (totalAmount / _freeDeliveryThreshold).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Swiggy Instamart / Blinkit Style Free Delivery Unlock Strip
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isFreeDeliveryUnlocked
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isFreeDeliveryUnlocked
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isFreeDeliveryUnlocked
                            ? Icons.celebration_rounded
                            : Icons.local_shipping_rounded,
                        size: 14,
                        color: isFreeDeliveryUnlocked
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isFreeDeliveryUnlocked
                              ? 'Yay! You unlocked FREE Delivery on this order!'
                              : 'Add ₹${remainingForFree.ceil()} more to unlock FREE Delivery!',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isFreeDeliveryUnlocked
                                ? const Color(0xFF15803D)
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isFreeDeliveryUnlocked) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFFDE68A),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Main View Cart Bar
            InkWell(
              onTap: onViewCartPressed,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF00875A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalQuantity ITEM${totalQuantity > 1 ? 'S' : ''} • ₹${totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Delivering to: $selectedAddress',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x26FFFFFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}