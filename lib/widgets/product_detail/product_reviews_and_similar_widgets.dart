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
  late final Stream<QuerySnapshot> _productsStream;
  List<QueryDocumentSnapshot> _cachedDocs = const [];

  @override
  void initState() {
    super.initState();
    _productsStream =
        FirebaseFirestore.instance.collection('products').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),

        // 1. REAL-TIME RATINGS, REAL CUSTOMER PHOTOS & LIVE REVIEWS
        RealtimeReviewsWidget(
          productId: widget.productId,
          productName: widget.productName,
          primaryImageUrl: widget.primaryImageUrl,
        ),
        const SizedBox(height: 6),

        // 2. CLEAN DELIVERY & TRUST CARD
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrustIconColumn(
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFF16A34A),
                label: '15 Mins Delivery',
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              _buildTrustIconColumn(
                icon: Icons.autorenew_rounded,
                iconColor: const Color(0xFF0284C7),
                label: 'Easy Exchange',
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              _buildTrustIconColumn(
                icon: Icons.payments_rounded,
                iconColor: const Color(0xFFD97706),
                label: 'Cash on Delivery',
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 3. ZERO-BLINK SMART RELATED PRODUCTS + CATEGORY & ENDLESS FEED
        StreamBuilder<QuerySnapshot>(
          stream: _productsStream,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              _cachedDocs = snapshot.data!.docs;
            }
            final List<QueryDocumentSnapshot> allDocs = _cachedDocs;
            if (allDocs.isEmpty) {
              return const SizedBox.shrink();
            }

            // A. Smart Related Products (Other brands, curd, dairy & matching items)
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
                if (relatedDocs.isNotEmpty)
                  _buildHorizontalRelatedCarousel(
                    title: 'Similar & Related Products',
                    subtitle: 'Other brands & matching essentials',
                    docs: relatedDocs,
                  ),

                if (cookingDocs.isNotEmpty)
                  _buildHorizontalRelatedCarousel(
                    title: 'Frequently Bought Together',
                    subtitle: 'Daily cooking & kitchen companions',
                    docs: cookingDocs,
                  ),

                ...categoryGroups.map((group) {
                  return _buildCategoryGridSection(
                    title: group.title,
                    subtitle: group.subtitle,
                    docs: group.products.take(6).toList(),
                  );
                }),

                ...List.generate(widget.endlessBatchesCount, (batchIdx) {
                  final endlessGroup =
                      SmartRecommendationEngine.generateEndlessSection(
                    batchIndex: batchIdx,
                    allDocs: allDocs,
                  );
                  return _buildCategoryGridSection(
                    title: endlessGroup.title,
                    subtitle: endlessGroup.subtitle,
                    docs: endlessGroup.products,
                  );
                }),
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
    required List<QueryDocumentSnapshot> docs,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
          const SizedBox(height: 12),
          SizedBox(
            height: 224,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: docs.length,
              itemBuilder: (context, idx) {
                return SizedBox(
                  width: 118,
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
    required List<QueryDocumentSnapshot> docs,
  }) {
    if (docs.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.46,
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
          key: ValueKey('pdetail_$pId'),
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
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(24),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}
