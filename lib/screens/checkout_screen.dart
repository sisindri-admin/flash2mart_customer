import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../widgets/checkout/checkout_promo_and_bill_widgets.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String? selectedAddress;

  const CheckoutScreen({
    super.key,
    this.selectedAddress,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'COD';
  bool _isPlacingOrder = false;
  CouponOffer? _appliedCoupon;

  final TextEditingController _instructionController = TextEditingController();
  final ScrollController _scrollController = ScrollController(keepScrollOffset: true);

  @override
  void dispose() {
    _instructionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    if (_isPlacingOrder) return;

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    }
  }

  String _generateNumericOrderId() {
    final random = Random();
    int number = 100000 + random.nextInt(900000);
    return number.toString();
  }

  Widget _buildProductImage(String? imageStr) {
    if (imageStr == null || imageStr.trim().isEmpty) {
      return Icon(
        Icons.shopping_bag_outlined,
        size: 24,
        color: Colors.green.shade400,
      );
    }

    if (!imageStr.startsWith('http://') && !imageStr.startsWith('https://')) {
      try {
        final cleanBase64 =
            imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        final bytes = base64Decode(cleanBase64.trim());
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.shopping_bag_outlined,
            size: 24,
            color: Colors.green.shade400,
          ),
        );
      } catch (_) {
        return Icon(
          Icons.shopping_bag_outlined,
          size: 24,
          color: Colors.green.shade400,
        );
      }
    }

    return Image.network(
      imageStr,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.shopping_bag_outlined,
        size: 24,
        color: Colors.green.shade400,
      ),
    );
  }

  Future<void> _placeOrder(CartProvider cartProvider) async {
    if (cartProvider.items.isEmpty) return;

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('దయచేసి ఆర్డర్ చేయడానికి ముందు లాగిన్ అవ్వండి.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final double itemTotal = cartProvider.totalAmount;
      final double discountAmount = _appliedCoupon != null
          ? _appliedCoupon!.calculateDiscount(itemTotal)
          : 0.0;
      final double deliveryFee = itemTotal > 200 ? 0.0 : 25.0;
      final double handlingFee = 5.0;
      final double grandTotal =
          (itemTotal - discountAmount + deliveryFee + handlingFee)
              .clamp(0.0, double.infinity);

      final String numericOrderId = _generateNumericOrderId();
      final String deliveryOtp = (1000 + Random().nextInt(9000)).toString();

      String extractedMerchantId = '';
      String extractedStoreName = '';

      if (cartProvider.items.isNotEmpty) {
        final firstItem = cartProvider.items.values.first;
        final String productId = firstItem.id;

        try {
          final productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();

          if (productDoc.exists && productDoc.data() != null) {
            final pData = productDoc.data()!;
            extractedMerchantId = (pData['merchantId'] ??
                    pData['merchantUid'] ??
                    pData['vendorId'] ??
                    '')
                .toString();
            extractedStoreName =
                (pData['storeName'] ?? pData['shopName'] ?? '').toString();
          }

          if (extractedMerchantId.isNotEmpty && extractedStoreName.isEmpty) {
            final merchantDoc = await FirebaseFirestore.instance
                .collection('merchants')
                .doc(extractedMerchantId)
                .get();
            if (merchantDoc.exists && merchantDoc.data() != null) {
              final mData = merchantDoc.data()!;
              extractedStoreName = (mData['storeName'] ??
                      mData['shopName'] ??
                      mData['name'] ??
                      mData['businessName'] ??
                      '')
                  .toString();
            }
          }
        } catch (e) {
          debugPrint('Error fetching merchant details: $e');
        }
      }

      final orderItems = cartProvider.items.values.map((item) {
        return {
          'id': item.id,
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
          'unit': item.unit,
          'imageUrl': item.imageUrl,
          'totalPrice': item.price * item.quantity,
        };
      }).toList();

      final String finalAddress =
          (widget.selectedAddress != null && widget.selectedAddress!.trim().isNotEmpty)
              ? widget.selectedAddress!.trim()
              : 'Standard Doorstep Delivery';

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(numericOrderId)
          .set({
        'orderId': numericOrderId,
        'deliveryOtp': deliveryOtp,
        'userId': currentUser.uid,
        'userPhone': currentUser.phoneNumber ?? '',
        'merchantId': extractedMerchantId,
        'storeName': extractedStoreName,
        'items': orderItems,
        'itemTotal': itemTotal,
        'couponCode': _appliedCoupon?.code ?? '',
        'discountAmount': discountAmount,
        'deliveryFee': deliveryFee,
        'handlingFee': handlingFee,
        'grandTotal': grandTotal,
        'deliveryAddress': finalAddress,
        'paymentMethod': _selectedPaymentMethod,
        'paymentStatus': _selectedPaymentMethod == 'COD' ? 'Pending' : 'Paid',
        'orderStatus': 'Placed',
        'status': 'Placed',
        'currentStatus': 'Placed',
        'deliveryInstructions': _instructionController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'trackingHistory': [
          {
            'status': 'Placed',
            'title': 'Order Placed Successfully',
            'timestamp': DateTime.now().toIso8601String(),
            'updatedBy': 'Customer',
          }
        ],
      });

      cartProvider.clearCart();

      if (!mounted) return;

      setState(() {
        _isPlacingOrder = false;
        _appliedCoupon = null;
      });
      _showSuccessDialog(numericOrderId, deliveryOtp);
    } catch (e) {
      setState(() => _isPlacingOrder = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ఆర్డర్ ప్లేస్ చేయడంలో లోపం: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String orderId, String deliveryOtp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF00875A), size: 62),
            SizedBox(height: 10),
            Text(
              'Order Placed Successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'మీ ఆర్డర్ విజయవంతంగా నమోదైంది.\nOrder ID: #$orderId',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                'Delivery OTP: $deliveryOtp',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Color(0xFF1D4ED8),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00875A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => OrderTrackingScreen(orderId: orderId),
                  ),
                );
              },
              child: const Text(
                'TRACK LIVE ORDER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayAddress =
        (widget.selectedAddress != null && widget.selectedAddress!.isNotEmpty)
            ? widget.selectedAddress!
            : 'దయచేసి అడ్రస్‌ని ఎంచుకోండి';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Checkout & Bill',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            tooltip: 'Back',
            onPressed: _handleBackNavigation,
          ),
        ),
        body: Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            if (cartProvider.items.isEmpty) {
              return _buildEmptyCartView();
            }

            final cartItems = cartProvider.items.values.toList();
            final double itemTotal = cartProvider.totalAmount;
            final double discountAmount = _appliedCoupon != null
                ? _appliedCoupon!.calculateDiscount(itemTotal)
                : 0.0;
            final double deliveryFee =
                itemTotal > 200 || itemTotal == 0 ? 0.0 : 25.0;
            final double handlingFee = itemTotal > 0 ? 5.0 : 0.0;
            final double grandTotal =
                (itemTotal - discountAmount + deliveryFee + handlingFee)
                    .clamp(0.0, double.infinity);

            final double totalSavings =
                discountAmount + (deliveryFee == 0 && itemTotal > 0 ? 25.0 : 0.0);

            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                key: const ValueKey('checkout_column'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. FREE DELIVERY PROGRESS BANNER
                  CheckoutFreeDeliveryBanner(itemTotal: itemTotal),
                  const SizedBox(height: 14),

                  // 2. DELIVERY ADDRESS SUMMARY
                  _buildSectionCard(
                    title: 'Delivery Address',
                    icon: Icons.location_on_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayAddress,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.bolt_rounded, size: 15, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              'Superfast Delivery in 15 mins',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF00875A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. ORDER SUMMARY LIST
                  _buildSectionCard(
                    title: 'Order Summary (${cartItems.length} Items)',
                    icon: Icons.shopping_bag_outlined,
                    trailing: TextButton(
                      onPressed: () => cartProvider.clearCart(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    child: ListView.separated(
                      key: const PageStorageKey('cart_items_list'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartItems.length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Row(
                          key: ValueKey(item.id),
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildProductImage(item.imageUrl),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    '${item.unit} • ₹${item.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0x1A00875A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => cartProvider.removeSingleItem(item.id),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 16,
                                        color: Color(0xFF00875A),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF00875A),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => cartProvider.addItem(
                                      id: item.id,
                                      name: item.name,
                                      price: item.price,
                                      unit: item.unit,
                                      imageUrl: item.imageUrl,
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 16,
                                        color: Color(0xFF00875A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. APPLY COUPON / PROMO CODE SECTION
                  CheckoutCouponSectionCard(
                    itemTotal: itemTotal,
                    appliedCoupon: _appliedCoupon,
                    onCouponChanged: (coupon) {
                      setState(() => _appliedCoupon = coupon);
                    },
                  ),
                  const SizedBox(height: 14),

                  // 5. DELIVERY INSTRUCTIONS WITH QUICK CHIPS
                  _buildSectionCard(
                    title: 'Delivery Instructions (Optional)',
                    icon: Icons.note_alt_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckoutInstructionQuickChips(
                          controller: _instructionController,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _instructionController,
                          decoration: const InputDecoration(
                            hintText: 'Add custom note for delivery partner...',
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 6. PAYMENT METHOD SELECTOR
                  _buildSectionCard(
                    title: 'Payment Method',
                    icon: Icons.payment_rounded,
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'COD',
                          groupValue: _selectedPaymentMethod,
                          activeColor: const Color(0xFF00875A),
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Cash on Delivery / Pay on Delivery',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          secondary: const Icon(Icons.money, color: Colors.green),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedPaymentMethod = val);
                            }
                          },
                        ),
                        RadioListTile<String>(
                          value: 'UPI',
                          groupValue: _selectedPaymentMethod,
                          activeColor: const Color(0xFF00875A),
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'UPI / GooglePay / PhonePe',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          secondary: const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.deepPurple,
                          ),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedPaymentMethod = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 7. BILL DETAILS
                  _buildSectionCard(
                    title: 'Bill Details',
                    icon: Icons.receipt_long_outlined,
                    child: Column(
                      children: [
                        _buildBillRow('Item Total', '₹${itemTotal.toStringAsFixed(2)}'),
                        if (discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          _buildBillRow(
                            'Coupon Discount (${_appliedCoupon?.code})',
                            '-₹${discountAmount.toStringAsFixed(2)}',
                            isFree: true,
                          ),
                        ],
                        const SizedBox(height: 8),
                        _buildBillRow(
                          'Delivery Charge',
                          deliveryFee == 0
                              ? 'FREE'
                              : '₹${deliveryFee.toStringAsFixed(2)}',
                          isFree: deliveryFee == 0,
                        ),
                        const SizedBox(height: 8),
                        _buildBillRow(
                          'Handling & Packaging Charge',
                          '₹${handlingFee.toStringAsFixed(2)}',
                        ),
                        const Divider(height: 20),
                        _buildBillRow(
                          'To Pay',
                          '₹${grandTotal.toStringAsFixed(2)}',
                          isBold: true,
                        ),
                        if (totalSavings > 0) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🎉 You are saving ₹${totalSavings.toStringAsFixed(0)} on this order!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            if (cartProvider.items.isEmpty) return const SizedBox.shrink();

            final double itemTotal = cartProvider.totalAmount;
            final double discountAmount = _appliedCoupon != null
                ? _appliedCoupon!.calculateDiscount(itemTotal)
                : 0.0;
            final double deliveryFee =
                itemTotal > 200 || itemTotal == 0 ? 0.0 : 25.0;
            final double handlingFee = itemTotal > 0 ? 5.0 : 0.0;
            final double grandTotal =
                (itemTotal - discountAmount + deliveryFee + handlingFee)
                    .clamp(0.0, double.infinity);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL PAYABLE',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF00875A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00875A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isPlacingOrder
                              ? null
                              : () => _placeOrder(cartProvider),
                          child: _isPlacingOrder
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'PLACE ORDER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCartView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0x1400875A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 62,
                color: Color(0xFF00875A),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'మీ కార్ట్ ఖాళీగా ఉంది (Your Cart is Empty)',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add fresh vegetables, fruits & daily groceries to get delivery in 15 mins!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00875A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _handleBackNavigation,
              icon: const Icon(Icons.storefront_rounded, size: 18),
              label: const Text(
                'BROWSE PRODUCTS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: const Color(0xFF00875A)),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 10),
            Material(
              color: Colors.transparent,
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(
    String label,
    String value, {
    bool isFree = false,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: isFree
                ? const Color(0xFF16A34A)
                : (isBold ? const Color(0xFF00875A) : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }
}