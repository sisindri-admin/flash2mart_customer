import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../widgets/bottom_order_bar.dart';
import '../widgets/product_detail/product_image_carousel_widget.dart';
import '../widgets/product_detail/product_price_and_highlights_widgets.dart';
import '../widgets/product_detail/product_reviews_and_similar_widgets.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productData,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isWishlisted = false;
  int _selectedPackMultiplier = 1;
  String _deliveryLocation = 'Nellore - 524004';
  int _endlessBatchesCount = 2;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 420 && _endlessBatchesCount < 12) {
      setState(() {
        _endlessBatchesCount += 2;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleWishlist(String productName) {
    setState(() => _isWishlisted = !_isWishlisted);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isWishlisted
              ? '$productName added to your Wishlist ♥'
              : 'Removed from Wishlist',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor:
            _isWishlisted ? const Color(0xFF00875A) : const Color(0xFF334155),
      ),
    );
  }

  void _shareProduct(String name, double price, String unit) {
    final String shareText =
        'Check out $name ($unit) at just ₹${price.toInt()} on Flash2Mart (15 Mins Superfast Delivery in Nellore)!';
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Product share details copied! Ready to paste on WhatsApp.'),
        backgroundColor: Color(0xFF00875A),
      ),
    );
  }

  void _changeDeliveryLocationDialog() {
    final TextEditingController locCtrl =
        TextEditingController(text: _deliveryLocation);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Change Delivery Pincode / Area',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: locCtrl,
          decoration: InputDecoration(
            hintText: 'e.g. Vedayapalem, Nellore - 524004',
            prefixIcon: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF00875A),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00875A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (locCtrl.text.trim().isNotEmpty) {
                setState(() => _deliveryLocation = locCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = widget.productData;
    final String name =
        (data['name'] ?? data['title'] ?? 'Product Details').toString();
    final double basePrice = ((data['price'] ?? 0) as num).toDouble();
    final double rawMarketPrice =
        ((data['marketPrice'] ?? basePrice) as num).toDouble();
    final double baseMarketPrice = (rawMarketPrice > basePrice && basePrice > 0)
        ? rawMarketPrice
        : (basePrice > 0 ? (basePrice * 1.18).ceilToDouble() : basePrice);
    final String unit =
        (data['unit'] ?? data['weight'] ?? '1 unit').toString();
    final String imageUrl = (data['imageUrl'] ??
            data['imageBase64'] ??
            data['image'] ??
            '')
        .toString();
    final String description = (data['description'] ??
            'Fresh and quality grocery products delivered in 15 minutes.')
        .toString();
    final String category =
        (data['category'] ?? 'Grocery / Supermarket').toString();
    final String merchantId = (data['merchantId'] ?? '').toString();
    final int stock = ((data['stock'] ?? 1) as num).toInt();
    final bool isOutOfStock = stock <= 0;

    final bool isCombo = data['isCombo'] == true ||
        data['isComboOffer'] == true ||
        category.toLowerCase().contains('combo');
    final String comboItems = (data['comboItems'] ?? '').toString();
    final List<Map<String, dynamic>> comboProductsList =
        (data['comboProductsList'] is List)
            ? (data['comboProductsList'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : const [];

    final List<String> extraImages = [];
    if (data['images'] is List) {
      for (final item in data['images'] as List) {
        if (item != null && item.toString().trim().isNotEmpty && !extraImages.contains(item.toString().trim())) {
          extraImages.add(item.toString().trim());
        }
      }
    }
    for (final cItem in comboProductsList) {
      final s = (cItem['imageUrl'] ?? cItem['imageBase64'] ?? '').toString().trim();
      if (s.isNotEmpty && !extraImages.contains(s)) {
        extraImages.add(s);
      }
    }

    int discountPercent = 0;
    if (baseMarketPrice > basePrice && baseMarketPrice > 0) {
      discountPercent =
          (((baseMarketPrice - basePrice) / baseMarketPrice) * 100)
              .round()
              .clamp(5, 85);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isWishlisted
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _isWishlisted
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF334155),
            ),
            tooltip: 'Wishlist',
            onPressed: () => _toggleWishlist(name),
          ),
          Selector<CartProvider, int>(
            selector: (context, cart) => cart.totalQuantity,
            builder: (context, totalQty, child) {
              return IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CheckoutScreen(selectedAddress: _deliveryLocation),
                    ),
                  );
                },
                icon: Badge(
                  isLabelVisible: totalQty > 0,
                  backgroundColor: const Color(0xFF00875A),
                  label: Text(
                    '$totalQty',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Color(0xFF334155),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      // Stack so the floating ₹199 badge, compact Cart badge, and Add/Buy pill hover over the screen!
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. MULTI-SLIDE IMAGE CAROUSEL
                  ProductImageCarouselWidget(
                    productId: widget.productId,
                    productName: name,
                    primaryImageUrl: imageUrl,
                    extraImages: extraImages,
                    unit: unit,
                    discountPercent: discountPercent,
                    deliveryLocation: _deliveryLocation,
                    onChangeLocationTap: _changeDeliveryLocationDialog,
                  ),

                  // 1B. COMBO PRODUCTS BREAKDOWN (Expandable / ">" Details Card)
                  if (isCombo && (comboProductsList.isNotEmpty || comboItems.isNotEmpty))
                    _ComboDetailsBreakdownCard(
                      comboProductsList: comboProductsList,
                      comboItemsSummary: comboItems,
                      totalComboPrice: basePrice,
                      totalActualMrp: baseMarketPrice,
                    ),

                  // 2. CLEAN PRICE + GREEN "% OFF" + PACK SIZE + STORE DETAILS
                  ProductPriceAndHighlightsSection(
                    productId: widget.productId,
                    name: name,
                    price: basePrice,
                    marketPrice: baseMarketPrice,
                    unit: unit,
                    category: category,
                    description: description,
                    merchantId: merchantId,
                    stock: stock,
                    isWishlisted: _isWishlisted,
                    onWishlistToggle: () => _toggleWishlist(name),
                    onShareTap: () => _shareProduct(name, basePrice, unit),
                    selectedPackMultiplier: _selectedPackMultiplier,
                    onPackMultiplierChanged: (mult) {
                      setState(() => _selectedPackMultiplier = mult);
                    },
                  ),

                  // 3. ZERO-BLINK REVIEWS + SIMILAR & RELATED PRODUCTS
                  ProductReviewsAndSimilarSection(
                    productId: widget.productId,
                    productName: name,
                    category: category,
                    primaryImageUrl: imageUrl,
                    deliveryLocation: _deliveryLocation,
                    onChangeLocationTap: _changeDeliveryLocationDialog,
                    endlessBatchesCount: _endlessBatchesCount,
                  ),
                  const SizedBox(height: 190),
                ],
              ),
            ),
          ),

          // HOVERING BOTTOM OVERLAY (Shop for ₹199 + Compact Cart Badge + Add/Buy Pill)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Selector<CartProvider, int>(
                    selector: (context, cart) => cart.totalQuantity,
                    builder: (context, totalQty, child) {
                      if (totalQty <= 0) return const SizedBox.shrink();
                      final cartProvider =
                          Provider.of<CartProvider>(context, listen: false);
                      return BottomOrderBar(
                        totalQuantity: totalQty,
                        totalAmount: cartProvider.totalAmount,
                        selectedAddress: _deliveryLocation,
                        onViewCartPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(
                                selectedAddress: _deliveryLocation,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Floating Add to Cart / Buy Now Pill Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFAFFFFFF),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Consumer<CartProvider>(
                        builder: (context, cart, child) {
                          final int currentQty =
                              cart.items[widget.productId]?.quantity ?? 0;

                          if (isOutOfStock) {
                            return Container(
                              width: double.infinity,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: Text(
                                  'CURRENTLY OUT OF STOCK',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: currentQty == 0
                                    ? SizedBox(
                                        height: 42,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF00875A),
                                            side: const BorderSide(
                                              color: Color(0xFF00875A),
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                            ),
                                          ),
                                          onPressed: () {
                                            for (int i = 0;
                                                i < _selectedPackMultiplier;
                                                i++) {
                                              cart.addItem(
                                                id: widget.productId,
                                                name: name,
                                                price: basePrice,
                                                unit: unit,
                                                imageUrl: imageUrl,
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.shopping_cart_outlined,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Add to Cart',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDF4),
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          border: Border.all(
                                            color: const Color(0xFF00875A),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(
                                                Icons.remove_rounded,
                                                color: Color(0xFF00875A),
                                              ),
                                              onPressed: () =>
                                                  cart.removeSingleItem(
                                                widget.productId,
                                              ),
                                            ),
                                            Text(
                                              '$currentQty in Cart',
                                              style: const TextStyle(
                                                color: Color(0xFF00875A),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 13,
                                              ),
                                            ),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(
                                                Icons.add_rounded,
                                                color: Color(0xFF00875A),
                                              ),
                                              onPressed: () => cart.addItem(
                                                id: widget.productId,
                                                name: name,
                                                price: basePrice,
                                                unit: unit,
                                                imageUrl: imageUrl,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 42,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00875A),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (currentQty == 0) {
                                        for (int i = 0;
                                            i < _selectedPackMultiplier;
                                            i++) {
                                          cart.addItem(
                                            id: widget.productId,
                                            name: name,
                                            price: basePrice,
                                            unit: unit,
                                            imageUrl: imageUrl,
                                          );
                                        }
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CheckoutScreen(
                                            selectedAddress: _deliveryLocation,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.double_arrow_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Buy Now',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComboDetailsBreakdownCard extends StatefulWidget {
  final List<Map<String, dynamic>> comboProductsList;
  final String comboItemsSummary;
  final double totalComboPrice;
  final double totalActualMrp;

  const _ComboDetailsBreakdownCard({
    required this.comboProductsList,
    required this.comboItemsSummary,
    required this.totalComboPrice,
    required this.totalActualMrp,
  });

  @override
  State<_ComboDetailsBreakdownCard> createState() => _ComboDetailsBreakdownCardState();
}

class _ComboDetailsBreakdownCardState extends State<_ComboDetailsBreakdownCard> {
  bool _isExpanded = true;

  Widget _buildItemThumb(String imgStr) {
    final trimmed = imgStr.trim();
    if (trimmed.isEmpty) {
      return const Icon(Icons.local_offer_rounded, color: Color(0xFF7C3AED), size: 20);
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(trimmed, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.grey));
    }
    try {
      final clean = trimmed.contains(',') ? trimmed.split(',').last : trimmed;
      return Image.memory(base64Decode(clean.trim()), fit: BoxFit.cover);
    } catch (_) {
      return const Icon(Icons.image, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    int highlightIdx = -1;
    double highestVal = -1;
    for (int i = 0; i < widget.comboProductsList.length; i++) {
      final item = widget.comboProductsList[i];
      final double act = ((item['actualPrice'] ?? 0) as num).toDouble();
      final double off = ((item['offerPrice'] ?? 0) as num).toDouble();
      if (off == 0 && act > 0) {
        highlightIdx = i;
        break;
      }
      if (act > highestVal) {
        highestVal = act;
        highlightIdx = i;
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer_rounded, color: Color(0xFF7C3AED), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.comboProductsList.isNotEmpty
                              ? "Combo Products Details (${widget.comboProductsList.length} Items)"
                              : "Combo Products Details",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4C1D95),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded,
                  color: const Color(0xFF7C3AED),
                  size: 22,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 16),
            if (widget.comboProductsList.isNotEmpty)
              ...widget.comboProductsList.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final iName = (item['name'] ?? 'Item').toString();
                final iQty = (item['quantity'] ?? item['qty'] ?? '1 pack').toString();
                final double iActual = ((item['actualPrice'] ?? 0) as num).toDouble();
                final double iOffer = ((item['offerPrice'] ?? 0) as num).toDouble();
                final String iImg = (item['imageUrl'] ?? item['imageBase64'] ?? '').toString();
                final bool isHighlighted = idx == highlightIdx;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isHighlighted ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 44,
                          height: 44,
                          color: const Color(0xFFF8FAFC),
                          child: _buildItemThumb(iImg),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$iQty $iName",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            if (isHighlighted)
                              Text(
                                iOffer == 0 ? "✨ FREE Bonus Item in Combo!" : "🔥 Highest Value Item",
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED)),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (iActual > iOffer) ...[
                            Text(
                              "₹${iActual.toInt()}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            iOffer == 0 ? "₹0 FREE" : "₹${iOffer.toInt()}",
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: iOffer == 0 ? const Color(0xFF16A34A) : const Color(0xFF4C1D95),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              })
            else
              Text(
                widget.comboItemsSummary,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.4),
              ),
            if (widget.totalActualMrp > widget.totalComboPrice)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Combo Savings:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF166534))),
                    Text(
                      "Save ₹${(widget.totalActualMrp - widget.totalComboPrice).toInt()} on this Combo!",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
