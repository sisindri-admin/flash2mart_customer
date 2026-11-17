import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../services/smart_recommendation_engine.dart';
import '../product_card.dart';
import '../shimmer_skeleton_grid.dart';

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
    ].take(6).toList();

    final List<QueryDocumentSnapshot> flashDealDocs = inStockDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final double price = ((data['price'] ?? 0) as num).toDouble();
      final double marketPrice =
          ((data['marketPrice'] ?? price) as num).toDouble();
      return marketPrice > price && price > 0;
    }).take(6).toList();

    final List<CategorySectionGroup> categorySections =
        SmartRecommendationEngine.buildCategorySections(allDocs);

    // Requirement 1 & 2: NO horizontal side-scroll! Everything rendered in a continuous, tight vertical layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recommendedDocs.isNotEmpty)
          _VerticalProductSection(
            title: 'Recommended for You',
            subtitle: 'Handpicked fresh essentials • 10 mins delivery',
            docs: recommendedDocs,
            onCartUpdated: onCartUpdated,
          ),
        if (flashDealDocs.isNotEmpty)
          _VerticalProductSection(
            title: 'Flash Deals & Super Savers',
            subtitle: 'Biggest price drops on daily groceries',
            docs: flashDealDocs,
            onCartUpdated: onCartUpdated,
          ),
        ...categorySections.map((group) {
          final List<QueryDocumentSnapshot> sectionProducts =
              group.products.take(6).toList();
          if (sectionProducts.isEmpty) return const SizedBox.shrink();

          return _VerticalProductSection(
            title: group.title,
            subtitle: group.subtitle,
            docs: sectionProducts,
            onCartUpdated: onCartUpdated,
          );
        }),
      ],
    );
  }
}

class _VerticalProductSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<QueryDocumentSnapshot> docs;
  final VoidCallback onCartUpdated;

  const _VerticalProductSection({
    required this.title,
    required this.subtitle,
    required this.docs,
    required this.onCartUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 1, bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 2),
      color: Colors.white,
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
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${docs.length} Items',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),

          // Requirement 1 & 2: Vertical Grid with TIGHT gap between top & bottom cards (mainAxisSpacing: 6)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.66,
                crossAxisSpacing: 8,
                mainAxisSpacing: 2,
              ),
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
                final String merchantId =
                    (data['merchantId'] ?? '').toString();
                final String category =
                    (data['category'] ?? 'Grocery / Supermarket').toString();
                final String description =
                    (data['description'] ?? '').toString();
                final bool isCombo = data['isCombo'] == true || data['isComboOffer'] == true || category.toLowerCase().contains('combo');
                final String comboItems = (data['comboItems'] ?? '').toString();
                final List<String> comboImages = (data['images'] is List)
                    ? (data['images'] as List).map((e) => e.toString()).toList()
                    : const [];
                final List<Map<String, dynamic>> comboProductsList = (data['comboProductsList'] is List)
                    ? (data['comboProductsList'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
                    : const [];

                return Selector<CartProvider, int>(
                  selector: (context, cart) =>
                      cart.items[productId]?.quantity ?? 0,
                  builder: (context, qty, child) {
                    return ProductCard(
                      key: ValueKey('vsec_${title}_$productId'),
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
                      isCombo: isCombo,
                      comboItems: comboItems,
                      comboImages: comboImages,
                      comboProductsList: comboProductsList,
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
    return const ShimmerProductSkeletonGrid(
      crossAxisCount: 3,
      itemCount: 6,
      childAspectRatio: 0.66,
    );
  }
}
