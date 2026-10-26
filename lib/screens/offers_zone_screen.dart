import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../widgets/checkout/checkout_promo_and_bill_widgets.dart';
import '../widgets/home/jiomart_popular_product_card.dart';
import 'help_screen.dart';

class OffersZoneScreen extends StatelessWidget {
  final String currentAddress;

  const OffersZoneScreen({
    super.key,
    required this.currentAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFC81E45),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.local_offer_rounded, color: Color(0xFFFDE047), size: 22),
            SizedBox(width: 8),
            Text(
              'Festive Offers & Super Deals',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17.5),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
            icon: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 18,
            ),
            label: const Text(
              'Help',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('app_config')
                  .doc('festival_banner')
                  .snapshots(),
              builder: (context, snapshot) {
                final data =
                    (snapshot.data?.data() as Map<String, dynamic>?) ?? {};
                final String title =
                    (data['festivalTitle'] ?? 'Diwali Mega Festival').toString();
                final String subtitle =
                    (data['festivalSubtitle'] ?? 'Up to 50% Off + Free Delivery')
                        .toString();

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC81E45), Color(0xFF881337)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFACC15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'LIVE FESTIVAL OFFER',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.celebration_rounded,
                        size: 52,
                        color: Color(0xFFFDE047),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Exclusive Coupons for You',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            ...CheckoutPromoAndBillWidgets.availableCoupons.map((coupon) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC81E45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        coupon.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coupon.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          Text(
                            coupon.description,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: coupon.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Coupon ${coupon.code} copied! Apply at Checkout.',
                            ),
                            backgroundColor: const Color(0xFF00875A),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0078AD),
                        side: const BorderSide(color: Color(0xFF0078AD)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'COPY',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'Biggest Price Drops Near You',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.48,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final String pId = doc.id;
                    final String pName =
                        (data['name'] ?? data['title'] ?? 'Product').toString();
                    final double pPrice =
                        ((data['price'] ?? 0) as num).toDouble();
                    final double pMrp =
                        ((data['marketPrice'] ?? (pPrice + 15)) as num)
                            .toDouble();
                    final String pUnit =
                        (data['unit'] ?? data['weight'] ?? '1 unit').toString();
                    final String pImg = (data['imageBase64'] ??
                            data['imageUrl'] ??
                            data['image'] ??
                            '')
                        .toString();
                    final int pStock = ((data['stock'] ?? 1) as num).toInt();

                    return Selector<CartProvider, int>(
                      selector: (context, cart) =>
                          cart.items[pId]?.quantity ?? 0,
                      builder: (context, qty, child) {
                        return JioMartPopularProductCard(
                          id: pId,
                          name: pName,
                          price: pPrice,
                          marketPrice: pMrp,
                          unit: pUnit,
                          imageUrl: pImg,
                          stock: pStock,
                          merchantId: (data['merchantId'] ?? '').toString(),
                          category: (data['category'] ?? '').toString(),
                          description: (data['description'] ?? '').toString(),
                          quantityInCart: qty,
                          onAdd: () {
                            context.read<CartProvider>().addItem(
                                  id: pId,
                                  name: pName,
                                  price: pPrice,
                                  unit: pUnit,
                                  imageUrl: pImg,
                                );
                          },
                          onRemove: () {
                            context.read<CartProvider>().removeSingleItem(pId);
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
