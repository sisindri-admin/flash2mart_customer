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

  @override
  Widget build(BuildContext context) {
    if (totalQuantity == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF00875A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalQuantity ITEM${totalQuantity > 1 ? 'S' : ''} • ₹${totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    child: Text(
                      'Delivering to: $selectedAddress',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onViewCartPressed,
                child: const Row(
                  children: [
                    Text('View Cart', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
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