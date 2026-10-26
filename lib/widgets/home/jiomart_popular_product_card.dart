import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../screens/product_detail_screen.dart';

class JioMartPopularProductCard extends StatelessWidget {
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

  const JioMartPopularProductCard({
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
    this.category = 'Groceries',
    this.description = '',
    required this.onAdd,
    required this.onRemove,
  });

  Widget _buildProductImage(String imageStr) {
    final String trimmed = imageStr.trim();
    if (trimmed.isEmpty) {
      return Icon(
        Icons.shopping_bag_outlined,
        size: 40,
        color: Colors.blueGrey.shade200,
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
          return Icon(
            Icons.shopping_bag_outlined,
            size: 40,
            color: Colors.blueGrey.shade200,
          );
        }
      }
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.shopping_bag_outlined,
          size: 40,
          color: Colors.blueGrey.shade200,
        ),
      );
    }

    return Image.network(
      trimmed,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.shopping_bag_outlined,
        size: 40,
        color: Colors.blueGrey.shade200,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = stock <= 0;
    final double effectiveMrp =
        marketPrice > price ? marketPrice : (price * 1.18).roundToDouble();
    final int discountPercent = effectiveMrp > price && effectiveMrp > 0
        ? (((effectiveMrp - price) / effectiveMrp) * 100).round()
        : 0;

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
                'marketPrice': effectiveMrp,
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
          SizedBox(
            height: 132,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: 116,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Opacity(
                    opacity: isOutOfStock ? 0.45 : 1.0,
                    child: _buildProductImage(imageUrl),
                  ),
                ),
                Positioned(
                  bottom: 22,
                  left: 8,
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F172A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFCBD5E1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFCBD5E1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 2,
                  left: 4,
                  right: 68,
                  child: Text(
                    unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: isOutOfStock
                      ? Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Center(
                            child: Text(
                              'OUT',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        )
                      : quantityInCart == 0
                          ? InkWell(
                              onTap: onAdd,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 32,
                                width: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF0078AD),
                                    width: 1.3,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x12000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'ADD',
                                    style: TextStyle(
                                      color: Color(0xFF0078AD),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0078AD),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1F000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: onRemove,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$quantityInCart',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: onAdd,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 13,
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
          Text(
            '₹${price.toInt()}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          if (discountPercent > 0)
            Row(
              children: [
                Text(
                  '₹${effectiveMrp.toInt()}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF94A3B8),
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '$discountPercent% off',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 3),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Delivery Before 10:00 AM',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
