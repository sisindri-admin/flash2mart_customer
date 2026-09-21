import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productData,
    required this.productId,
  });

  Widget _buildProductImage(String imageStr) {
    if (imageStr.trim().isEmpty) {
      return Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.green.shade200);
    }

    if (!imageStr.startsWith('http://') && !imageStr.startsWith('https://')) {
      try {
        final cleanBase64 = imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        final bytes = base64Decode(cleanBase64.trim());
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (e) {
        return Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.green.shade200);
      }
    }

    return Image.network(
      imageStr,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.green.shade200),
    );
  }

  // Store Image పై Click చేసినప్పుడు ఫుల్ స్క్రీన్‌లో చూపించే Dialog
  void _showFullStoreImage(BuildContext context, String imageStr, String storeName) {
    if (imageStr.trim().isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    storeName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImageWidget(imageStr, height: 300, fit: BoxFit.contain),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // Common Helper function to render Base64 / Network Store Images
  Widget _buildImageWidget(String imageStr, {double width = double.infinity, double height = 60, BoxFit fit = BoxFit.cover}) {
    if (!imageStr.startsWith('http://') && !imageStr.startsWith('https://')) {
      try {
        final cleanBase64 = imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        final bytes = base64Decode(cleanBase64.trim());
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => const Icon(Icons.storefront, color: Color(0xFF00875A), size: 36),
        );
      } catch (e) {
        return const Icon(Icons.storefront, color: Color(0xFF00875A), size: 36);
      }
    }

    return Image.network(
      imageStr,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => const Icon(Icons.storefront, color: Color(0xFF00875A), size: 36),
    );
  }

  Widget _buildStoreImage(BuildContext context, String imageStr, String storeName) {
    if (imageStr.trim().isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF00875A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.storefront, color: Color(0xFF00875A), size: 32),
      );
    }

    return GestureDetector(
      onTap: () => _showFullStoreImage(context, imageStr, storeName),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 60,
          height: 60,
          color: Colors.white,
          child: _buildImageWidget(imageStr, width: 60, height: 60, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Future<Map<String, String>> _fetchMerchantDetails(String merchantId) async {
    if (merchantId.isEmpty) {
      return {
        'storeName': 'Flash2Mart Partner Store',
        'location': 'Local Store, Nellore',
        'ownerName': 'Verified Partner',
        'storeImageBase64': '',
      };
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('merchants').doc(merchantId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'storeName': (data['storeName'] ?? 'Flash2Mart Store').toString(),
          'location': (data['location'] ?? 'Nellore, Andhra Pradesh').toString(),
          'ownerName': (data['ownerName'] ?? 'Verified Merchant').toString(),
          'storeImageBase64': (data['storeImageBase64'] ?? '').toString(),
        };
      }
    } catch (e) {
      debugPrint("Error fetching merchant data: $e");
    }

    return {
      'storeName': 'Flash2Mart Partner Store',
      'location': 'Nellore, Andhra Pradesh',
      'ownerName': 'Verified Merchant',
      'storeImageBase64': '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final String name = productData['name'] ?? productData['title'] ?? 'Product Details';
    final double price = ((productData['price'] ?? 0) as num).toDouble();
    final double marketPrice = ((productData['marketPrice'] ?? price) as num).toDouble();
    final String unit = productData['unit'] ?? productData['weight'] ?? '1 unit';
    final String imageUrl = productData['imageUrl'] ?? productData['imageBase64'] ?? productData['image'] ?? '';
    final String description = productData['description'] ?? 'Fresh and quality grocery products delivered in minutes.';
    final String category = productData['category'] ?? 'Grocery / Supermarket';
    final String merchantId = productData['merchantId'] ?? '';
    final int stock = ((productData['stock'] ?? 1) as num).toInt();
    final bool isOutOfStock = stock <= 0;

    int discountPercent = 0;
    if (marketPrice > price && marketPrice > 0) {
      discountPercent = (((marketPrice - price) / marketPrice) * 100).round();
    }
    final int savingsAmount = (marketPrice - price).round();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          name,
          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PRODUCT IMAGE SHOWCASE
                  Container(
                    height: 260,
                    width: double.infinity,
                    color: Colors.grey.shade50,
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Hero(
                        tag: 'product_image_$productId',
                        child: _buildProductImage(imageUrl),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DELIVERY TIME & DISCOUNT BADGE
                        Row(
                          children: [
                            const Icon(Icons.bolt, color: Color(0xFF00875A), size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              'Delivery in 15 MINS',
                              style: TextStyle(
                                color: Color(0xFF00875A),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            if (discountPercent > 0 && !isOutOfStock)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$discountPercent% OFF',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // PRODUCT NAME & UNIT
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          unit,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 12),

                        // PRICING ROW
                        Row(
                          children: [
                            Text(
                              '₹${price.toInt()}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (marketPrice > price) ...[
                              Text(
                                '₹${marketPrice.toInt()}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (savingsAmount > 0 && !isOutOfStock)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Save ₹$savingsAmount',
                                  style: const TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        const Divider(),
                        const SizedBox(height: 8),

                        // PRODUCT INFORMATION SECTION
                        const Text(
                          'Product Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),

                        FutureBuilder<Map<String, String>>(
                          future: _fetchMerchantDetails(merchantId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: LinearProgressIndicator(color: Color(0xFF00875A)),
                              );
                            }

                            final storeName = snapshot.data?['storeName'] ?? 'Flash2Mart Store';
                            final location = snapshot.data?['location'] ?? 'Nellore, AP';
                            final ownerName = snapshot.data?['ownerName'] ?? 'Merchant';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Merchant Shop Name', storeName),
                                _buildInfoRow('Category', category),
                                _buildInfoRow('Sold By', ownerName),
                                _buildInfoRow('Address', location),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // ENHANCED VERIFIED SELLER CARD (Increased Size & Click to View Image)
                        FutureBuilder<Map<String, String>>(
                          future: _fetchMerchantDetails(merchantId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox.shrink();
                            final storeImgStr = snapshot.data!['storeImageBase64'] ?? '';
                            final storeName = snapshot.data!['storeName'] ?? 'Store';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00875A).withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF00875A).withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  _buildStoreImage(context, storeImgStr, storeName),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          storeName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF00875A),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Verified Seller • 100% Fresh Guarantee',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                        ),
                                        if (storeImgStr.isNotEmpty)
                                          const Padding(
                                            padding: EdgeInsets.only(top: 2),
                                            child: Text(
                                              'Tap image to view full photo',
                                              style: TextStyle(fontSize: 10, color: Colors.grey),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // ABOUT / DESCRIPTION
                        const Text(
                          'About Product',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description.isNotEmpty
                              ? description
                              : 'Fresh and quality grocery products delivered in minutes right to your doorstep.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // STICKY BOTTOM ADD TO CART BAR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Consumer<CartProvider>(
              builder: (context, cart, child) {
                final int currentQty = cart.items[productId]?.quantity ?? 0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          '₹${price.toInt()}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    isOutOfStock
                        ? Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'OUT OF STOCK',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : currentQty == 0
                            ? SizedBox(
                                height: 46,
                                width: 140,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00875A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    cart.addItem(
                                      id: productId,
                                      name: name,
                                      price: price,
                                      unit: unit,
                                      imageUrl: imageUrl,
                                    );
                                  },
                                  child: const Text(
                                    'ADD TO CART',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00875A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: Colors.white),
                                      onPressed: () => cart.removeSingleItem(productId),
                                    ),
                                    Text(
                                      '$currentQty',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: Colors.white),
                                      onPressed: () => cart.addItem(
                                        id: productId,
                                        name: name,
                                        price: price,
                                        unit: unit,
                                        imageUrl: imageUrl,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}