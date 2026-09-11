import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import 'my_orders_screen.dart'; // 👈 MyOrdersScreen Import

class CheckoutScreen extends StatefulWidget {
  final String selectedAddress;

  const CheckoutScreen({
    super.key,
    required this.selectedAddress,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'COD';
  bool _isPlacingOrder = false;

  final TextEditingController _instructionController = TextEditingController();
  final ScrollController _scrollController = ScrollController(keepScrollOffset: true);

  @override
  void dispose() {
    _instructionController.dispose();
    _scrollController.dispose();
    super.dispose();
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

    // Base64 Image Handling
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

    // Network Image Handling
    return Image.network(
      imageStr,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(Icons.shopping_bag_outlined, size: 24, color: Colors.green.shade400),
    );
  }

  // Order Placement
  Future<void> _placeOrder(CartProvider cartProvider) async {
    if (cartProvider.items.isEmpty) return;

    setState(() => _isPlacingOrder = true);

    try {
      final double itemTotal = cartProvider.totalAmount;
      final double deliveryFee = itemTotal > 200 ? 0.0 : 25.0;
      final double handlingFee = 5.0;
      final double grandTotal = itemTotal + deliveryFee + handlingFee;

      final String numericOrderId = _generateNumericOrderId();

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

      await FirebaseFirestore.instance.collection('orders').doc(numericOrderId).set({
        'orderId': numericOrderId,
        'items': orderItems,
        'itemTotal': itemTotal,
        'deliveryFee': deliveryFee,
        'handlingFee': handlingFee,
        'grandTotal': grandTotal,
        'deliveryAddress': widget.selectedAddress,
        'paymentMethod': _selectedPaymentMethod,
        'paymentStatus': _selectedPaymentMethod == 'COD' ? 'Pending' : 'Paid',
        'orderStatus': 'Pending',
        'deliveryInstructions': _instructionController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
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
            Text('Order Placed Successfully!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                Navigator.of(ctx).pop(); // Close Dialog
                Navigator.of(context).pop(); // Close Checkout Screen

                // Direct Navigation to My Orders Screen 👈
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
                );
              },
              child: const Text('VIEW MY ORDERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Checkout & Bill', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: SingleChildScrollView(
              controller: _scrollController,
              primary: false,
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
                          widget.selectedAddress,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.bolt, size: 14, color: Colors.amber),
                            SizedBox(width: 4),
                            Text('Delivery in 15 mins', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. ORDER SUMMARY LIST WITH WORKING IMAGES
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
                            // Product Image Container (Base64 + Network Image handling)
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
                                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00875A))),
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
            ),
            bottomSheet: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: Row(
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
                        onPressed: _isPlacingOrder ? null : () => _placeOrder(cartProvider),
                        child: _isPlacingOrder
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('PLACE ORDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
        Text(label, style: TextStyle(fontSize: isBold ? 15 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? Colors.black : Colors.grey.shade700)),
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