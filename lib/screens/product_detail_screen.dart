import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
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
    if (maxScroll - currentScroll <= 420) {
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
    final double baseMarketPrice =
        ((data['marketPrice'] ?? basePrice) as num).toDouble();
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

    final List<String> extraImages = [];
    if (data['images'] is List) {
      for (final item in data['images'] as List) {
        if (item != null && item.toString().trim().isNotEmpty) {
          extraImages.add(item.toString().trim());
        }
      }
    }

    int discountPercent = 0;
    if (baseMarketPrice > basePrice && baseMarketPrice > 0) {
      discountPercent =
          (((baseMarketPrice - basePrice) / baseMarketPrice) * 100).round();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
            icon: const Icon(Icons.search_rounded, color: Color(0xFF334155)),
            tooltip: 'Search Products',
            onPressed: () => Navigator.pop(context),
          ),
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. MULTI-SLIDE IMAGE CAROUSEL + LOCATION BAR + LIVE COUNTDOWN
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

                  // 2. PRICE, MALL BADGE, SPECIAL OFFER, SIZE SELECTOR, SELLER & HIGHLIGHTS
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

                  // 3. REAL-TIME PHOTO REVIEWS + SMART RELATED PRODUCTS + CATEGORY & ENDLESS FEED
                  ProductReviewsAndSimilarSection(
                    productId: widget.productId,
                    productName: name,
                    category: category,
                    primaryImageUrl: imageUrl,
                    deliveryLocation: _deliveryLocation,
                    onChangeLocationTap: _changeDeliveryLocationDialog,
                    endlessBatchesCount: _endlessBatchesCount,
                  ),
                ],
              ),
            ),
          ),

          // 4. STICKY DUAL-BUTTON BOTTOM BAR ([Add to Cart] + [Buy Now])
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Consumer<CartProvider>(
                builder: (context, cart, child) {
                  final int currentQty =
                      cart.items[widget.productId]?.quantity ?? 0;

                  if (isOutOfStock) {
                    return Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'CURRENTLY OUT OF STOCK',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
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
                                height: 46,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF00875A),
                                    side: const BorderSide(
                                      color: Color(0xFF00875A),
                                      width: 1.6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$name added to Cart!'),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor:
                                            const Color(0xFF00875A),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 19,
                                  ),
                                  label: const Text(
                                    'Add to Cart',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF00875A),
                                    width: 1.6,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_rounded,
                                        color: Color(0xFF00875A),
                                      ),
                                      onPressed: () => cart
                                          .removeSingleItem(widget.productId),
                                    ),
                                    Text(
                                      '$currentQty in Cart',
                                      style: const TextStyle(
                                        color: Color(0xFF00875A),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    IconButton(
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00875A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
                              size: 19,
                            ),
                            label: const Text(
                              'Buy Now',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5,
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
    );
  }
}