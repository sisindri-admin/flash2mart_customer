import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductPriceAndHighlightsSection extends StatefulWidget {
  final String productId;
  final String name;
  final double price;
  final double marketPrice;
  final String unit;
  final String category;
  final String description;
  final String merchantId;
  final int stock;
  final bool isWishlisted;
  final VoidCallback onWishlistToggle;
  final VoidCallback onShareTap;
  final ValueChanged<int> onPackMultiplierChanged;
  final int selectedPackMultiplier;

  const ProductPriceAndHighlightsSection({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.marketPrice,
    required this.unit,
    required this.category,
    required this.description,
    required this.merchantId,
    required this.stock,
    required this.isWishlisted,
    required this.onWishlistToggle,
    required this.onShareTap,
    required this.onPackMultiplierChanged,
    required this.selectedPackMultiplier,
  });

  @override
  State<ProductPriceAndHighlightsSection> createState() =>
      _ProductPriceAndHighlightsSectionState();
}

class _ProductPriceAndHighlightsSectionState
    extends State<ProductPriceAndHighlightsSection> {
  bool _showAdditionalDetails = false;

  Future<Map<String, String>> _fetchMerchantDetails(String merchantId) async {
    if (merchantId.isEmpty) {
      return {
        'storeName': 'Flash2Mart Official Store',
        'location': 'Nellore, Andhra Pradesh',
        'ownerName': 'Verified Partner',
        'storeImageBase64': '',
      };
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('merchants')
          .doc(merchantId)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'storeName': (data['storeName'] ??
                  data['shopName'] ??
                  'Flash2Mart Partner Store')
              .toString(),
          'location': (data['location'] ?? 'Nellore, Andhra Pradesh').toString(),
          'ownerName': (data['ownerName'] ?? 'Verified Merchant').toString(),
          'storeImageBase64': (data['storeImageBase64'] ?? '').toString(),
        };
      }
    } catch (_) {}

    return {
      'storeName': 'Flash2Mart Partner Store',
      'location': 'Nellore, Andhra Pradesh',
      'ownerName': 'Verified Merchant',
      'storeImageBase64': '',
    };
  }

  Widget _buildStoreAvatar(String imageStr) {
    if (imageStr.trim().isEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.storefront_rounded,
          color: Color(0xFF00875A),
          size: 24,
        ),
      );
    }

    if (!imageStr.startsWith('http://') && !imageStr.startsWith('https://')) {
      try {
        final cleanBase64 =
            imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        final bytes = base64Decode(cleanBase64.trim());
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            bytes,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.storefront_rounded,
              color: Color(0xFF00875A),
              size: 24,
            ),
          ),
        );
      } catch (_) {}
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageStr,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.storefront_rounded,
          color: Color(0xFF00875A),
          size: 24,
        ),
      ),
    );
  }

  void _showSpecialOfferSheet(BuildContext context, double specialPrice, int extraOff) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Special Price Breakdown',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            _buildPriceBreakdownRow(
              'Maximum Retail Price (MRP)',
              '₹${widget.marketPrice.toInt()}',
            ),
            const SizedBox(height: 6),
            _buildPriceBreakdownRow(
              'Flash2Mart Selling Price',
              '₹${widget.price.toInt()}',
            ),
            const SizedBox(height: 6),
            _buildPriceBreakdownRow(
              'Special Offer / Local Nellore Discount',
              '-₹$extraOff',
              isGreen: true,
            ),
            const Divider(height: 20),
            _buildPriceBreakdownRow(
              'Effective Special Price',
              '₹${specialPrice.toInt()}',
              isBold: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_offer_rounded, size: 16, color: Color(0xFF16A34A)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Apply coupon FLASH20 or WELCOME10 at Checkout to claim this special price!',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdownRow(
    String label,
    String val, {
    bool isGreen = false,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: const Color(0xFF334155),
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: isGreen
                ? const Color(0xFF16A34A)
                : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double effectivePrice = widget.price * widget.selectedPackMultiplier;
    final double effectiveMarketPrice =
        widget.marketPrice * widget.selectedPackMultiplier;

    int discountPercent = 0;
    if (effectiveMarketPrice > effectivePrice && effectiveMarketPrice > 0) {
      discountPercent =
          (((effectiveMarketPrice - effectivePrice) / effectiveMarketPrice) * 100)
              .round();
    }

    final int localNelloreDiscount =
        (effectivePrice * 0.06).round().clamp(5, 30);
    final double specialOfferPrice =
        (effectivePrice - localNelloreDiscount).clamp(1.0, effectivePrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. PRICING, MALL BADGE, WISHLIST & SHARE CARD (Screenshot 1)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Mall',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextSpan(
                            text: '${widget.name} (${widget.unit})',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Wishlist Action
                  InkWell(
                    onTap: widget.onWishlistToggle,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        children: [
                          Icon(
                            widget.isWishlisted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 22,
                            color: widget.isWishlisted
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF475569),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Wishlist',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Share Action
                  InkWell(
                    onTap: widget.onShareTap,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        children: [
                          Icon(
                            Icons.share_outlined,
                            size: 22,
                            color: Color(0xFF475569),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Share',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Main Price Row (₹381  ₹399  5% off  (i))
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹${effectivePrice.toInt()}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (effectiveMarketPrice > effectivePrice) ...[
                    Text(
                      '₹${effectiveMarketPrice.toInt()}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF94A3B8),
                        decoration: TextDecoration.lineThrough,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$discountPercent% off',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _showSpecialOfferSheet(
                      context,
                      specialOfferPrice,
                      localNelloreDiscount,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Green Special Offer Row (₹353 with 1 Special Offer >)
              InkWell(
                onTap: () => _showSpecialOfferSheet(
                  context,
                  specialOfferPrice,
                  localNelloreDiscount,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${specialOfferPrice.toInt()} with 1 Special Offer',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00875A),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF00875A),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Discount for Nellore Row
              Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: Color(0xFF00875A),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '₹$localNelloreDiscount off | Special Discount for Nellore',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Green Rating Pill + 15 Mins Express Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00875A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '4.3',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.star_rounded, size: 13, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '(997 Ratings)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 14,
                          color: Color(0xFFD97706),
                        ),
                        Text(
                          '15 MINS DELIVERY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF92400E),
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
        const SizedBox(height: 8),

        // 2. SELECT SIZE / PACK QUANTITY SECTION (Screenshot 2)
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Size / Pack Quantity',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildSizeChip(
                    label: widget.unit.isNotEmpty ? widget.unit : 'Standard Pack',
                    multiplier: 1,
                  ),
                  _buildSizeChip(
                    label: 'Combo Pack of 2 (${widget.unit} x 2)',
                    multiplier: 2,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 3. SOLD BY VERIFIED SELLER CARD (Screenshot 2)
        FutureBuilder<Map<String, String>>(
          future: _fetchMerchantDetails(widget.merchantId),
          builder: (context, snapshot) {
            final String storeName =
                snapshot.data?['storeName'] ?? 'FLASH2MART PARTNER STORE';
            final String location =
                snapshot.data?['location'] ?? 'Nellore, Andhra Pradesh';
            final String storeImg = snapshot.data?['storeImageBase64'] ?? '';

            return Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  _buildStoreAvatar(storeImg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sold by ${storeName.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF00875A),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '4.4',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF00875A),
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.star_rounded,
                                    size: 12,
                                    color: Color(0xFF00875A),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF475569),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // 4. PRODUCT HIGHLIGHTS (2-COLUMN GRID + COPY BUTTON + ADDITIONAL DETAILS) (Screenshot 2)
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
                    'Product Highlights',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      final String summaryText =
                          'Product: ${widget.name}\nCategory: ${widget.category}\nNet Quantity: ${widget.unit}\nPrice: ₹${widget.price.toInt()}\nDescription: ${widget.description}';
                      Clipboard.setData(ClipboardData(text: summaryText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Product highlights copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'COPY',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00875A),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildHighlightCell('Category', widget.category),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHighlightCell('Net Quantity (N)', widget.unit),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildHighlightCell(
                      'Quality Standard',
                      '100% Farm Fresh & Verified',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHighlightCell(
                      'Stock Status',
                      widget.stock > 0
                          ? 'In Stock (${widget.stock} left)'
                          : 'Out of Stock',
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              InkWell(
                onTap: () {
                  setState(() {
                    _showAdditionalDetails = !_showAdditionalDetails;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Additional Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Icon(
                      _showAdditionalDetails
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF334155),
                    ),
                  ],
                ),
              ),
              if (_showAdditionalDetails) ...[
                const SizedBox(height: 10),
                Text(
                  widget.description.isNotEmpty
                      ? widget.description
                      : 'Fresh, hygienically packed quality product delivered directly from local partner store in 15 minutes.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Country of Origin: India\n• Dispatch Time: Instant (15-20 Mins)\n• Return Policy: Instant doorstep exchange if damaged',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSizeChip({required String label, required int multiplier}) {
    final bool isSelected = widget.selectedPackMultiplier == multiplier;
    return InkWell(
      onTap: () => widget.onPackMultiplierChanged(multiplier),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00875A)
                : const Color(0xFFCBD5E1),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFF00875A)
                : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
