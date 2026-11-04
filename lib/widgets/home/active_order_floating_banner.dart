import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/order_tracking_model.dart';
import '../../screens/order_tracking_screen.dart';

class ActiveOrderFloatingBanner extends StatefulWidget {
  const ActiveOrderFloatingBanner({super.key});

  @override
  State<ActiveOrderFloatingBanner> createState() =>
      _ActiveOrderFloatingBannerState();
}

class _ActiveOrderFloatingBannerState extends State<ActiveOrderFloatingBanner> {
  final PageController _pageController = PageController();
  int _activePageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final List<QueryDocumentSnapshot> activeDocs =
            snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final model = OrderTrackingModel.fromFirestore(doc.id, data);
          return !model.isDelivered && !model.isCancelled;
        }).toList();

        if (activeDocs.isEmpty) return const SizedBox.shrink();

        activeDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final Timestamp? aTime = aData['createdAt'] as Timestamp?;
          final Timestamp? bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        final int activeCount = activeDocs.length;

        if (activeCount == 1) {
          final doc = activeDocs.first;
          final data = doc.data() as Map<String, dynamic>;
          final model = OrderTrackingModel.fromFirestore(doc.id, data);

          return _buildSingleOrderCard(
            context,
            docId: doc.id,
            model: model,
          );
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF334155),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$activeCount ACTIVE ORDERS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Swipe to switch orders',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: List.generate(activeCount, (dotIdx) {
                        final bool isCurrent = _activePageIndex == dotIdx;
                        return Container(
                          width: isCurrent ? 14 : 6,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF475569),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF334155), height: 1),
              SizedBox(
                height: 72,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: activeCount,
                  onPageChanged: (idx) {
                    setState(() {
                      _activePageIndex = idx;
                    });
                  },
                  itemBuilder: (context, index) {
                    final doc = activeDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final model =
                        OrderTrackingModel.fromFirestore(doc.id, data);

                    return _buildOrderContentRow(
                      context,
                      docId: doc.id,
                      model: model,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleOrderCard(
    BuildContext context, {
    required String docId,
    required OrderTrackingModel model,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _buildOrderContentRow(context, docId: docId, model: model),
    );
  }

  Widget _buildOrderContentRow(
    BuildContext context, {
    required String docId,
    required OrderTrackingModel model,
  }) {
    final bool isOnTheWay = model.currentStepIndex >= 3;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: docId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOnTheWay
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOnTheWay
                    ? Icons.two_wheeler_rounded
                    : Icons.inventory_2_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Order #${docId.length > 6 ? docId.substring(docId.length - 6) : docId} • ${model.displayStatus}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    model.statusSubtitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (model.deliveryOtp.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: model.deliveryOtp));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delivery OTP ${model.deliveryOtp} Copied!'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFF59E0B),
                      width: 1.1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'OTP',
                        style: TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        model.deliveryOtp,
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Track',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
