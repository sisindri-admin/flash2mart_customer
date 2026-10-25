import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/order_tracking_model.dart';
import '../widgets/orders/my_order_card_widget.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _showHistoryTab = false;

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            }
          },
        ),
        title: const Text(
          'My Orders & Live Tracking',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF00875A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: currentUserId == null
          ? const Center(
              child: Text(
                'దయచేసి మీ ఆర్డర్లు చూడటానికి ముందు లాగిన్ అవ్వండి.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: currentUserId)
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

                final List<QueryDocumentSnapshot> allOrders =
                    List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);

                allOrders.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final Timestamp? aTime = aData['createdAt'] as Timestamp?;
                  final Timestamp? bTime = bData['createdAt'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

                // Use OrderTrackingModel's unified status resolution so Delivered/Cancelled orders
                // accurately move into Order History even when updated by Delivery Partner app
                final List<QueryDocumentSnapshot> activeOrders = [];
                final List<QueryDocumentSnapshot> historyOrders = [];

                for (final doc in allOrders) {
                  final data = doc.data() as Map<String, dynamic>;
                  final model = OrderTrackingModel.fromFirestore(doc.id, data);
                  if (model.isDelivered || model.isCancelled) {
                    historyOrders.add(doc);
                  } else {
                    activeOrders.add(doc);
                  }
                }

                final List<QueryDocumentSnapshot> displayedOrders =
                    _showHistoryTab ? historyOrders : activeOrders;

                return Column(
                  children: [
                    // Segmented Tab Switcher (Active Orders vs Past Orders)
                    Container(
                      color: const Color(0xFF00875A),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF065F46),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTabButton(
                                title: 'Active Orders (${activeOrders.length})',
                                isSelected: !_showHistoryTab,
                                onTap: () => setState(() => _showHistoryTab = false),
                              ),
                            ),
                            Expanded(
                              child: _buildTabButton(
                                title: 'Past Orders (${historyOrders.length})',
                                isSelected: _showHistoryTab,
                                onTap: () => setState(() => _showHistoryTab = true),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Orders List or Empty State
                    Expanded(
                      child: displayedOrders.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              itemCount: displayedOrders.length,
                              itemBuilder: (context, index) {
                                final doc = displayedOrders[index];
                                final orderData =
                                    doc.data() as Map<String, dynamic>;
                                return MyOrderCardWidget(
                                  key: ValueKey('order_${doc.id}'),
                                  orderId: doc.id,
                                  data: orderData,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isSelected ? const Color(0xFF00875A) : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0x1400875A),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _showHistoryTab
                    ? Icons.history_rounded
                    : Icons.shopping_bag_outlined,
                size: 56,
                color: const Color(0xFF00875A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _showHistoryTab
                  ? 'గత ఆర్డర్లు ఏవీ లేవు (No Past Orders)'
                  : 'ప్రస్తుతం యాక్టివ్ ఆర్డర్లు ఏవీ లేవు',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _showHistoryTab
                  ? 'మీరు డెలివరీ పూర్తి చేసుకున్న ఆర్డర్లు ఇక్కడ కనిపిస్తాయి.'
                  : '15 నిమిషాల్లో ఫ్రెష్ కూరగాయలు & సరుకుల కోసం ఇప్పుడే ఆర్డర్ చేయండి!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}