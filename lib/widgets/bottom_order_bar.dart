import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';

class BottomOrderBar extends StatefulWidget {
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
  State<BottomOrderBar> createState() => _BottomOrderBarState();
}

class _BottomOrderBarState extends State<BottomOrderBar> {
  static final Map<String, MemoryImage> _thumbMemoryCache = {};
  static const double _freeDeliveryThreshold = 199.0;

  bool _isFreeDeliveryBannerDismissed = false;

  Widget _buildProductThumb(String imageStr) {
    final String trimmed = imageStr.trim();
    if (trimmed.isEmpty) {
      return Container(
        color: const Color(0xFFF1F5F9),
        child: const Icon(
          Icons.shopping_bag_rounded,
          size: 15,
          color: Color(0xFF00875A),
        ),
      );
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      MemoryImage? memImg = _thumbMemoryCache[trimmed];
      if (memImg == null) {
        try {
          final String clean =
              trimmed.contains(',') ? trimmed.split(',').last : trimmed;
          final Uint8List bytes = base64Decode(clean.trim());
          memImg = MemoryImage(bytes);
          _thumbMemoryCache[trimmed] = memImg;
        } catch (_) {
          return Container(
            color: const Color(0xFFF1F5F9),
            child: const Icon(
              Icons.shopping_bag_rounded,
              size: 15,
              color: Color(0xFF00875A),
            ),
          );
        }
      }
      return Image(
        image: memImg,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Icon(
            Icons.shopping_bag_rounded,
            size: 15,
            color: Color(0xFF00875A),
          ),
        ),
      );
    }

    return Image.network(
      trimmed,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFF1F5F9),
        child: const Icon(
          Icons.shopping_bag_rounded,
          size: 15,
          color: Color(0xFF00875A),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalQuantity <= 0) return const SizedBox.shrink();

    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final List<CartItem> allCartItems = cart.items.values.toList();
        if (allCartItems.isEmpty) return const SizedBox.shrink();

        // Keep at most 3 latest added items
        final List<CartItem> visibleItems = allCartItems.length > 3
            ? allCartItems.sublist(allCartItems.length - 3)
            : allCartItems;

        final int count = visibleItems.length;
        // Compact 32px circles shifted by 16px each
        final double stackWidth = 32.0 + ((count - 1) * 16.0);

        final double currentTotal = cart.totalAmount;
        final double neededForFree = (_freeDeliveryThreshold - currentTotal)
            .clamp(0.0, _freeDeliveryThreshold);
        final bool isFreeUnlocked = neededForFree <= 0;
        final double progress =
            (currentTotal / _freeDeliveryThreshold).clamp(0.0, 1.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. TOP PROGRESS BANNER: Shown ONLY when total < ₹199 with filling line & "X"
            //    Once ₹199 is reached, it clears automatically because the cart badge itself shows "FREE Delivery"
            if (!isFreeUnlocked && !_isFreeDeliveryBannerDismissed)
              Padding(
                padding: const EdgeInsets.only(bottom: 5, left: 14, right: 14),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 350),
                    padding: const EdgeInsets.fromLTRB(10, 6, 8, 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFAFFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF86EFAC),
                        width: 1.1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDCFCE7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.two_wheeler_rounded,
                                size: 14,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1E293B),
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Shop for ₹199 for ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const TextSpan(
                                      text: 'FREE Delivery ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                    TextSpan(
                                      text: '(Add ₹${neededForFree.ceil()})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '₹${currentTotal.toInt()}/199',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isFreeDeliveryBannerDismissed = true;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Sleek filling progress line
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 2. FLOATING "View cart" BADGE:
            //    - Styled with Flash2Mart Emerald Green gradient
            //    - When ₹199 is reached, shows a small "FREE Delivery" label with green bike icon at the bottom of the badge!
            //    - When total < 199, this "FREE Delivery" label is completely hidden!
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Center(
                child: GestureDetector(
                  onTap: widget.onViewCartPressed,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: isFreeUnlocked ? 52 : 46,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00875A), // Flash2Mart Brand Emerald Green
                          Color(0xFF047857),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3300875A),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Overlapping circular product thumbnails (up to 3 latest items)
                        SizedBox(
                          width: stackWidth,
                          height: 32,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: List.generate(count, (idx) {
                              final item = visibleItems[idx];
                              return Positioned(
                                left: idx * 16.0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.6,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x22000000),
                                        blurRadius: 3,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ClipOval(
                                    child: _buildProductThumb(item.imageUrl),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Title, item count, and when >= 199: FREE Delivery at bottom of badge
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'View cart',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              '${widget.totalQuantity} ${widget.totalQuantity == 1 ? 'item' : 'items'} • ₹${currentTotal.toInt()}',
                              style: const TextStyle(
                                color: Color(0xFFDCFCE7),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                height: 1.1,
                              ),
                            ),
                            // Requirement 1: Free Delivery with small icon in small letters inside cart badge
                            // Only appears when total >= 199; disappears completely when below 199!
                            if (isFreeUnlocked) ...[
                              const SizedBox(height: 1),
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.two_wheeler_rounded,
                                    size: 11,
                                    color: Color(0xFF86EFAC),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'FREE Delivery',
                                    style: TextStyle(
                                      color: Color(0xFFDCFCE7),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9.5,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Compact White Circle with Green '>' Chevron
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF00875A),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}