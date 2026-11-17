import 'dart:async';
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

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 2, 12, 4),
          height: 52,
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
          child: Stack(
            children: [
              activeCount == 1
                  ? _buildOrderRow(
                      context,
                      doc: activeDocs.first,
                      orderIndex: 1,
                      totalOrders: 1,
                    )
                  : PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: activeCount,
                      onPageChanged: (idx) {
                        setState(() => _activePageIndex = idx);
                      },
                      itemBuilder: (context, index) {
                        return _buildOrderRow(
                          context,
                          doc: activeDocs[index],
                          orderIndex: index + 1,
                          totalOrders: activeCount,
                        );
                      },
                    ),

              // Right side top edge: Slide indicator pills (.  -  .  .)
              if (activeCount > 1)
                Positioned(
                  top: 5,
                  right: 14,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(activeCount, (dotIdx) {
                      final bool isCurrent = _activePageIndex == dotIdx;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(left: 3),
                        width: isCurrent ? 14 : 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF64748B),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderRow(
    BuildContext context, {
    required QueryDocumentSnapshot doc,
    required int orderIndex,
    required int totalOrders,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final model = OrderTrackingModel.fromFirestore(doc.id, data);
    final String displayOrderId = (data['orderId'] ?? doc.id).toString();
    final bool isOnTheWay = model.currentStepIndex >= 3;

    final String orderNoun = totalOrders == 1 ? 'order' : 'orders';
    final String processingLabel = '$totalOrders $orderNoun processing';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: doc.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
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
                size: 15,
              ),
            ),
            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          processingLabel,
                          style: const TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const _AnimatedProcessingChevrons(),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: orderIndex == 1
                              ? const Color(0xFF2563EB)
                              : orderIndex == 2
                                  ? const Color(0xFF7C3AED)
                                  : const Color(0xFF0891B2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Order $orderIndex#$displayOrderId',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          model.displayStatus,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (model.deliveryOtp.isNotEmpty) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: model.deliveryOtp));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('OTP ${model.deliveryOtp} Copied!'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFF59E0B),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'OTP: ',
                        style: TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        model.deliveryOtp,
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(width: 6),

            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Track',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedProcessingChevrons extends StatefulWidget {
  const _AnimatedProcessingChevrons();

  @override
  State<_AnimatedProcessingChevrons> createState() =>
      _AnimatedProcessingChevronsState();
}

class _AnimatedProcessingChevronsState
    extends State<_AnimatedProcessingChevrons> {
  Timer? _timer;
  int _activeArrowIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 280), (_) {
      if (!mounted) return;
      setState(() {
        _activeArrowIndex = (_activeArrowIndex + 1) % 4;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final bool isLit = _activeArrowIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 0.5),
          child: Text(
            '>',
            style: TextStyle(
              fontSize: 9,
              fontWeight: isLit ? FontWeight.w900 : FontWeight.w600,
              color: isLit
                  ? const Color(0xFF22C55E)
                  : const Color(0x664ADE80),
            ),
          ),
        );
      }),
    );
  }
}
