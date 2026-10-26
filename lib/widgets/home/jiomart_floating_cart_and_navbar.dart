import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';

class JioMartFloatingCartAndBottomArea extends StatefulWidget {
  final int currentTabIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onViewCartPressed;

  const JioMartFloatingCartAndBottomArea({
    super.key,
    required this.currentTabIndex,
    required this.onTabSelected,
    required this.onViewCartPressed,
  });

  @override
  State<JioMartFloatingCartAndBottomArea> createState() =>
      _JioMartFloatingCartAndBottomAreaState();
}

class _JioMartFloatingCartAndBottomAreaState
    extends State<JioMartFloatingCartAndBottomArea> {
  bool _dismissedFreeDeliveryBanner = false;
  static const double _freeDeliveryThreshold = 199.0;
  static final Map<String, Uint8List> _thumbCache = {};

  Widget _buildMiniThumb(String imageStr) {
    final String trimmed = imageStr.trim();
    if (trimmed.isEmpty) {
      return const Icon(
        Icons.shopping_bag_rounded,
        size: 20,
        color: Color(0xFF0078AD),
      );
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      Uint8List? bytes = _thumbCache[trimmed];
      if (bytes == null) {
        try {
          final String clean =
              trimmed.contains(',') ? trimmed.split(',').last : trimmed;
          bytes = base64Decode(clean.trim());
          _thumbCache[trimmed] = bytes;
        } catch (_) {
          return const Icon(
            Icons.shopping_bag_rounded,
            size: 20,
            color: Color(0xFF0078AD),
          );
        }
      }
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.shopping_bag_rounded,
          size: 20,
          color: Color(0xFF0078AD),
        ),
      );
    }

    return Image.network(
      trimmed,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.shopping_bag_rounded,
        size: 20,
        color: Color(0xFF0078AD),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final int totalQty = cart.totalQuantity;
        final double totalAmount = cart.totalAmount;
        final double remainingForFree =
            (_freeDeliveryThreshold - totalAmount).clamp(0.0, _freeDeliveryThreshold);
        final String firstItemImg =
            cart.items.values.isNotEmpty ? cart.items.values.first.imageUrl : '';

        return Container(
          color: Colors.transparent,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (totalQty > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: widget.onViewCartPressed,
                      child: Container(
                        height: 54,
                        width: 230,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0078AD),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _buildMiniThumb(firstItemImg),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'View cart',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '$totalQty ${totalQty == 1 ? 'item' : 'items'}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF0078AD),
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!_dismissedFreeDeliveryBanner && widget.currentTabIndex == 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF8FF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.two_wheeler_rounded,
                            color: Color(0xFFDC2626),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: remainingForFree > 0
                              ? RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF0F172A),
                                      height: 1.3,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Shop for '),
                                      TextSpan(
                                        text:
                                            '₹${totalAmount > 0 ? remainingForFree.ceil() : 199}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const TextSpan(text: ' or more to '),
                                      const TextSpan(
                                        text: 'unlock free delivery',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' on your Quick grocery order',
                                      ),
                                    ],
                                  ),
                                )
                              : const Text(
                                  '🎉 Free delivery unlocked on your Quick grocery order!',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          onPressed: () {
                            setState(() => _dismissedFreeDeliveryBanner = true);
                          },
                        ),
                      ],
                    ),
                  ),
                Container(
                  height: 66,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        index: 0,
                        label: 'Home',
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                      ),
                      _buildNavItem(
                        index: 1,
                        label: 'Categories',
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard_rounded,
                      ),
                      _buildNavItem(
                        index: 2,
                        label: 'Buy Again',
                        icon: Icons.replay_circle_filled_outlined,
                        activeIcon: Icons.replay_rounded,
                      ),
                      _buildNavItem(
                        index: 3,
                        label: 'Offers',
                        icon: Icons.local_offer_outlined,
                        activeIcon: Icons.local_offer_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final bool isSelected = widget.currentTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 24,
                color: isSelected
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF475569),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
