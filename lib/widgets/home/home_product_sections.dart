import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../services/smart_recommendation_engine.dart';
import '../product_card.dart';

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
    ].take(9).toList();

    final List<QueryDocumentSnapshot> flashDealDocs = inStockDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final double price = ((data['price'] ?? 0) as num).toDouble();
      final double marketPrice =
          ((data['marketPrice'] ?? price) as num).toDouble();
      return marketPrice > price && price > 0;
    }).take(9).toList();

    // Category-wise sections (Milk/Curd/Dairy, Vegetables & Fruits, Cooking & Grocery, etc.)
    final List<CategorySectionGroup> categorySections =
        SmartRecommendationEngine.buildCategorySections(allDocs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recommendedDocs.isNotEmpty)
          _HorizontalProductSection(
            title: 'Recommended for You',
            subtitle: 'Handpicked fresh essentials • 15 mins delivery',
            badgeText: 'TOP PICKS',
            badgeColor: const Color(0xFF00875A),
            headerBgGradient: const [Color(0xFFF0FDF4), Colors.white],
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
            headerBgGradient: const [Color(0xFFFEF2F2), Colors.white],
            docs: flashDealDocs,
            onCartUpdated: onCartUpdated,
            isFlashDeal: true,
          ),
        // Category-wise Horizontal Carousels on Home Screen using Image 3 ProductCard
        ...categorySections.map((group) {
          return _HorizontalProductSection(
            title: group.title,
            subtitle: group.subtitle,
            badgeText: 'CATEGORY',
            badgeColor: group.accentColor,
            headerBgGradient: [group.bgTint, Colors.white],
            docs: group.products.take(10).toList(),
            onCartUpdated: onCartUpdated,
            isFlashDeal: false,
          );
        }),
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
      margin: const EdgeInsets.only(top: 10, bottom: 4),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          const SizedBox(height: 12),
          SizedBox(
            height: 226,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final String productId = doc.id;
                final String name =
                    (data['name'] ?? data['title'] ?? 'Product').toString();
                final double price = ((data['price'] ?? 0) as num).toDouble();
                final double marketPrice =
                    ((data['marketPrice'] ?? price) as num).toDouble();
                final String unit =
                    (data['unit'] ?? data['weight'] ?? '1 unit').toString();
                final String imageUrl = (data['imageBase64'] ??
                        data['imageUrl'] ??
                        data['image'] ??
                        '')
                    .toString();
                final int stock = ((data['stock'] ?? 1) as num).toInt();
                final String merchantId = (data['merchantId'] ?? '').toString();
                final String category =
                    (data['category'] ?? 'Grocery / Supermarket').toString();
                final String description =
                    (data['description'] ?? '').toString();

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 116,
                    child: Selector<CartProvider, int>(
                      selector: (context, cart) =>
                          cart.items[productId]?.quantity ?? 0,
                      builder: (context, qty, child) {
                        return ProductCard(
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
                            context
                                .read<CartProvider>()
                                .removeSingleItem(productId);
                            onCartUpdated();
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.48,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 132,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 8),
            Container(height: 14, width: 45, color: const Color(0xFFF1F5F9)),
            const SizedBox(height: 6),
            Container(height: 11, width: 90, color: const Color(0xFFF1F5F9)),
            const SizedBox(height: 4),
            Container(height: 10, width: 55, color: const Color(0xFFF1F5F9)),
          ],
        );
      },
    );
  }
}
