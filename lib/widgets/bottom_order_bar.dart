import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';

class BottomOrderBar extends StatelessWidget {
  final int totalQuantity;
  final double totalAmount;
  final String selectedAddress;
  final VoidCallback onViewCartPressed;

  static final Map<String, Uint8List> _thumbCache = {};

  const BottomOrderBar({
    super.key,
    required this.totalQuantity,
    required this.totalAmount,
    required this.selectedAddress,
    required this.onViewCartPressed,
  });

  Widget _buildProductThumb(String imageStr) {
    final String trimmed = imageStr.trim();
    if (trimmed.isEmpty) {
      return Container(
        color: const Color(0xFFF1F5F9),
        child: const Icon(
          Icons.shopping_bag_rounded,
          size: 20,
          color: Color(0xFF0072A0),
        ),
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
          return Container(
            color: const Color(0xFFF1F5F9),
            child: const Icon(
              Icons.shopping_bag_rounded,
              size: 20,
              color: Color(0xFF0072A0),
            ),
          );
        }
      }
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Icon(
            Icons.shopping_bag_rounded,
            size: 20,
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
          size: 20,
          color: Color(0xFF0072A0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (totalQuantity <= 0) return const SizedBox.shrink();

    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final List<CartItem> allCartItems = cart.items.values.toList();
        if (allCartItems.isEmpty) return const SizedBox.shrink();

        // Show at most 3 items; when more than 3 items are added, hide older ones and show the latest 3
        final List<CartItem> visibleItems = allCartItems.length > 3
            ? allCartItems.sublist(allCartItems.length - 3)
            : allCartItems;

        final int count = visibleItems.length;
        // Calculate width of overlapping circular thumbnails stack (each 46px wide, shifted by 24px)
        final double stackWidth = 46.0 + ((count - 1) * 24.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Center(
            child: GestureDetector(
              onTap: onViewCartPressed,
              child: Container(
                height: 62,
                constraints: const BoxConstraints(
                  minWidth: 235,
                  maxWidth: 310,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0072A0), // Exact Teal-Blue from Image 1
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: const Color(0xFF0284C7),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. OVERLAPPING CIRCULAR PRODUCT THUMBNAILS (1 to 3 latest items)
                    SizedBox(
                      width: stackWidth,
                      height: 46,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: List.generate(count, (idx) {
                          final item = visibleItems[idx];
                          return Positioned(
                            left: idx * 24.0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x26000000),
                                    blurRadius: 4,
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
                    const SizedBox(width: 12),

                    // 2. "View cart" + "X items"
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'View cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16.5,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$totalQuantity ${totalQuantity == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                            color: Color(0xFFE0F2FE),
                            fontWeight: FontWeight.w500,
                            fontSize: 13.5,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // 3. WHITE CIRCLE WITH BLUE '>' CHEVRON (Image 1)
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF0072A0),
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}