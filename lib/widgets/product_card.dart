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

  static final Map<String, MemoryImage> _sharedMemoryImageCache = {};
  static final Set<String> _invalidBase64Keys = {};

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
    if (trimmed.isEmpty || _invalidBase64Keys.contains(trimmed)) {
      return Container(
        color: const Color(0xFFF8FAFC),
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 38,
          color: Colors.green.shade200,
        ),
      );
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      MemoryImage? memImg = _sharedMemoryImageCache[trimmed];
      if (memImg == null) {
        try {
          final String cleanBase64 =
              trimmed.contains(',') ? trimmed.split(',').last : trimmed;
          final Uint8List bytes = base64Decode(cleanBase64.trim());
          memImg = MemoryImage(bytes);
          _sharedMemoryImageCache[trimmed] = memImg;
        } catch (_) {
          _invalidBase64Keys.add(trimmed);
          return Container(
            color: const Color(0xFFF8FAFC),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 38,
              color: Colors.green.shade200,
            ),
          );
        }
      }
      return Image(
        image: memImg,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF8FAFC),
          child: Icon(
            Icons.shopping_bag_outlined,
            size: 38,
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
          size: 38,
          color: Colors.green.shade200,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = stock <= 0;

    final double effectiveMarketPrice = (marketPrice > price && price > 0)
        ? marketPrice
        : (price > 0 ? (price * 1.18).ceilToDouble() : price);

    int discountPercent = 0;
    if (effectiveMarketPrice > price && effectiveMarketPrice > 0) {
      discountPercent =
          (((effectiveMarketPrice - price) / effectiveMarketPrice) * 100)
              .round()
              .clamp(5, 85);
    }

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: id,
                productData: {
                  'name': name,
                  'price': price,
                  'marketPrice': effectiveMarketPrice,
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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. IMAGE + GRAY UNIT STRIP + OVERLAPPING ADD / "- 1 +" BUTTON
              SizedBox(
                height: 126,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 121,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 0.8,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(11),
                              ),
                              child: Opacity(
                                opacity: isOutOfStock ? 0.45 : 1.0,
                                child: _buildProductImage(imageUrl),
                              ),
                            ),
                          ),
                          // Light Gray Unit Strip ("410 g", "849 g", "500 g")
                          Container(
                            height: 24,
                            width: double.infinity,
                            color: const Color(0xFFF1F5F9),
                            padding: const EdgeInsets.only(left: 7, right: 60),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              unit,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Overlapping ADD / "- 1 +" Button on Bottom-Right
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: isOutOfStock
                          ? Container(
                              height: 28,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Center(
                                child: Text(
                                  'OUT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            )
                          : quantityInCart == 0
                              ? InkWell(
                                  onTap: onAdd,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 30,
                                    width: 58,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFF007AA6),
                                        width: 1.3,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x12000000),
                                          blurRadius: 3,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'ADD',
                                        style: TextStyle(
                                          color: Color(0xFF007AA6),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 30,
                                  width: 66,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF38BDF8),
                                        Color(0xFF0284C7),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x220284C7),
                                        blurRadius: 4,
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
                                            horizontal: 3,
                                            vertical: 3,
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$quantityInCart',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: onAdd,
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 3,
                                            vertical: 3,
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            size: 14,
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

              // 2. BOLD PRICE + STRUCK-THROUGH MRP + GREEN "% OFF" ON SAME ROW (Exact Image 1 layout)
              Row(
                children: [
                  Text(
                    '₹${price.toInt()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color:
                          isOutOfStock ? Colors.grey : const Color(0xFF09090B),
                    ),
                  ),
                  if (effectiveMarketPrice > price) ...[
                    const SizedBox(width: 5),
                    Text(
                      '₹${effectiveMarketPrice.toInt()}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        decoration: TextDecoration.lineThrough,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$discountPercent% off',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A), // Exact green % off
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),

              // 3. PRODUCT NAME (Exact typography from Image 1)
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  height: 1.25,
                  color:
                      isOutOfStock ? Colors.grey : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 3),

              // 4. DELIVERY TIME ("⚡ 15 mins")
              const Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 12,
                    color: Color(0xFF16A34A),
                  ),
                  SizedBox(width: 2),
                  Text(
                    '15 mins',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}