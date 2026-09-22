import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

import 'home_screen.dart'; // HomeScreen / MyOrders tab navigation kosam

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  // Direct ga My Orders screen / tab ki velle navigation helper
  void _navigateToMyOrders(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(), // Home screen 1st tab or My Orders view
        ),
      );
    }
  }

  // Phone Call చేసే హెల్పర్ ఫంక్షన్ (డయాల్ ప్యాడ్ కి పంపడానికి)
  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleanNumber.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number not available')),
        );
      }
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open dialer for $cleanNumber')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening dialer: $e')),
        );
      }
    }
  }

  // Base64 మరియు Network Image Helper Widget
  Widget _buildProductImage(String? imageStr) {
    if (imageStr == null || imageStr.trim().isEmpty) {
      return Container(
        color: Colors.green.shade50,
        child: Icon(Icons.shopping_bag_outlined, size: 24, color: Colors.green.shade600),
      );
    }

    if (!imageStr.startsWith('http://') && !imageStr.startsWith('https://')) {
      try {
        final cleanBase64 = imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        final bytes = base64Decode(cleanBase64.trim());
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.green.shade50,
            child: Icon(Icons.shopping_bag_outlined, size: 24, color: Colors.green.shade600),
          ),
        );
      } catch (e) {
        return Container(
          color: Colors.green.shade50,
          child: Icon(Icons.shopping_bag_outlined, size: 24, color: Colors.green.shade600),
        );
      }
    }

    return Image.network(
      imageStr,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.green.shade50,
        child: Icon(Icons.shopping_bag_outlined, size: 24, color: Colors.green.shade600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateToMyOrders(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () => _navigateToMyOrders(context),
          ),
          title: Text(
            'Track Order #$orderId',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0.5,
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  'Order details not found',
                  style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final String currentStatus = (data['currentStatus'] ?? data['orderStatus'] ?? data['status'] ?? 'Placed').toString();
            final List<dynamic> trackingHistory = (data['trackingHistory'] as List<dynamic>?) ?? [];
            final List<dynamic> items = (data['items'] as List<dynamic>?) ?? [];
            final String storeName = data['storeName'] ?? 'Merchant Store';
            final String deliveryAddress = data['deliveryAddress'] ?? 'Standard Delivery';
            
            // Delivery Partner Details
            final Map<String, dynamic>? deliveryPartner = data['deliveryPartner'] as Map<String, dynamic>?;
            final String partnerName = deliveryPartner?['name'] ?? 'Assigning Delivery Partner...';
            
            String partnerPhone = (deliveryPartner?['phone'] ?? data['deliveryPartnerPhone'] ?? data['driverPhone'] ?? '').toString().trim();
            if (partnerPhone.isEmpty) {
              partnerPhone = '9281048287';
            }
            
            final String partnerRating = (deliveryPartner?['rating'] ?? '4.8').toString();
            final String partnerPhoto = deliveryPartner?['photoUrl'] ?? '';
            
            // Live Location LatLng (latlong2)
            LatLng partnerLatLng = const LatLng(14.4426, 79.9865);
            if (data['deliveryPartnerLocation'] is GeoPoint) {
              final GeoPoint loc = data['deliveryPartnerLocation'] as GeoPoint;
              partnerLatLng = LatLng(loc.latitude, loc.longitude);
            } else if (data['driverLocation'] is GeoPoint) {
              final GeoPoint loc = data['driverLocation'] as GeoPoint;
              partnerLatLng = LatLng(loc.latitude, loc.longitude);
            }

            // Bill Breakdown
            final double itemTotal = (data['itemTotal'] ?? data['itemsTotal'] ?? 0).toDouble();
            final double deliveryFee = (data['deliveryFee'] ?? 0).toDouble();
            final double handlingFee = (data['handlingFee'] ?? data['taxes'] ?? 0).toDouble();
            final double grandTotal = (data['grandTotal'] ?? data['totalAmount'] ?? (itemTotal + deliveryFee + handlingFee)).toDouble();
            
            final String paymentMethod = (data['paymentMethod'] ?? 'COD').toString();
            final String paymentStatus = (data['paymentStatus'] ?? 'Pending').toString();

            final bool isCancelled = currentStatus.toLowerCase() == 'cancelled';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. LIVE STATUS HIGHLIGHT CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCancelled ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCancelled ? Colors.redAccent : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Store: $storeName',
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              isCancelled ? Icons.cancel_rounded : Icons.local_shipping_rounded,
                              color: isCancelled ? Colors.redAccent : const Color(0xFF2563EB),
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CURRENT STATUS',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                  Text(
                                    currentStatus.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: isCancelled ? Colors.redAccent : const Color(0xFF2563EB),
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
                  const SizedBox(height: 16),

                  // 2. FREE OPENSTREETMAP LIVE LOCATION & DELIVERY PARTNER CARD
                  if (!isCancelled)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: partnerLatLng,
                                initialZoom: 14.5,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.flash2mart.customer',
                                  tileProvider: CancellableNetworkTileProvider(),
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: partnerLatLng,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 38,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Delivery Partner Profile & CALL BUTTON Card
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFF00875A).withOpacity(0.1),
                                  backgroundImage: partnerPhoto.isNotEmpty ? NetworkImage(partnerPhoto) : null,
                                  child: partnerPhoto.isEmpty
                                      ? const Icon(Icons.person, color: Color(0xFF00875A), size: 24)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        partnerName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                          const SizedBox(width: 2),
                                          Text(
                                            '$partnerRating • Delivery Partner',
                                            style: const TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // CALL OPTION BUTTON
                                InkWell(
                                  onTap: () => _makePhoneCall(partnerPhone, context),
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.phone_in_talk_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 3. REAL-TIME TRACKING TIMELINE
                  const Text(
                    'Order Journey Timeline',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: trackingHistory.isEmpty
                        ? const Text('Tracking details updating...')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: trackingHistory.length,
                            itemBuilder: (context, index) {
                              final step = trackingHistory[index] as Map<String, dynamic>;
                              final String title = step['title'] ?? step['status'] ?? '';
                              final String updatedBy = step['updatedBy'] ?? 'System';
                              final String timestamp = step['timestamp'] ?? '';
                              final bool isLast = index == trackingHistory.length - 1;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF16A34A),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, size: 14, color: Colors.white),
                                      ),
                                      if (!isLast)
                                        Container(
                                          width: 2,
                                          height: 38,
                                          color: const Color(0xFF22C55E),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Updated by $updatedBy',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                          if (timestamp.isNotEmpty)
                                            Text(
                                              timestamp.length > 16 ? timestamp.substring(0, 16).replaceAll('T', ' ') : timestamp,
                                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),

                  // 4. PRODUCTS LIST WITH IMAGES
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Items Ordered',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        ),
                        const Divider(height: 16),
                        ...items.map((item) {
                          final String? imageUrl = item['imageUrl'] ?? item['image'] ?? item['productImage'];
                          final String unit = item['unit'] ?? '';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: _buildProductImage(imageUrl),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] ?? 'Product',
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item['quantity'] ?? 1}x ${unit.isNotEmpty ? '($unit)' : ''}',
                                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${item['totalPrice'] ?? item['price']}',
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. BILL DETAILS & PAYMENT SUMMARY
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bill Details & Payment Info',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        ),
                        const Divider(height: 16),
                        _buildBillRow('Item Total', itemTotal),
                        const SizedBox(height: 6),
                        _buildBillRow('Delivery Fee', deliveryFee, isFree: deliveryFee == 0),
                        const SizedBox(height: 6),
                        _buildBillRow('Handling & Taxes', handlingFee),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand Total Paid:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              '₹${grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payment Method: ${paymentMethod.toUpperCase()}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              Text(
                                'Status: ${paymentStatus.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: paymentStatus.toLowerCase() == 'paid' ? Colors.green : Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. DELIVERY ADDRESS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Address',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 18, color: Color(0xFF2563EB)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                deliveryAddress,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildBillRow(String label, double amount, {bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: Colors.grey),
        ),
        Text(
          isFree ? 'FREE' : '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isFree ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }
}