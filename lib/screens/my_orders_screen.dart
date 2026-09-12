import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _showOnlyHistory = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          _showOnlyHistory ? 'Order History' : 'Active Tracked Orders',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF00875A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showOnlyHistory ? Icons.assignment : Icons.history),
            tooltip: _showOnlyHistory ? 'Show Active Orders' : 'Order History',
            onPressed: () {
              setState(() {
                _showOnlyHistory = !_showOnlyHistory;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00875A)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyOrdersView();
          }

          final allOrders = snapshot.data!.docs;
          final filteredOrders = allOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'pending').toString().toLowerCase();
            if (_showOnlyHistory) {
              return status == 'delivered' || status == 'cancelled';
            } else {
              return status != 'delivered' && status != 'cancelled';
            }
          }).toList();

          if (filteredOrders.isEmpty) {
            return Center(
              child: Text(
                _showOnlyHistory ? 'గత ఆర్డర్లు ఏవీ లేవు.' : 'యాక్టివ్ ఆర్డర్లు ఏవీ లేవు.',
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final orderData = filteredOrders[index].data() as Map<String, dynamic>;
              final orderId = filteredOrders[index].id;
              return _buildAdvancedOrderCard(orderId, orderData);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyOrdersView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF00875A).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Color(0xFF00875A),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Orders Found!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOrderCard(String orderId, Map<String, dynamic> data) {
    final String status = data['status'] ?? 'Pending';
    final List items = data['items'] ?? [];

    // 1. Price Calculations
    double calculatedItemsTotal = 0.0;
    int totalItemCount = 0;

    for (var item in items) {
      final int qty = (item['quantity'] ?? 1) as int;
      final double price = ((item['price'] ?? 0) as num).toDouble();
      calculatedItemsTotal += (price * qty);
      totalItemCount += qty;
    }

    final double subtotal = data['subtotal'] != null
        ? ((data['subtotal']) as num).toDouble()
        : calculatedItemsTotal;

    final double deliveryFee = ((data['deliveryFee'] ?? 0) as num).toDouble();
    final double taxes = ((data['taxes'] ?? 5) as num).toDouble();
    final double totalAmount = subtotal + deliveryFee + taxes;

    // 2. Payment Method Info
    final String rawPaymentMethod = (
      data['paymentMethod'] ?? 
      data['payment_method'] ?? 
      data['paymentType'] ?? 
      'COD'
    ).toString().toLowerCase();

    final bool isCOD = rawPaymentMethod.contains('cod') || rawPaymentMethod.contains('cash');
    final String paymentMethodDisplay = isCOD ? 'CASH ON DELIVERY' : 'ONLINE PAYMENT';
    final String paymentStatus = data['paymentStatus'] ?? (isCOD ? 'Pending' : 'Paid');

    final String shopDistance = data['shopToCustomerDistance'] ?? '2.4 km';
    final String estimatedTime = data['estimatedDeliveryTime'] ?? '15-20 Mins';

    final Map<String, dynamic>? deliveryBoy = data['deliveryPartner'];
    final String partnerName = deliveryBoy?['name'] ?? 'Ramesh Kumar';
    final String partnerPhone = deliveryBoy?['phone'] ?? '+919876543210';
    final String partnerRating = deliveryBoy?['rating'] ?? '4.8';
    final String partnerPhoto = deliveryBoy?['photoUrl'] ?? '';

    final Timestamp? timestamp = data['createdAt'] as Timestamp?;
    final String dateStr = timestamp != null
        ? "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} at ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
        : "Recently";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Live Status Banner
              _buildLiveStatusBanner(status, estimatedTime),

              // 2. Order ID & Payment Badge
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length).toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                    _buildPaymentBadge(paymentMethodDisplay, paymentStatus, isCOD),
                  ],
                ),
              ),

              // 3. Step Progress Bar
              if (status.toLowerCase() != 'delivered' && status.toLowerCase() != 'cancelled')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: _buildProgressTimeline(status),
                ),

              const Divider(height: 16),

              // 4. Real Database Store Name Fetching Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront, color: Color(0xFF00875A), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStoreNameWidget(data, shopDistance, estimatedTime),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 5. Ordered Items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ITEMS ($totalItemCount)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...items.map((item) {
                      final itemName = item['name'] ?? 'Product';
                      final qty = item['quantity'] ?? 1;
                      final price = ((item['price'] ?? 0) as num).toDouble();
                      final itemTotal = price * qty;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '$itemName x $qty',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '₹$price x $qty = ₹${itemTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 6. Complete Bill Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    title: const Text(
                      'Bill Details & Payment Info',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00875A)),
                    ),
                    children: [
                      _buildBillRow('Item Total ($totalItemCount items)', subtotal),
                      _buildBillRow('Delivery Fee', deliveryFee),
                      _buildBillRow('Taxes & Charges', taxes),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00875A)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 7. Delivery Partner Card
              if (status.toLowerCase() != 'delivered' && status.toLowerCase() != 'cancelled')
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00875A).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00875A).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: partnerPhoto.isNotEmpty ? NetworkImage(partnerPhoto) : null,
                          child: partnerPhoto.isEmpty
                              ? const Icon(Icons.person, color: Colors.grey, size: 20)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                partnerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 11, color: Colors.amber),
                                  Text(
                                    ' $partnerRating • Delivery Partner',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone, color: Color(0xFF00875A), size: 20),
                          onPressed: () async {
                            final Uri launchUri = Uri(scheme: 'tel', path: partnerPhone);
                            if (await canLaunchUrl(launchUri)) {
                              await launchUrl(launchUri);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.map, color: Colors.blue, size: 20),
                          tooltip: 'Live Map Location',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opening Live Map Location...')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Merchant Store Name డిస్‌ప్లే చేసే ఫంక్షన్
  Widget _buildStoreNameWidget(Map<String, dynamic> orderData, String distance, String time) {
    // 1. Order Document లోనే storeName ఉందేమో చూడడం
    final String directStoreName = orderData['storeName'] ?? 
        orderData['store_name'] ?? 
        orderData['merchantName'] ?? 
        orderData['shopName'] ?? 
        '';

    if (directStoreName.isNotEmpty) {
      return _buildStoreDetailWidget(directStoreName, distance, time);
    }

    // 2. Merchant ID (UID) తీసుకోవడం
    final String merchantUid = (orderData['merchantId'] ?? 
        orderData['merchant_id'] ?? 
        orderData['merchantUid'] ?? 
        orderData['uid'] ?? 
        '').toString();

    if (merchantUid.isEmpty) {
      return _buildStoreDetailWidget('Vinayaka Store', distance, time);
    }

    // 3. Firestore merchants collection నుండి real storeName తేవడం
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('merchants').doc(merchantUid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStoreDetailWidget('Loading Store...', distance, time);
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final merchantData = snapshot.data!.data() as Map<String, dynamic>?;
          final String realStoreName = merchantData?['storeName'] ?? 
              merchantData?['shopName'] ?? 
              'Vinayaka Store';

          return _buildStoreDetailWidget(realStoreName, distance, time);
        }

        return _buildStoreDetailWidget('Vinayaka Store', distance, time);
      },
    );
  }

  Widget _buildStoreDetailWidget(String storeName, String distance, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          storeName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Text(
          'Distance: $distance • Delivery in $time',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLiveStatusBanner(String status, String time) {
    String message = "Processing your order...";
    IconData icon = Icons.timer_sharp;
    Color color = Colors.orange;

    switch (status.toLowerCase()) {
      case 'placed':
      case 'pending':
        message = "Order Received • Waiting for Shop Confirmation";
        icon = Icons.receipt_long;
        color = Colors.orange.shade800;
        break;
      case 'preparing':
        message = "Shop is Packing your Items";
        icon = Icons.soup_kitchen;
        color = Colors.blue.shade700;
        break;
      case 'on the way':
      case 'out for delivery':
        message = "Arriving in $time • Delivery Partner on the way";
        icon = Icons.delivery_dining;
        color = const Color(0xFF00875A);
        break;
      case 'delivered':
        message = "Order Delivered Successfully!";
        icon = Icons.check_circle;
        color = Colors.green.shade800;
        break;
      case 'cancelled':
        message = "Order Cancelled";
        icon = Icons.cancel;
        color = Colors.red.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          if (status.toLowerCase() != 'delivered' && status.toLowerCase() != 'cancelled')
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
        ],
      ),
    );
  }

  Widget _buildProgressTimeline(String status) {
    int currentStep = 1;
    final statusLower = status.toLowerCase();

    if (statusLower == 'preparing') currentStep = 2;
    if (statusLower == 'on the way' || statusLower == 'out for delivery') currentStep = 3;
    if (statusLower == 'delivered') currentStep = 4;

    return Row(
      children: [
        _buildTimelineStep("Placed", currentStep >= 1),
        _buildTimelineLine(currentStep >= 2),
        _buildTimelineStep("Preparing", currentStep >= 2),
        _buildTimelineLine(currentStep >= 3),
        _buildTimelineStep("On Way", currentStep >= 3),
        _buildTimelineLine(currentStep >= 4),
        _buildTimelineStep("Delivered", currentStep >= 4),
      ],
    );
  }

  Widget _buildTimelineStep(String label, bool isDone) {
    return Column(
      children: [
        CircleAvatar(
          radius: 8,
          backgroundColor: isDone ? const Color(0xFF00875A) : Colors.grey.shade300,
          child: isDone
              ? const Icon(Icons.check, size: 10, color: Colors.white)
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            color: isDone ? const Color(0xFF00875A) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 12),
        color: isDone ? const Color(0xFF00875A) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildPaymentBadge(String methodTitle, String status, bool isCOD) {
    final Color bgColor = isCOD ? Colors.orange.shade50 : Colors.blue.shade50;
    final Color borderCol = isCOD ? Colors.orange.shade300 : Colors.blue.shade300;
    final Color txtCol = isCOD ? Colors.orange.shade900 : Colors.blue.shade900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            methodTitle,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: txtCol,
            ),
          ),
          Text(
            'Status: ${status.toUpperCase()}',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: status.toLowerCase() == 'paid' ? Colors.green.shade800 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String title, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}