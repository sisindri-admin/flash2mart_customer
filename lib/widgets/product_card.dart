import 'dart:convert';
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
    if (imageStr.trim().isEmpty) {
      return Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.green.shade200);
    }

    if (!imageStr.startsWith('http://') && !imageStr.startsWith('https://')) {
      try {
        final cleanBase64 = imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        final bytes = base64Decode(cleanBase64.trim());
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.green.shade200),
        );
      } catch (e) {
        return Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.green.shade200);
      }
    }

    return Image.network(
      imageStr,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.green.shade200),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = stock <= 0;

    int discountPercent = 0;
    if (marketPrice > price && marketPrice > 0) {
      discountPercent = (((marketPrice - price) / marketPrice) * 100).round();
    }

    final int savingsAmount = (marketPrice - price).round();

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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Opacity(
                            opacity: isOutOfStock ? 0.4 : 1.0,
                            child: Hero(
                              tag: 'product_image_$id',
                              child: _buildProductImage(imageUrl),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  if (savingsAmount > 0 && !isOutOfStock)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Save ₹$savingsAmount',
                        style: const TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isOutOfStock ? Colors.grey : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  Text(
                    unit,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${price.toInt()}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: isOutOfStock ? Colors.grey : const Color(0xFF0F172A),
                            ),
                          ),
                          if (marketPrice > price)
                            Text(
                              '₹${marketPrice.toInt()}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),

                      isOutOfStock
                          ? Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'NO STOCK',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            )
                          : quantityInCart == 0
                              ? SizedBox(
                                  height: 32,
                                  width: 66,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00875A).withOpacity(0.1),
                                      foregroundColor: const Color(0xFF00875A),
                                      elevation: 0,
                                      side: const BorderSide(color: Color(0xFF00875A), width: 1.5),
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: onAdd,
                                    child: const Text(
                                      'ADD',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00875A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: onRemove,
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          child: Icon(Icons.remove, size: 14, color: Colors.white),
                                        ),
                                      ),
                                      Text(
                                        '$quantityInCart',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: onAdd,
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          child: Icon(Icons.add, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                    ],
                  ),
                ],
              ),
            ),

            if (discountPercent > 0 && !isOutOfStock)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    '$discountPercent% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

            if (isOutOfStock)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OUT OF STOCK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}