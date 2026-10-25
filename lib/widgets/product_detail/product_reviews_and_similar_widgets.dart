import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../screens/product_detail_screen.dart';

class ProductReviewsAndSimilarSection extends StatefulWidget {
  final String productId;
  final String productName;
  final String category;
  final String primaryImageUrl;
  final String deliveryLocation;
  final VoidCallback onChangeLocationTap;

  const ProductReviewsAndSimilarSection({
    super.key,
    required this.productId,
    required this.productName,
    required this.category,
    required this.primaryImageUrl,
    required this.deliveryLocation,
    required this.onChangeLocationTap,
  });

  @override
  State<ProductReviewsAndSimilarSection> createState() =>
      _ProductReviewsAndSimilarSectionState();
}

class _ProductReviewsAndSimilarSectionState
    extends State<ProductReviewsAndSimilarSection> {
  final Set<String> _likedReviewIds = {};

  final List<Map<String, dynamic>> _defaultReviews = [
    {
      'id': 'rev_1',
      'author': 'Lakshmi Narayana',
      'rating': 5,
      'tag': 'Very Good',
      'date': 'Posted recently',
      'comment':
          'Super fresh quality and very fast 15 mins delivery in Nellore! Packaging is neat and hygienic. Definitely ordering again.',
      'helpfulCount': 37,
    },
    {
      'id': 'rev_2',
      'author': 'Prachi Patil',
      'rating': 5,
      'tag': 'Very Good',
      'date': 'Verified Purchase',
      'comment':
          'Genuine product received at the lowest price compared to local market. Delivery partner was polite and on time.',
      'helpfulCount': 50,
    },
  ];

  Widget _buildProductImage(String imageStr, {BoxFit fit = BoxFit.contain}) {
    if (imageStr.trim().isEmpty) {
      return Icon(
        Icons.shopping_bag_outlined,
        size: 40,
        color: Colors.green.shade200,
      );
    }

    if (!imageStr.startsWith('http://') && !imageStr.startsWith('https://')) {
      try {
        final cleanBase64 =
            imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        final bytes = base64Decode(cleanBase64.trim());
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.shopping_bag_outlined,
            size: 40,
            color: Colors.green.shade200,
          ),
        );
      } catch (_) {
        return Icon(
          Icons.shopping_bag_outlined,
          size: 40,
          color: Colors.green.shade200,
        );
      }
    }

    return Image.network(
      imageStr,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.shopping_bag_outlined,
        size: 40,
        color: Colors.green.shade200,
      ),
    );
  }

  Future<void> _openWriteReviewDialog(BuildContext context) async {
    final TextEditingController commentCtrl = TextEditingController();
    int selectedStars = 5;

    final bool? submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Rate & Review Product',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (idx) {
                  final int starVal = idx + 1;
                  return IconButton(
                    onPressed: () {
                      setDialogState(() => selectedStars = starVal);
                    },
                    icon: Icon(
                      starVal <= selectedStars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience with quality & delivery...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00875A),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );

    if (submitted == true && commentCtrl.text.trim().isNotEmpty) {
      final User? user = FirebaseAuth.instance.currentUser;
      try {
        await FirebaseFirestore.instance.collection('product_reviews').add({
          'productId': widget.productId,
          'author': user?.displayName ?? user?.phoneNumber ?? 'Verified Customer',
          'rating': selectedStars,
          'tag': selectedStars >= 4 ? 'Very Good' : 'Good',
          'comment': commentCtrl.text.trim(),
          'helpfulCount': 1,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      setState(() {
        _defaultReviews.insert(0, {
          'id': 'custom_${DateTime.now().millisecondsSinceEpoch}',
          'author': user?.displayName ?? 'Verified Customer',
          'rating': selectedStars,
          'tag': selectedStars >= 4 ? 'Very Good' : 'Good',
          'date': 'Just now',
          'comment': commentCtrl.text.trim(),
          'helpfulCount': 1,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // 1. CUSTOMER RATINGS & REVIEWS BREAKDOWN + REAL PHOTOS + REVIEWS LIST (Screenshots 2 & 3)
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Customer Ratings & Reviews',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openWriteReviewDialog(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00875A),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.rate_review_outlined, size: 15),
                    label: const Text(
                      'Rate Product',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Rating Summary Box + 5 Progress Bars (Screenshot 2)
              Row(
                children: [
                  // Big Green Rating Card
                  Container(
                    width: 112,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: const Color(0xFF00875A),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '4.3',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          color: const Color(0xFFF8FAFC),
                          child: const Column(
                            children: [
                              Text(
                                '997 ratings',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '324 reviews',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // 5 Rating Progress Bars
                  Expanded(
                    child: Column(
                      children: [
                        _buildRatingBar(
                          'Very Good',
                          0.65,
                          '620',
                          const Color(0xFF00875A),
                        ),
                        const SizedBox(height: 6),
                        _buildRatingBar(
                          'Good',
                          0.26,
                          '230',
                          const Color(0xFF22C55E),
                        ),
                        const SizedBox(height: 6),
                        _buildRatingBar(
                          'Ok-Ok',
                          0.09,
                          '78',
                          const Color(0xFFF59E0B),
                        ),
                        const SizedBox(height: 6),
                        _buildRatingBar(
                          'Bad',
                          0.03,
                          '25',
                          const Color(0xFFEA580C),
                        ),
                        const SizedBox(height: 6),
                        _buildRatingBar(
                          'Very Bad',
                          0.04,
                          '44',
                          const Color(0xFFDC2626),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Real Photos (25) Section (Screenshot 3)
              const Text(
                'Real Customer Photos (25)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(4, (idx) {
                  final bool isLast = idx == 3;
                  return Expanded(
                    child: Container(
                      height: 76,
                      margin: EdgeInsets.only(right: isLast ? 0 : 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: _buildProductImage(widget.primaryImageUrl),
                          ),
                          if (isLast)
                            Container(
                              color: const Color(0x88000000),
                              child: const Center(
                                child: Text(
                                  '+21\nMore',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Individual Customer Review Cards (Screenshot 3)
              ..._defaultReviews.map((rev) {
                final String revId = rev['id'] as String;
                final bool isLiked = _likedReviewIds.contains(revId);
                final int count =
                    (rev['helpfulCount'] as int) + (isLiked ? 1 : 0);

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00875A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${rev['rating']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.star_rounded,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${rev['tag']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${rev['date']}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${rev['comment']}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF334155),
                                    height: 1.38,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '~ ${rev['author']}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 54,
                            height: 54,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: _buildProductImage(widget.primaryImageUrl),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isLiked) {
                              _likedReviewIds.remove(revId);
                            } else {
                              _likedReviewIds.add(revId);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.thumb_up_alt_rounded
                                    : Icons.thumb_up_alt_outlined,
                                size: 16,
                                color: isLiked
                                    ? const Color(0xFF00875A)
                                    : const Color(0xFF475569),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Helpful ($count)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isLiked
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isLiked
                                      ? const Color(0xFF00875A)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 2. DELIVERY TIMELINE CARD + 3-ICON TRUST STRIP (Screenshot 4)
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

        // 3. PEOPLE ALSO VIEWED (2-COLUMN SIMILAR PRODUCTS GRID) (Screenshot 4)
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PEOPLE ALSO VIEWED',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .limit(12)
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = (snapshot.data?.docs ?? [])
                      .where((d) => d.id != widget.productId)
                      .take(6)
                      .toList();

                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'More fresh products available on Home Screen',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final String pId = doc.id;
                      final String pName =
                          (data['name'] ?? data['title'] ?? 'Product').toString();
                      final double pPrice =
                          ((data['price'] ?? 0) as num).toDouble();
                      final double pMarketPrice =
                          ((data['marketPrice'] ?? (pPrice + 15)) as num)
                              .toDouble();
                      final String pUnit =
                          (data['unit'] ?? data['weight'] ?? '1 unit').toString();
                      final String pImg = (data['imageBase64'] ??
                              data['imageUrl'] ??
                              data['image'] ??
                              '')
                          .toString();
                      final int pStock = ((data['stock'] ?? 1) as num).toInt();

                      int disc = 0;
                      if (pMarketPrice > pPrice && pMarketPrice > 0) {
                        disc = (((pMarketPrice - pPrice) / pMarketPrice) * 100)
                            .round();
                      }
                      final int specialOffer =
                          (pPrice - 8).clamp(1, pPrice).round();

                      return GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
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
                            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                      padding: const EdgeInsets.all(10),
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
                                          child: const Text(
                                            'SALE',
                                            style: TextStyle(
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6D28D9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            size: 10,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'Mall',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '₹${pPrice.toInt()}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        if (disc > 0) ...[
                                          Text(
                                            '₹${pMarketPrice.toInt()}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF94A3B8),
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$disc% off',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹$specialOffer with 1 Special Offer',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF00875A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Discount for Nellore',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00875A),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Row(
                                            children: [
                                              Text(
                                                '4.3',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Icon(
                                                Icons.star_rounded,
                                                size: 10,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          '(540)',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: Color(0xFF64748B),
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
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBar(
    String label,
    double ratio,
    String countText,
    Color barColor,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            countText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
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
