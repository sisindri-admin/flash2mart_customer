import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  late Future<Map<String, String>> _merchantFuture;

  @override
  void initState() {
    super.initState();
    _merchantFuture = _fetchMerchantDetails(widget.merchantId);
  }

  @override
  void didUpdateWidget(covariant ProductPriceAndHighlightsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.merchantId != widget.merchantId) {
      _merchantFuture = _fetchMerchantDetails(widget.merchantId);
    }
  }

  Future<Map<String, String>> _fetchMerchantDetails(String merchantId) async {
    if (merchantId.isEmpty) {
      return {
        'storeName': 'Flash2Mart Official Store',
        'location': 'Nellore, Andhra Pradesh',
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
          'location':
              (data['location'] ?? 'Nellore, Andhra Pradesh').toString(),
          'storeImageBase64': (data['storeImageBase64'] ?? '').toString(),
        };
      }
    } catch (_) {}

    return {
      'storeName': 'Flash2Mart Partner Store',
      'location': 'Nellore, Andhra Pradesh',
      'storeImageBase64': '',
    };
  }

  Widget _buildStoreAvatar(String imageStr) {
    if (imageStr.trim().isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.storefront_rounded,
          color: Color(0xFF00875A),
          size: 22,
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
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.storefront_rounded,
              color: Color(0xFF00875A),
              size: 22,
            ),
          ),
        );
      } catch (_) {}
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageStr,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.storefront_rounded,
          color: Color(0xFF00875A),
          size: 22,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double baseMarket = (widget.marketPrice > widget.price &&
            widget.price > 0)
        ? widget.marketPrice
        : (widget.price > 0 ? (widget.price * 1.18).ceilToDouble() : widget.price);

    final double effectivePrice = widget.price * widget.selectedPackMultiplier;
    final double effectiveMarketPrice =
        baseMarket * widget.selectedPackMultiplier;

    int discountPercent = 0;
    if (effectiveMarketPrice > effectivePrice && effectiveMarketPrice > 0) {
      discountPercent =
          (((effectiveMarketPrice - effectivePrice) / effectiveMarketPrice) *
                  100)
              .round()
              .clamp(5, 85);
    }

    final int savedAmount =
        (effectiveMarketPrice - effectivePrice).round().clamp(0, 99999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. CLEAN PRODUCT TITLE + GREEN "% OFF" + PRICE CARD DIRECTLY BELOW IMAGE
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Green "% OFF" Pill + 15 Mins Express Tag right below the product image
              Row(
                children: [
                  if (discountPercent > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Text(
                        '$discountPercent% OFF',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF15803D),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  if (discountPercent > 0) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 14,
                          color: Color(0xFF16A34A),
                        ),
                        SizedBox(width: 2),
                        Text(
                          '15 MINS',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: widget.onWishlistToggle,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        widget.isWishlisted
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 22,
                        color: widget.isWishlisted
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: widget.onShareTap,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.share_outlined,
                        size: 21,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Product Name & Unit
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Net Qty: ${widget.unit}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),

              // Price + Struck-through MRP + Green "% OFF" text
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
                  if (effectiveMarketPrice > effectivePrice) ...[
                    const SizedBox(width: 8),
                    Text(
                      'MRP ₹${effectiveMarketPrice.toInt()}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                        decoration: TextDecoration.lineThrough,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$discountPercent% OFF',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ],
              ),
              if (savedAmount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'You save ₹$savedAmount on this pack (Inclusive of all taxes)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 2. CLEAN PACK QUANTITY SELECTOR
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Pack Size',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildSizeChip(
                    label:
                        '${widget.unit.isNotEmpty ? widget.unit : '1 Pack'} • ₹${widget.price.toInt()}',
                    multiplier: 1,
                  ),
                  _buildSizeChip(
                    label:
                        'Pack of 2 (${widget.unit} x 2) • ₹${(widget.price * 2).toInt()}',
                    multiplier: 2,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 3. COMPACT PRODUCT HIGHLIGHTS & STORE INFO
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<Map<String, String>>(
                future: _merchantFuture,
                builder: (context, snapshot) {
                  final String storeName =
                      snapshot.data?['storeName'] ?? 'Flash2Mart Partner Store';
                  final String location =
                      snapshot.data?['location'] ?? 'Nellore';
                  final String storeImg =
                      snapshot.data?['storeImageBase64'] ?? '';

                  return Row(
                    children: [
                      _buildStoreAvatar(storeImg),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Verified Store • $location',
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
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFF16A34A),
                            ),
                            SizedBox(width: 2),
                            Text(
                              '4.4',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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
                      'Product Information & Details',
                      style: TextStyle(
                        fontSize: 14.5,
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
                      : '100% fresh and quality checked product delivered in 15 minutes.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Category: ${widget.category}  •  Net Qty: ${widget.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
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
                ? const Color(0xFF16A34A)
                : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFF15803D)
                : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
