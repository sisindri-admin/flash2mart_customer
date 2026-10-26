import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../screens/product_detail_screen.dart';
import '../../services/smart_recommendation_engine.dart';
import 'realtime_reviews_widget.dart';

class ProductReviewsAndSimilarSection extends StatefulWidget {
  final String productId;
  final String productName;
  final String category;
  final String primaryImageUrl;
  final String deliveryLocation;
  final VoidCallback onChangeLocationTap;
  final int endlessBatchesCount;

  const ProductReviewsAndSimilarSection({
    super.key,
    required this.productId,
    required this.productName,
    required this.category,
    required this.primaryImageUrl,
    required this.deliveryLocation,
    required this.onChangeLocationTap,
    this.endlessBatchesCount = 2,
  });

  @override
  State<ProductReviewsAndSimilarSection> createState() =>
      _ProductReviewsAndSimilarSectionState();
}

class _ProductReviewsAndSimilarSectionState
    extends State<ProductReviewsAndSimilarSection> {
  final Map<String, Uint8List> _base64Cache = {};

  Widget _buildProductImage(String imageStr, {BoxFit fit = BoxFit.contain}) {
    final String trimmed = imageStr.trim();
    if (trimmed.isEmpty) {
      return Icon(
        Icons.shopping_bag_outlined,
        size: 40,
        color: Colors.green.shade200,
      );
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      Uint8List? bytes = _base64Cache[trimmed];
      if (bytes == null) {
        try {
          final String cleanBase64 =
              trimmed.contains(',') ? trimmed.split(',').last : trimmed;
          bytes = base64Decode(cleanBase64.trim());
          _base64Cache[trimmed] = bytes;
        } catch (_) {
          return Icon(
            Icons.shopping_bag_outlined,
            size: 40,
            color: Colors.green.shade200,
          );
        }
      }
      return Image.memory(
        bytes,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.shopping_bag_outlined,
          size: 40,
          color: Colors.green.shade200,
        ),
      );
    }

    return Image.network(
      trimmed,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.shopping_bag_outlined,
        size: 40,
        color: Colors.green.shade200,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // 1. REAL-TIME RATINGS, REAL CUSTOMER PHOTOS & LIVE REVIEWS
        RealtimeReviewsWidget(
          productId: widget.productId,
          productName: widget.productName,
          primaryImageUrl: widget.primaryImageUrl,
        ),
        const SizedBox(height: 8),

        // 2. DELIVERY TIMELINE CARD + 3-ICON TRUST STRIP
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Delivery in ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '15 - 20 Mins (Today)',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'at ${widget.deliveryLocation}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: widget.onChangeLocationTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00875A),
                      side: const BorderSide(color: Color(0xFF00875A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Change',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTrustIconColumn(
                    icon: Icons.autorenew_rounded,
                    iconColor: const Color(0xFF00875A),
                    label: 'Easy Exchange',
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: const Color(0xFFE2E8F0),
                  ),
                  _buildTrustIconColumn(
                    icon: Icons.local_offer_rounded,
                    iconColor: const Color(0xFF2563EB),
                    label: 'Lowest Price',
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: const Color(0xFFE2E8F0),
                  ),
                  _buildTrustIconColumn(
                    icon: Icons.payments_rounded,
                    iconColor: const Color(0xFFD97706),
                    label: 'Cash on Delivery',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 3. SMART RELATED PRODUCTS + COOKING COMPANIONS + CATEGORY-WISE + ENDLESS SCROLL
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, snapshot) {
            final List<QueryDocumentSnapshot> allDocs =
                snapshot.data?.docs ?? [];
            if (allDocs.isEmpty) {
              return const SizedBox.shrink();
            }

            // A. Smart Related Products (e.g., Other brand Milk packets, Curd, Dairy when viewing Milk)
            final List<QueryDocumentSnapshot> relatedDocs =
                SmartRecommendationEngine.getRelatedProducts(
              currentProductId: widget.productId,
              currentName: widget.productName,
              currentCategory: widget.category,
              allDocs: allDocs,
            ).take(8).toList();

            // B. Cooking & Daily Companion Products
            final List<QueryDocumentSnapshot> cookingDocs =
                SmartRecommendationEngine.getCookingAndCompanionProducts(
              currentProductId: widget.productId,
              currentName: widget.productName,
              allDocs: allDocs,
            ).take(8).toList();

            // C. Category-wise Grouped Sections
            final List<CategorySectionGroup> categoryGroups =
                SmartRecommendationEngine.buildCategorySections(
              allDocs,
              excludeProductId: widget.productId,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION A: SIMILAR & RELATED BRANDS (Horizontal Carousel with ADD Buttons)
                if (relatedDocs.isNotEmpty)
                  _buildHorizontalRelatedCarousel(
                    title: 'Similar & Related Products',
                    subtitle:
                        'Other brands, curd, dairy & matching items for ${widget.productName}',
                    badgeText: 'MATCHING PICKS',
                    accentColor: const Color(0xFF00875A),
                    docs: relatedDocs,
                  ),

                // SECTION B: COOKING & DAILY ESSENTIALS CAROUSEL
                if (cookingDocs.isNotEmpty)
                  _buildHorizontalRelatedCarousel(
                    title: 'Cooking & Kitchen Essentials',
                    subtitle: 'Frequently bought together for daily cooking',
                    badgeText: 'DAILY NEEDS',
                    accentColor: const Color(0xFFD97706),
                    docs: cookingDocs,
                  ),

                // SECTION C: CATEGORY-WISE SECTIONS AS USER SCROLLS
                ...categoryGroups.map((group) {
                  return _buildCategoryGridSection(
                    title: group.title,
                    subtitle: group.subtitle,
                    accentColor: group.accentColor,
                    bgTint: group.bgTint,
                    docs: group.products.take(4).toList(),
                  );
                }),

                // SECTION D: ENDLESS / INFINITE SCROLL DISCOVERY BATCHES
                ...List.generate(widget.endlessBatchesCount, (batchIdx) {
                  final endlessGroup =
                      SmartRecommendationEngine.generateEndlessSection(
                    batchIndex: batchIdx,
                    allDocs: allDocs,
                  );
                  return _buildCategoryGridSection(
                    title: endlessGroup.title,
                    subtitle: endlessGroup.subtitle,
                    accentColor: endlessGroup.accentColor,
                    bgTint: endlessGroup.bgTint,
                    docs: endlessGroup.products,
                  );
                }),

                // Loading indicator at bottom indicating endless stream
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  color: Colors.white,
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF00875A),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Keep scrolling for more fresh recommendations...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHorizontalRelatedCarousel({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color accentColor,
    required List<QueryDocumentSnapshot> docs,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
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
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 238,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: docs.length,
              itemBuilder: (context, idx) {
                return SizedBox(
                  width: 158,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _buildInteractiveProductCard(docs[idx]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGridSection({
    required String title,
    required String subtitle,
    required Color accentColor,
    required Color bgTint,
    required List<QueryDocumentSnapshot> docs,
  }) {
    if (docs.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.category_rounded, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.59,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              return _buildInteractiveProductCard(docs[index]);
            },
          ),
        ],
      ),
    );
  }

  /// Product card with Mall badge, Special Offer price, AND direct ADD / + - button
  Widget _buildInteractiveProductCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String pId = doc.id;
    final String pName = (data['name'] ?? data['title'] ?? 'Product').toString();
    final double pPrice = ((data['price'] ?? 0) as num).toDouble();
    final double pMarketPrice =
        ((data['marketPrice'] ?? (pPrice + 15)) as num).toDouble();
    final String pUnit =
        (data['unit'] ?? data['weight'] ?? '1 unit').toString();
    final String pImg =
        (data['imageBase64'] ?? data['imageUrl'] ?? data['image'] ?? '')
            .toString();
    final int pStock = ((data['stock'] ?? 1) as num).toInt();
    final bool isOutOfStock = pStock <= 0;

    int disc = 0;
    if (pMarketPrice > pPrice && pMarketPrice > 0) {
      disc = (((pMarketPrice - pPrice) / pMarketPrice) * 100).round();
    }
    final int specialOffer = (pPrice - 8).clamp(1, pPrice).round();

    return Selector<CartProvider, int>(
      selector: (context, cart) => cart.items[pId]?.quantity ?? 0,
      builder: (context, currentQty, child) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(
                  productId: pId,
                  productData: {
                    'name': pName,
                    'price': pPrice,
                    'marketPrice': pMarketPrice,
                    'unit': pUnit,
                    'imageUrl': pImg,
                    'stock': pStock,
                    'merchantId': data['merchantId'] ?? '',
                    'category': data['category'] ?? widget.category,
                    'description': data['description'] ?? '',
                  },
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: currentQty > 0
                    ? const Color(0xFF00875A)
                    : const Color(0xFFE2E8F0),
                width: currentQty > 0 ? 1.5 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.all(8),
                        child: _buildProductImage(pImg),
                      ),
                      if (disc > 0)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              '$disc% OFF',
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6D28D9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 9,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Mall',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              pUnit,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹$specialOffer with Special Offer',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00875A),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Price + Direct ADD / + - Stepper Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${pPrice.toInt()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (disc > 0)
                                Text(
                                  '₹${pMarketPrice.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFF94A3B8),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                          isOutOfStock
                              ? const Text(
                                  'NO STOCK',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : currentQty == 0
                                  ? SizedBox(
                                      height: 28,
                                      width: 58,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFF0FDF4),
                                          foregroundColor:
                                              const Color(0xFF00875A),
                                          elevation: 0,
                                          padding: EdgeInsets.zero,
                                          side: const BorderSide(
                                            color: Color(0xFF00875A),
                                            width: 1.3,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(7),
                                          ),
                                        ),
                                        onPressed: () {
                                          context.read<CartProvider>().addItem(
                                                id: pId,
                                                name: pName,
                                                price: pPrice,
                                                unit: pUnit,
                                                imageUrl: pImg,
                                              );
                                        },
                                        child: const Text(
                                          'ADD',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00875A),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => context
                                                .read<CartProvider>()
                                                .removeSingleItem(pId),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 5,
                                              ),
                                              child: Icon(
                                                Icons.remove,
                                                size: 13,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '$currentQty',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => context
                                                .read<CartProvider>()
                                                .addItem(
                                                  id: pId,
                                                  name: pName,
                                                  price: pPrice,
                                                  unit: pUnit,
                                                  imageUrl: pImg,
                                                ),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 5,
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
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrustIconColumn({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(24),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}
