import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
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

  // Live Location State
  Position? _currentCustomerPosition;
  bool _isFetchingLocation = false;

  final TextEditingController _instructionController = TextEditingController();
  final ScrollController _scrollController = ScrollController(keepScrollOffset: true);

  @override
  void initState() {
    super.initState();
    _fetchLiveCustomerLocation();
  }

  @override
  void dispose() {
    _instructionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 1. GPS Live Location Fetcher Helper
  Future<void> _fetchLiveCustomerLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isFetchingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isFetchingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isFetchingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _currentCustomerPosition = pos;
        _isFetchingLocation = false;
      });
    } catch (e) {
      debugPrint("Error fetching customer live location: $e");
      setState(() => _isFetchingLocation = false);
    }
  }

  // Safe Navigation Handler using /home
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

  // 6-digit Numeric Order ID Generator
  String _generateNumericOrderId() {
    final random = Random();
    int number = 100000 + random.nextInt(900000);
    return number.toString();
  }

  // Helper Widget for Rendering Base64 & Network Images
  Widget _buildProductImage(String? imageStr) {
    if (imageStr == null || imageStr.trim().isEmpty) {
      return Icon(Icons.shopping_bag_outlined, size: 24, color: Colors.green.shade400);
    }

    if (!imageStr.startsWith('http://') && !imageStr.startsWith('https://')) {
      try {
        final cleanBase64 = imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        final bytes = base64Decode(cleanBase64.trim());
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.shopping_bag_outlined, size: 24, color: Colors.green.shade400),
        );
      } catch (e) {
        return Icon(Icons.shopping_bag_outlined, size: 24, color: Colors.green.shade400);
      }
    }

    return Image.network(
      imageStr,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(Icons.shopping_bag_outlined, size: 24, color: Colors.green.shade400),
    );
  }

  // 2. ORDER SUMMARY BOTTOM SHEET WITH ACCEPT / RECHECK BUTTONS
  void _showOrderSummaryBottomSheet(CartProvider cartProvider) {
    final cartItems = cartProvider.items.values.toList();
    final double itemTotal = cartProvider.totalAmount;
    final double deliveryFee = itemTotal > 200 || itemTotal == 0 ? 0.0 : 25.0;
    final double handlingFee = itemTotal > 0 ? 5.0 : 0.0;
    final double grandTotal = itemTotal + deliveryFee + handlingFee;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sheet Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Summary Review',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),

                    // Live Location Recheck Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.my_location_rounded, color: Color(0xFF2563EB), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Delivery Live GPS Location',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: _isFetchingLocation
                                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.refresh_rounded, size: 14),
                                label: const Text('Re-check', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  setModalState(() => _isFetchingLocation = true);
                                  await _fetchLiveCustomerLocation();
                                  setModalState(() => _isFetchingLocation = false);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currentCustomerPosition != null
                                ? 'Lat: ${_currentCustomerPosition!.latitude.toStringAsFixed(5)}, Long: ${_currentCustomerPosition!.longitude.toStringAsFixed(5)}'
                                : 'Fetching live location coordinates...',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Items List
                    const Text('Items in Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...cartItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.quantity}x ${item.name}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        )),
                    const Divider(height: 20),

                    // Bill Summary
                    _buildBillRow('Item Total', '₹${itemTotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 4),
                    _buildBillRow('Delivery Charge', deliveryFee == 0 ? 'FREE' : '₹${deliveryFee.toStringAsFixed(2)}', isFree: deliveryFee == 0),
                    const SizedBox(height: 4),
                    _buildBillRow('Handling Fee', '₹${handlingFee.toStringAsFixed(2)}'),
                    const Divider(height: 16),
                    _buildBillRow('Grand Total', '₹${grandTotal.toStringAsFixed(2)}', isBold: true),

                    const SizedBox(height: 20),

                    // Cancel & Accept Confirmation Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('CANCEL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00875A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            label: const Text('CONFIRM & PLACE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _placeOrder(cartProvider);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 3. Safe Order Placement Function with Customer GeoPoint Sync
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
      final double deliveryFee = itemTotal > 200 ? 0.0 : 25.0;
      final double handlingFee = 5.0;
      final double grandTotal = itemTotal + deliveryFee + handlingFee;

      final String numericOrderId = _generateNumericOrderId();

      String extractedMerchantId = '';
      String extractedStoreName = '';

      if (cartProvider.items.isNotEmpty) {
        final firstItem = cartProvider.items.values.first;
        final String productId = firstItem.id;

        try {
          final productDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();

          if (productDoc.exists && productDoc.data() != null) {
            final pData = productDoc.data()!;
            extractedMerchantId = (pData['merchantId'] ?? pData['merchantUid'] ?? pData['vendorId'] ?? '').toString();
            extractedStoreName = (pData['storeName'] ?? pData['shopName'] ?? '').toString();
          }

          if (extractedMerchantId.isNotEmpty && extractedStoreName.isEmpty) {
            final merchantDoc = await FirebaseFirestore.instance.collection('merchants').doc(extractedMerchantId).get();
            if (merchantDoc.exists && merchantDoc.data() != null) {
              final mData = merchantDoc.data()!;
              extractedStoreName = (mData['storeName'] ?? mData['shopName'] ?? mData['name'] ?? mData['businessName'] ?? '').toString();
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

      final String finalAddress = widget.selectedAddress ?? 'No Delivery Address Provided';

      // Customer Live GPS Location Conversion to GeoPoint
      GeoPoint? customerGeoPoint;
      if (_currentCustomerPosition != null) {
        customerGeoPoint = GeoPoint(_currentCustomerPosition!.latitude, _currentCustomerPosition!.longitude);
      }

      // Firestore Order Collection Entry with Customer GeoPoint
      await FirebaseFirestore.instance.collection('orders').doc(numericOrderId).set({
        'orderId': numericOrderId,
        'userId': currentUser.uid,
        'userPhone': currentUser.phoneNumber ?? '',
        'merchantId': extractedMerchantId,
        'storeName': extractedStoreName,
        'items': orderItems,
        'itemTotal': itemTotal,
        'deliveryFee': deliveryFee,
        'handlingFee': handlingFee,
        'grandTotal': grandTotal,
        'deliveryAddress': finalAddress,
        'customerLocation': customerGeoPoint, // 🚀 Delivery Partner App Map Indicator LatLongs
        'userLocation': customerGeoPoint,
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

      setState(() => _isPlacingOrder = false);
      _showSuccessDialog(numericOrderId);
    } catch (e) {
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ఆర్డర్ ప్లేస్ చేయడంలో లోపం: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF00875A), size: 60),
            SizedBox(height: 10),
            Text(
              'Order Placed Successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'మీ ఆర్డర్ విజయవంతంగా నమోదైంది.\nOrder ID: #$orderId',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00875A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayAddress = (widget.selectedAddress != null && widget.selectedAddress!.isNotEmpty)
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
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            tooltip: 'Back',
            onPressed: _handleBackNavigation,
          ),
        ),
        body: Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            if (cartProvider.items.isEmpty) {
              return const Center(child: Text('మీ కార్ట్ ఖాళీగా ఉంది.'));
            }

            final cartItems = cartProvider.items.values.toList();
            final double itemTotal = cartProvider.totalAmount;
            final double deliveryFee = itemTotal > 200 || itemTotal == 0 ? 0.0 : 25.0;
            final double handlingFee = itemTotal > 0 ? 5.0 : 0.0;
            final double grandTotal = itemTotal + deliveryFee + handlingFee;

            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                key: const ValueKey('checkout_column'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DELIVERY ADDRESS SUMMARY
                  _buildSectionCard(
                    title: 'Delivery Address',
                    icon: Icons.location_on,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayAddress,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.bolt, size: 14, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              'Delivery in 15 mins',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. ORDER SUMMARY LIST
                  _buildSectionCard(
                    title: 'Order Summary (${cartItems.length} Items)',
                    icon: Icons.shopping_bag_outlined,
                    child: ListView.separated(
                      key: const PageStorageKey('cart_items_list'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Row(
                          key: ValueKey(item.id),
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
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
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(item.unit, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00875A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => cartProvider.removeSingleItem(item.id),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Icon(Icons.remove, size: 16, color: Color(0xFF00875A)),
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00875A)),
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
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Icon(Icons.add, size: 16, color: Color(0xFF00875A)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3. DELIVERY INSTRUCTIONS
                  _buildSectionCard(
                    title: 'Delivery Instructions (Optional)',
                    icon: Icons.note_alt_outlined,
                    child: TextField(
                      controller: _instructionController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Leave at door, Don\'t ring bell...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4. PAYMENT METHOD SELECTOR
                  _buildSectionCard(
                    title: 'Payment Method',
                    icon: Icons.payment,
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'COD',
                          groupValue: _selectedPaymentMethod,
                          activeColor: const Color(0xFF00875A),
                          title: const Text('Cash on Delivery / Pay on Delivery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          secondary: const Icon(Icons.money, color: Colors.green),
                          onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                        ),
                        RadioListTile<String>(
                          value: 'UPI',
                          groupValue: _selectedPaymentMethod,
                          activeColor: const Color(0xFF00875A),
                          title: const Text('UPI / GooglePay / PhonePe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          secondary: const Icon(Icons.qr_code_scanner, color: Colors.deepPurple),
                          onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 5. BILL DETAILS
                  _buildSectionCard(
                    title: 'Bill Details',
                    icon: Icons.receipt_long_outlined,
                    child: Column(
                      children: [
                        _buildBillRow('Item Total', '₹${itemTotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildBillRow('Delivery Charge', deliveryFee == 0 ? 'FREE' : '₹${deliveryFee.toStringAsFixed(2)}', isFree: deliveryFee == 0),
                        const SizedBox(height: 8),
                        _buildBillRow('Handling & Packaging Charge', '₹${handlingFee.toStringAsFixed(2)}'),
                        const Divider(height: 20),
                        _buildBillRow('To Pay', '₹${grandTotal.toStringAsFixed(2)}', isBold: true),
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
            final double itemTotal = cartProvider.totalAmount;
            final double deliveryFee = itemTotal > 200 || itemTotal == 0 ? 0.0 : 25.0;
            final double handlingFee = itemTotal > 0 ? 5.0 : 0.0;
            final double grandTotal = itemTotal + deliveryFee + handlingFee;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL PAYABLE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(
                        '₹${grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00875A)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isPlacingOrder ? null : () => _showOrderSummaryBottomSheet(cartProvider),
                        child: _isPlacingOrder
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('PLACE ORDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF00875A)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

  Widget _buildBillRow(String label, String value, {bool isFree = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isFree ? Colors.green : (isBold ? const Color(0xFF00875A) : Colors.black87),
          ),
        ),
      ],
    );
  }
}