import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  // Base64 & Network Image Handler
  Widget _buildProductImage(String? imageStr) {
    if (imageStr == null || imageStr.trim().isEmpty) {
      return Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.green.shade400);
    }

    if (!imageStr.startsWith('http://') && !imageStr.startsWith('https://')) {
      try {
        final cleanBase64 = imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        final bytes = base64Decode(cleanBase64.trim());
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.green.shade400),
        );
      } catch (e) {
        return Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.green.shade400);
      }
    }

    return Image.network(
      imageStr,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.green.shade400),
    );
  }

  // Status Badge Helper
  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'accepted':
        color = Colors.blue;
        break;
      case 'out for delivery':
        color = Colors.orange;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.amber.shade800; // Pending
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00875A)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading orders: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No orders found!', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final String orderId = order['orderId'] ?? '';
              final String orderStatus = order['orderStatus'] ?? 'Pending';
              final double grandTotal = (order['grandTotal'] ?? 0.0).toDouble();
              final List items = order['items'] ?? [];
              final Timestamp? createdAt = order['createdAt'] as Timestamp?;

              final String dateStr = createdAt != null
                  ? "${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}"
                  : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Order ID & Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              if (dateStr.isNotEmpty)
                                Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          _buildStatusBadge(orderStatus),
                        ],
                      ),
                      const Divider(height: 20),

                      // Order Items List Horizontal Preview
                      Column(
                        children: items.map<Widget>((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: _buildProductImage(item['imageUrl']),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "${item['name']} x ${item['quantity']}",
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "₹${item['totalPrice'] ?? item['price']}",
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const Divider(height: 20),

                      // Footer: Total Amount & Payment Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Payment: ${order['paymentMethod'] ?? 'COD'}",
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Total: ₹${grandTotal.toStringAsFixed(0)}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF00875A)),
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
      ),
    );
  }
}