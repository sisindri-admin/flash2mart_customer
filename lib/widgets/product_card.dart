import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../screens/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final String id;
  final String name;
  final double price;
  final double marketPrice;
  final String unit;
  final String imageUrl;
  final int stock;
  final int quantityInCart;
  final String merchantId;
  final String category;
  final String description;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  static final Map<String, Uint8List> _sharedBase64Cache = {};

  const ProductCard({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    required this.marketPrice,
    required this.unit,
    required this.imageUrl,
    required this.stock,
    required this.quantityInCart,
    this.merchantId = '',
    this.category = 'General',
    this.description = '',
    required this.onAdd,
    required this.onRemove,
  });

  Widget _buildProductImage(String imageStr) {
    final String trimmed = imageStr.trim();
    if (trimmed.isEmpty) {
      return Container(
        color: const Color(0xFFF8FAFC),
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 42,
          color: Colors.green.shade200,
        ),
      );
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      Uint8List? bytes = _sharedBase64Cache[trimmed];
      if (bytes == null) {
        try {
          final String cleanBase64 =
              trimmed.contains(',') ? trimmed.split(',').last : trimmed;
          bytes = base64Decode(cleanBase64.trim());
          _sharedBase64Cache[trimmed] = bytes;
        } catch (_) {
          return Container(
            color: const Color(0xFFF8FAFC),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 42,
              color: Colors.green.shade200,
            ),
          );
        }
      }
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF8FAFC),
          child: Icon(
            Icons.shopping_bag_outlined,
            size: 42,
            color: Colors.green.shade200,
          ),
        ),
      );
    }

    return Image.network(
      trimmed,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFF8FAFC),
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 42,
          color: Colors.green.shade200,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = stock <= 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: id,
              productData: {
                'name': name,
                'price': price,
                'marketPrice': marketPrice,
                'unit': unit,
                'imageUrl': imageUrl,
                'stock': stock,
                'merchantId': merchantId,
                'category': category,
                'description': description,
              },
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. IMAGE + GRAY UNIT STRIP + OVERLAPPING ADD / "- 1 +" PILL BUTTON (Image 3)
          SizedBox(
            height: 138,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Rounded Image + Bottom Unit Bar Container
                Container(
                  width: double.infinity,
                  height: 132,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full-bleed Rounded Top Image
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14),
                              ),
                              child: Opacity(
                                opacity: isOutOfStock ? 0.45 : 1.0,
                                child: _buildProductImage(imageUrl),
                              ),
                            ),
                            // Mini Pagination Dots at Bottom-Left of Photo
                            Positioned(
                              bottom: 6,
                              left: 7,
                              child: Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Colors.black87,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Container(
                                    width: 4.5,
                                    height: 4.5,
                                    decoration: const BoxDecoration(
                                      color: Colors.white70,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Light Gray Unit Strip ("1 Pieces", "500 g", "250 g")
                      Container(
                        height: 26,
                        width: double.infinity,
                        color: const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.only(left: 7, right: 66),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          unit,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Overlapping ADD / "- 1 +" Button on Bottom-Right (Image 3)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: isOutOfStock
                      ? Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'OUT',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        )
                      : quantityInCart == 0
                          ? InkWell(
                              onTap: onAdd,
                              borderRadius: BorderRadius.circular(11),
                              child: Container(
                                height: 34,
                                width: 66,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: const Color(0xFF0072A0),
                                    width: 1.2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'ADD',
                                    style: TextStyle(
                                      color: Color(0xFF0072A0),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 34,
                              width: 72,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF38BDF8),
                                    Color(0xFF0284C7),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x240284C7),
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  InkWell(
                                    onTap: onRemove,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 4,
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$quantityInCart',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: onAdd,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 4,
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 2. BOLD PRICE ("₹13", "₹88", "₹75")
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${price.toInt()}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15.5,
                  color: isOutOfStock ? Colors.grey : const Color(0xFF09090B),
                ),
              ),
              if (marketPrice > price) ...[
                const SizedBox(width: 4),
                Text(
                  '₹${marketPrice.toInt()}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF94A3B8),
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),

          // 3. PRODUCT NAME (Up to 2 lines)
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.22,
              color: isOutOfStock ? Colors.grey : const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 4),

          // 4. LIGHTNING DELIVERY TIME ("⚡ 15 mins")
          const Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 13,
                color: Color(0xFF64748B),
              ),
              SizedBox(width: 2),
              Text(
                '15 mins',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}