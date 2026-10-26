import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/order_tracking_model.dart';
import '../../providers/cart_provider.dart';
import '../../screens/checkout_screen.dart';
import '../../screens/order_tracking_screen.dart';

class MyOrderCardWidget extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const MyOrderCardWidget({
    super.key,
    required this.orderId,
    required this.data,
  });

  Widget _buildProductImage(String? imageStr) {
    if (imageStr == null || imageStr.trim().isEmpty) {
      return Container(
        color: Colors.green.shade50,
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 22,
          color: Colors.green.shade600,
        ),
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
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.green.shade50,
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 22,
              color: Colors.green.shade600,
            ),
          ),
        );
      } catch (_) {
        return Container(
          color: Colors.green.shade50,
          child: Icon(
            Icons.shopping_bag_outlined,
            size: 22,
            color: Colors.green.shade600,
          ),
        );
      }
    }

    return Image.network(
      imageStr,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.green.shade50,
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 22,
          color: Colors.green.shade600,
        ),
      ),
    );
  }

  Future<void> _callPartner(BuildContext context, String rawPhone) async {
    final String clean = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return;
    final Uri uri = Uri(scheme: 'tel', path: clean);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not call $clean')),
      );
    }
  }

  void _handleReorder(BuildContext context, OrderTrackingModel model) {
    if (model.items.isEmpty) return;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    int addedCount = 0;
    for (final item in model.items) {
      for (int i = 0; i < item.quantity; i++) {
        cartProvider.addItem(
          id: item.id.isNotEmpty ? item.id : item.name,
          name: item.name,
          price: item.price,
          unit: item.unit,
          imageUrl: item.imageUrl ?? '',
        );
      }
      addedCount += item.quantity;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$addedCount items added to cart for Reorder!'),
        backgroundColor: const Color(0xFF00875A),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(selectedAddress: model.deliveryAddress),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final OrderTrackingModel model = OrderTrackingModel.fromFirestore(orderId, data);

    final int totalItemCount =
        model.items.fold(0, (sum, item) => sum + item.quantity);
    final double discountAmount =
        ((data['discountAmount'] ?? 0) as num).toDouble();

    final bool isCOD = model.paymentMethod.toLowerCase().contains('cod') ||
        model.paymentMethod.toLowerCase().contains('cash');
    final String paymentMethodDisplay =
        isCOD ? 'CASH ON DELIVERY' : 'ONLINE / UPI';

    final String shopDistance =
        (data['shopToCustomerDistance'] ?? '2.2 km').toString();
    final String estimatedTime =
        (data['estimatedDeliveryTime'] ?? '15 Mins').toString();

    final Timestamp? timestamp = data['createdAt'] as Timestamp?;
    final String dateStr = timestamp != null
        ? '${timestamp.toDate().day.toString().padLeft(2, '0')}/${timestamp.toDate().month.toString().padLeft(2, '0')}/${timestamp.toDate().year} • ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
        : 'Recently Placed';

    final bool showOtpBadge = !model.isCancelled &&
        !model.isDelivered &&
        (model.currentStepIndex >= 2 || model.deliveryPartnerId.isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: model.isCancelled
              ? const Color(0xFFFECACA)
              : model.isDelivered
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF86EFAC),
          width: (!model.isCancelled && !model.isDelivered) ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP LIVE STATUS BANNER
          _buildStatusBanner(model),

          // 2. ORDER ID, DATE & PAYMENT BADGE
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${data['orderId'] ?? orderId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                _buildPaymentBadge(
                  paymentMethodDisplay,
                  model.isDelivered ? 'PAID' : model.paymentStatus,
                  isCOD,
                ),
              ],
            ),
          ),

          // 3. 5-STEP PROGRESS BAR FOR ACTIVE ORDERS
          if (!model.isDelivered && !model.isCancelled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: _buildCompactStepBar(model.currentStepIndex),
            ),

          // 4. 4-DIGIT DELIVERY OTP PILL (WHEN ASSIGNED / ON THE WAY)
          if (showOtpBadge)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 6, 14, 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lock_person_rounded,
                        size: 16,
                        color: Color(0xFF1D4ED8),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Delivery OTP (Share at doorstep):',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: model.deliveryOtp));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('OTP copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        model.deliveryOtp.split('').join(' '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 16),

          // 5. STORE HEADER BOX
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    color: Color(0xFF00875A),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StoreInfoLookup(
                      orderData: data,
                      fallbackStoreName: model.storeName,
                      distance: shopDistance,
                      time: estimatedTime,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 6. ORDERED ITEMS LIST
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ITEMS ($totalItemCount)',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                ...model.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: _buildProductImage(item.imageUrl),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${item.quantity} x ₹${item.price.toStringAsFixed(0)} ${item.unit.isNotEmpty ? '(${item.unit})' : ''}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${item.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // 7. EXPANDABLE BILL SUMMARY
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bill Details & Summary',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00875A),
                      ),
                    ),
                    Text(
                      'Total: ₹${model.grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                children: [
                  _buildBillRow('Item Total ($totalItemCount items)', model.itemTotal),
                  if (discountAmount > 0)
                    _buildBillRow(
                      'Coupon Discount',
                      -discountAmount,
                      isDiscount: true,
                    ),
                  _buildBillRow(
                    'Delivery Fee',
                    model.deliveryFee,
                    isFree: model.deliveryFee == 0,
                  ),
                  _buildBillRow('Handling & Packaging', model.handlingFee),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        '₹${model.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Color(0xFF00875A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 8. DYNAMIC DELIVERY PARTNER BAR (ONLY FOR ACTIVE ORDERS WITH ASSIGNED PARTNER)
          if (!model.isDelivered &&
              !model.isCancelled &&
              model.deliveryPartnerId.isNotEmpty)
            _AssignedPartnerMiniCard(
              partnerId: model.deliveryPartnerId,
              fallbackName: model.fallbackPartnerName,
              fallbackPhone: model.fallbackPartnerPhone,
              onCall: (phone) => _callPartner(context, phone),
            ),

          // 9. ACTION BUTTONS (TRACK ORDER + REORDER)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (!model.isDelivered && !model.isCancelled)
                            ? const Color(0xFF00875A)
                            : const Color(0xFFF1F5F9),
                        foregroundColor: (!model.isDelivered && !model.isCancelled)
                            ? Colors.white
                            : const Color(0xFF1E293B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(
                        (!model.isDelivered && !model.isCancelled)
                            ? Icons.location_on_rounded
                            : Icons.receipt_long_rounded,
                        size: 17,
                      ),
                      label: Text(
                        (!model.isDelivered && !model.isCancelled)
                            ? 'TRACK LIVE ORDER'
                            : 'VIEW DETAILS',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderTrackingScreen(orderId: orderId),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (model.isDelivered || model.isCancelled) ...[
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.replay_rounded, size: 17),
                        label: const Text(
                          'REORDER',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () => _handleReorder(context, model),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(OrderTrackingModel model) {
    final Color bgColor = model.isCancelled
        ? const Color(0xFFDC2626)
        : model.isDelivered
            ? const Color(0xFF15803D)
            : const Color(0xFF00875A);

    final IconData icon = model.isCancelled
        ? Icons.cancel_rounded
        : model.isDelivered
            ? Icons.check_circle_rounded
            : Icons.delivery_dining_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      color: bgColor,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${model.displayStatus} • ${model.statusSubtitle}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!model.isDelivered && !model.isCancelled)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactStepBar(int currentStepIndex) {
    const List<String> labels = [
      'Placed',
      'Preparing',
      'Packed',
      'On Way',
      'Delivered',
    ];

    return Row(
      children: List.generate(labels.length * 2 - 1, (idx) {
        if (idx.isOdd) {
          final int stepBefore = idx ~/ 2;
          final bool active = stepBefore < currentStepIndex;
          return Expanded(
            child: Container(
              height: 2.5,
              margin: const EdgeInsets.only(bottom: 12),
              color: active ? const Color(0xFF00875A) : const Color(0xFFE2E8F0),
            ),
          );
        }

        final int step = idx ~/ 2;
        final bool isDone = step <= currentStepIndex;
        return Column(
          children: [
            CircleAvatar(
              radius: 7,
              backgroundColor:
                  isDone ? const Color(0xFF00875A) : const Color(0xFFCBD5E1),
              child: isDone
                  ? const Icon(Icons.check, size: 9, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 3),
            Text(
              labels[step],
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                color: isDone
                    ? const Color(0xFF00875A)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPaymentBadge(String methodTitle, String status, bool isCOD) {
    final bool isPaid = status.toLowerCase() == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPaid ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            methodTitle,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          Text(
            'Status: ${status.toUpperCase()}',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: isPaid
                  ? const Color(0xFF15803D)
                  : const Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(
    String title,
    double amount, {
    bool isFree = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          Text(
            isFree
                ? 'FREE'
                : isDiscount
                    ? '-₹${amount.abs().toStringAsFixed(2)}'
                    : '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: (isFree || isDiscount)
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreInfoLookup extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String fallbackStoreName;
  final String distance;
  final String time;

  const _StoreInfoLookup({
    required this.orderData,
    required this.fallbackStoreName,
    required this.distance,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final String directStoreName = (orderData['storeName'] ??
            orderData['store_name'] ??
            orderData['merchantName'] ??
            orderData['shopName'] ??
            '')
        .toString()
        .trim();

    if (directStoreName.isNotEmpty) {
      return _buildLabel(directStoreName);
    }

    final String merchantUid = (orderData['merchantId'] ??
            orderData['merchant_id'] ??
            orderData['merchantUid'] ??
            orderData['vendorId'] ??
            '')
        .toString()
        .trim();

    if (merchantUid.isEmpty) {
      return _buildLabel(fallbackStoreName);
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('merchants')
          .doc(merchantUid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final mData = snapshot.data!.data() as Map<String, dynamic>?;
          final String store = (mData?['storeName'] ??
                  mData?['shopName'] ??
                  mData?['name'] ??
                  fallbackStoreName)
              .toString();
          return _buildLabel(store);
        }
        return _buildLabel(fallbackStoreName);
      },
    );
  }

  Widget _buildLabel(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12.5,
            color: Color(0xFF1E293B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Distance: $distance • Est. $time',
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _AssignedPartnerMiniCard extends StatelessWidget {
  final String partnerId;
  final String fallbackName;
  final String fallbackPhone;
  final ValueChanged<String> onCall;

  const _AssignedPartnerMiniCard({
    required this.partnerId,
    required this.fallbackName,
    required this.fallbackPhone,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('delivery_partners')
          .doc(partnerId)
          .snapshots(),
      builder: (context, snapshot) {
        final Map<String, dynamic> pData =
            (snapshot.data?.data() as Map<String, dynamic>?) ?? {};
        final String name = (pData['fullName'] ??
                pData['name'] ??
                (fallbackName.isNotEmpty ? fallbackName : 'Delivery Partner'))
            .toString();
        final String phone =
            (pData['phone'] ?? pData['phoneNumber'] ?? fallbackPhone).toString();
        final String vehicle =
            (pData['vehicleNumber'] ?? pData['vehicleType'] ?? 'Verified Partner')
                .toString();

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Icon(
                    Icons.delivery_dining_rounded,
                    color: Color(0xFF00875A),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '4.8 ★ • $vehicle',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                if (phone.trim().isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.phone_in_talk_rounded,
                      color: Color(0xFF00875A),
                      size: 20,
                    ),
                    onPressed: () => onCall(phone),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
