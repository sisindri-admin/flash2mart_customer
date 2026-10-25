import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../screens/product_detail_screen.dart';

class HomeProductSections extends StatelessWidget {
  final List<QueryDocumentSnapshot> allDocs;
  final VoidCallback onCartUpdated;

  const HomeProductSections({
    super.key,
    required this.allDocs,
    required this.onCartUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (allDocs.isEmpty) return const SizedBox.shrink();

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final Set<String> cartProductIds = cartProvider.items.keys.toSet();

    final List<QueryDocumentSnapshot> inStockDocs = allDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final int stock = ((data['stock'] ?? 1) as num).toInt();
      return stock > 0;
    }).toList();

    final List<QueryDocumentSnapshot> recommendedDocs = [
      ...inStockDocs.where((d) => !cartProductIds.contains(d.id)),
      ...inStockDocs.where((d) => cartProductIds.contains(d.id)),
    ].take(8).toList();

    final List<QueryDocumentSnapshot> flashDealDocs = inStockDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final double price = ((data['price'] ?? 0) as num).toDouble();
      final double marketPrice = ((data['marketPrice'] ?? price) as num).toDouble();
      return marketPrice > price && price > 0;
    }).take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recommendedDocs.isNotEmpty)
          _HorizontalProductSection(
            title: 'Recommended for You',
            subtitle: 'Handpicked fresh essentials • 15 mins delivery',
            badgeText: 'TOP PICKS',
            badgeColor: const Color(0xFF00875A),
            headerBgGradient: const [Color(0xFFF0FDF4), Color(0xFFF8FAFC)],
            docs: recommendedDocs,
            onCartUpdated: onCartUpdated,
            isFlashDeal: false,
          ),
        if (flashDealDocs.isNotEmpty)
          _HorizontalProductSection(
            title: 'Flash Deals & Super Savers',
            subtitle: 'Biggest price drops on daily groceries',
            badgeText: 'HOT DEALS',
            badgeColor: const Color(0xFFDC2626),
            headerBgGradient: const [Color(0xFFFEF2F2), Color(0xFFF8FAFC)],
            docs: flashDealDocs,
            onCartUpdated: onCartUpdated,
            isFlashDeal: true,
          ),
      ],
    );
  }
}

class _HorizontalProductSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final List<Color> headerBgGradient;
  final List<QueryDocumentSnapshot> docs;
  final VoidCallback onCartUpdated;
  final bool isFlashDeal;

  const _HorizontalProductSection({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.headerBgGradient,
    required this.docs,
    required this.onCartUpdated,
    required this.isFlashDeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: headerBgGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isFlashDeal
                                ? Icons.local_fire_department_rounded
                                : Icons.recommend_rounded,
                            size: 18,
                            color: badgeColor,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 222,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final String productId = doc.id;
                final String name = (data['name'] ?? data['title'] ?? 'Product').toString();
                final double price = ((data['price'] ?? 0) as num).toDouble();
                final double marketPrice = ((data['marketPrice'] ?? price) as num).toDouble();
                final String unit = (data['unit'] ?? data['weight'] ?? '1 unit').toString();
                final String imageUrl =
                    (data['imageBase64'] ?? data['imageUrl'] ?? data['image'] ?? '').toString();
                final int stock = ((data['stock'] ?? 1) as num).toInt();
                final String merchantId = (data['merchantId'] ?? '').toString();
                final String category =
                    (data['category'] ?? 'Grocery / Supermarket').toString();
                final String description = (data['description'] ?? '').toString();

                return Selector<CartProvider, int>(
                  selector: (context, cart) => cart.items[productId]?.quantity ?? 0,
                  builder: (context, qty, child) {
                    return _CompactHorizontalProductCard(
                      id: productId,
                      name: name,
                      price: price,
                      marketPrice: marketPrice,
                      unit: unit,
                      imageUrl: imageUrl,
                      stock: stock,
                      merchantId: merchantId,
                      category: category,
                      description: description,
                      quantityInCart: qty,
                      isFlashDeal: isFlashDeal,
                      onAdd: () {
                        context.read<CartProvider>().addItem(
                              id: productId,
                              name: name,
                              price: price,
                              unit: unit,
                              imageUrl: imageUrl,
                            );
                        onCartUpdated();
                      },
                      onRemove: () {
                        context.read<CartProvider>().removeSingleItem(productId);
                        onCartUpdated();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactHorizontalProductCard extends StatelessWidget {
  final String id;
  final String name;
  final double price;
  final double marketPrice;
  final String unit;
  final String imageUrl;
  final int stock;
  final String merchantId;
  final String category;
  final String description;
  final int quantityInCart;
  final bool isFlashDeal;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CompactHorizontalProductCard({
    required this.id,
    required this.name,
    required this.price,
    required this.marketPrice,
    required this.unit,
    required this.imageUrl,
    required this.stock,
    required this.merchantId,
    required this.category,
    required this.description,
    required this.quantityInCart,
    required this.isFlashDeal,
    required this.onAdd,
    required this.onRemove,
  });

  Widget _buildImage(String imageStr) {
    if (imageStr.trim().isEmpty) {
      return Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.green.shade200);
    }

    if (!imageStr.startsWith('http://') && !imageStr.startsWith('https://')) {
      try {
        final cleanBase64 =
            imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        final bytes = base64Decode(cleanBase64.trim());
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.green.shade200),
        );
      } catch (_) {
        return Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.green.shade200);
      }
    }

    return Image.network(
      imageStr,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.green.shade200),
    );
  }

  @override
  Widget build(BuildContext context) {
    int discountPercent = 0;
    if (marketPrice > price && marketPrice > 0) {
      discountPercent = (((marketPrice - price) / marketPrice) * 100).round();
    }

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
        width: 148,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFlashDeal ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: _buildImage(imageUrl)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF00875A)),
                      const SizedBox(width: 2),
                      Text(
                        isFlashDeal ? 'FAST DEAL' : '15 MINS',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00875A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (marketPrice > price)
                            Text(
                              '₹${marketPrice.toInt()}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      quantityInCart == 0
                          ? SizedBox(
                              height: 30,
                              width: 58,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF0FDF4),
                                  foregroundColor: const Color(0xFF00875A),
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  side: const BorderSide(
                                    color: Color(0xFF00875A),
                                    width: 1.4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: onAdd,
                                child: const Text(
                                  'ADD',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00875A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: onRemove,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 5),
                                      child: Icon(Icons.remove, size: 13, color: Colors.white),
                                    ),
                                  ),
                                  Text(
                                    '$quantityInCart',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: onAdd,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 5),
                                      child: Icon(Icons.add, size: 13, color: Colors.white),
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
            if (discountPercent > 0)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isFlashDeal ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Text(
                    '$discountPercent% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
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

class HomeProductSkeletonGrid extends StatelessWidget {
  const HomeProductSkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.63,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(height: 12, width: 100, color: const Color(0xFFF1F5F9)),
              const SizedBox(height: 6),
              Container(height: 10, width: 60, color: const Color(0xFFF1F5F9)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 16, width: 45, color: const Color(0xFFF1F5F9)),
                  Container(
                    height: 30,
                    width: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
