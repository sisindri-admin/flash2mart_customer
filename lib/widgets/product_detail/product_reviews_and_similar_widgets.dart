import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../services/smart_recommendation_engine.dart';
import '../product_card.dart';
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

        // 3. SMART RELATED PRODUCTS + COOKING COMPANIONS + CATEGORY-WISE + ENDLESS SCROLL (ALL USING IMAGE 3 PRODUCT CARDS)
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
            ).take(9).toList();

            // B. Cooking & Daily Companion Products
            final List<QueryDocumentSnapshot> cookingDocs =
                SmartRecommendationEngine.getCookingAndCompanionProducts(
              currentProductId: widget.productId,
              currentName: widget.productName,
              allDocs: allDocs,
            ).take(9).toList();

            // C. Category-wise Grouped Sections
            final List<CategorySectionGroup> categoryGroups =
                SmartRecommendationEngine.buildCategorySections(
              allDocs,
              excludeProductId: widget.productId,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION A: SIMILAR & RELATED BRANDS (Horizontal Carousel with Image 3 Cards)
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

                // SECTION C: CATEGORY-WISE SECTIONS AS USER SCROLLS (3-Column Image 3 Grid)
                ...categoryGroups.map((group) {
                  return _buildCategoryGridSection(
                    title: group.title,
                    subtitle: group.subtitle,
                    accentColor: group.accentColor,
                    bgTint: group.bgTint,
                    docs: group.products.take(6).toList(),
                  );
                }),

                // SECTION D: ENDLESS / INFINITE SCROLL DISCOVERY BATCHES (3-Column Image 3 Grid)
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
            height: 226,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: docs.length,
              itemBuilder: (context, idx) {
                return SizedBox(
                  width: 122,
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
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
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
              crossAxisCount: 3,
              childAspectRatio: 0.48,
              crossAxisSpacing: 10,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              return _buildInteractiveProductCard(docs[index]);
            },
          ),
        ],
      ),
    );
  }

  /// Uses the unified Image 3 ProductCard design everywhere on the Product Detail screen
  Widget _buildInteractiveProductCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String pId = doc.id;
    final String pName = (data['name'] ?? data['title'] ?? 'Product').toString();
    final double pPrice = ((data['price'] ?? 0) as num).toDouble();
    final double pMarketPrice =
        ((data['marketPrice'] ?? pPrice) as num).toDouble();
    final String pUnit =
        (data['unit'] ?? data['weight'] ?? '1 unit').toString();
    final String pImg =
        (data['imageBase64'] ?? data['imageUrl'] ?? data['image'] ?? '')
            .toString();
    final int pStock = ((data['stock'] ?? 1) as num).toInt();
    final String pMerchantId = (data['merchantId'] ?? '').toString();
    final String pCategory =
        (data['category'] ?? widget.category).toString();
    final String pDesc = (data['description'] ?? '').toString();

    return Selector<CartProvider, int>(
      selector: (context, cart) => cart.items[pId]?.quantity ?? 0,
      builder: (context, currentQty, child) {
        return ProductCard(
          id: pId,
          name: pName,
          price: pPrice,
          marketPrice: pMarketPrice,
          unit: pUnit,
          imageUrl: pImg,
          stock: pStock,
          merchantId: pMerchantId,
          category: pCategory,
          description: pDesc,
          quantityInCart: currentQty,
          onAdd: () {
            context.read<CartProvider>().addItem(
                  id: pId,
                  name: pName,
                  price: pPrice,
                  unit: pUnit,
                  imageUrl: pImg,
                );
          },
          onRemove: () {
            context.read<CartProvider>().removeSingleItem(pId);
          },
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
