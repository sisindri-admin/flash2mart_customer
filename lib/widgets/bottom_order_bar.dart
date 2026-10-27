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
          color: Color(0xFF0072A0),
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
              color: Color(0xFF0072A0),
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
            color: Color(0xFF0072A0),
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
          color: Color(0xFF0072A0),
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
        final double neededForFree =
            (_freeDeliveryThreshold - currentTotal).clamp(0.0, _freeDeliveryThreshold);
        final bool isFreeUnlocked = neededForFree <= 0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. FLOATING "Shop for ₹199 or more to unlock FREE delivery" PILL WITH GREEN BIKE & "X" CLOSE
            if (!_isFreeDeliveryBannerDismissed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 16, right: 16),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xF5FFFFFF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF86EFAC),
                        width: 1.1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.two_wheeler_rounded,
                            size: 15,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isFreeUnlocked
                                ? 'FREE Delivery unlocked on your order!'
                                : 'Shop for ₹199 or more to unlock FREE delivery (Add ₹${neededForFree.ceil()})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isFreeDeliveryBannerDismissed = true;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 2. COMPACT FLOATING "View cart" PILL BADGE (Smaller size hovering over screen)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Center(
                child: GestureDetector(
                  onTap: widget.onViewCartPressed,
                  child: Container(
                    height: 46,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0072A0),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF0284C7),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
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

                        // Compact "View cart" + "X items"
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'View cart',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              '${widget.totalQuantity} ${widget.totalQuantity == 1 ? 'item' : 'items'}',
                              style: const TextStyle(
                                color: Color(0xFFE0F2FE),
                                fontWeight: FontWeight.w600,
                                fontSize: 10.5,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Compact White Circle with '>' Chevron
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
                              color: Color(0xFF0072A0),
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