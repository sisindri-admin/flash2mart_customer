import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order_tracking_model.dart';
import '../widgets/order_tracking/live_tracking_map_card.dart';
import '../widgets/order_tracking/order_items_bill_card.dart';
import '../widgets/order_tracking/order_status_stepper_card.dart';
import '../widgets/order_tracking/order_timeline_card.dart';
import 'help_screen.dart';
import 'home_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  bool _isCancelling = false;
  Map<String, dynamic>? _merchantDocData;
  Map<String, dynamic>? _customerDocData;
  String? _lastLoadedMerchantId;
  String? _lastLoadedUserId;

  void _navigateToMyOrders(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number not available yet')),
        );
      }
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open dialer for $cleanNumber')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening dialer: $e')),
        );
      }
    }
  }

  Future<void> _fetchMerchantAndCustomerDetails(
      String merchantId, String userId) async {
    if (merchantId.isNotEmpty && merchantId != _lastLoadedMerchantId) {
      _lastLoadedMerchantId = merchantId;
      try {
        final mDoc = await FirebaseFirestore.instance
            .collection('merchants')
            .doc(merchantId)
            .get();
        if (mDoc.exists && mounted) {
          setState(() {
            _merchantDocData = mDoc.data();
          });
        }
      } catch (_) {}
    }

    if (userId.isNotEmpty && userId != _lastLoadedUserId) {
      _lastLoadedUserId = userId;
      try {
        final cDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(userId)
            .get();
        if (cDoc.exists && mounted) {
          setState(() {
            _customerDocData = cDoc.data();
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _confirmAndCancelOrder() async {
    final TextEditingController reasonController = TextEditingController();
    String selectedReason = 'Ordered by mistake';
    final List<String> cancelReasons = [
      'Ordered by mistake',
      'Want to change items or address',
      'Delivery taking longer than expected',
      'Other reason',
    ];

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Cancel Order?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to cancel this order?',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              ...cancelReasons.map((reason) {
                return RadioListTile<String>(
                  value: reason,
                  groupValue: selectedReason,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFFDC2626),
                  title: Text(reason, style: const TextStyle(fontSize: 13)),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedReason = val);
                    }
                  },
                );
              }),
              if (selectedReason == 'Other reason') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: 'Enter reason...',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep Order'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirm Cancel'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final String finalReason = selectedReason == 'Other reason' &&
            reasonController.text.trim().isNotEmpty
        ? reasonController.text.trim()
        : selectedReason;

    setState(() => _isCancelling = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': 'Cancelled',
        'orderStatus': 'Cancelled',
        'currentStatus': 'Cancelled',
        'cancelReason': finalReason,
        'cancelledBy': 'Customer',
        'updatedAt': FieldValue.serverTimestamp(),
        'trackingHistory': FieldValue.arrayUnion([
          {
            'status': 'Cancelled',
            'title': 'Order Cancelled by Customer ($finalReason)',
            'timestamp': DateTime.now().toIso8601String(),
            'updatedBy': 'Customer',
          }
        ]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
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
            'Track Order #${widget.orderId}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17.5),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0.5,
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                );
              },
              icon: const Icon(Icons.support_agent_rounded,
                  size: 18, color: Color(0xFF00875A)),
              label: const Text(
                'Help',
                style: TextStyle(
                  color: Color(0xFF00875A),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.orderId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00875A)),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  'Order details not found',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }

            final data =
                snapshot.data!.data() as Map<String, dynamic>? ?? {};

            final String merchantId =
                (data['merchantId'] ?? '').toString().trim();
            final String userId = (data['userId'] ?? '').toString().trim();

            if (data['storeLocation'] == null ||
                data['customerLocation'] == null) {
              _fetchMerchantAndCustomerDetails(merchantId, userId);
            }

            final model = OrderTrackingModel.fromFirestore(
              widget.orderId,
              data,
              merchantDocData: _merchantDocData,
              customerDocData: _customerDocData,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. LIVE STATUS BANNER + 5-STEP STEPPER + 4-DIGIT DELIVERY OTP
                  OrderStatusStepperCard(
                    model: model,
                    onCancelTap: _isCancelling ? null : _confirmAndCancelOrder,
                  ),
                  const SizedBox(height: 16),

                  // 2. LIVE OPENSTREETMAP + BLUE ROUTE LINE + 3 PINS + DYNAMIC ETA BANNER
                  if (!model.isCancelled) ...[
                    LiveTrackingMapCard(
                      model: model,
                      onCallPartner: _makePhoneCall,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 3. REAL-TIME MERGED TRACKING TIMELINE
                  OrderTimelineCard(
                    timeline: model.timeline,
                    isCancelled: model.isCancelled,
                  ),
                  const SizedBox(height: 16),

                  // 4. ITEMS ORDERED, BILL SUMMARY & ADDRESS/INSTRUCTIONS
                  OrderItemsAndBillSection(model: model),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}