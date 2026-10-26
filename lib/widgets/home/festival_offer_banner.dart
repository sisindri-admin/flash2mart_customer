import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FestivalOfferBanner extends StatelessWidget {
  final VoidCallback? onShopFestivalTap;

  const FestivalOfferBanner({
    super.key,
    this.onShopFestivalTap,
  });

  Map<String, dynamic> _getSeasonalDefaultFestival() {
    final int month = DateTime.now().month;
    if (month == 1) {
      return {
        'festivalName': '🌾 SANKRANTI PANDUGA MELA',
        'title': 'Sankranti Special Grocery Dhamaka!',
        'subtitle':
            'Flat 40% OFF on Jaggery, Rice, Ghee, Dry Fruits & Pindi Vantalu Items',
        'couponCode': 'PANDUGA40',
        'badgeText': 'FESTIVAL LIVE',
        'primaryColor': const Color(0xFFB45309),
        'secondaryColor': const Color(0xFF78350F),
      };
    } else if (month == 3 || month == 4) {
      return {
        'festivalName': '🥭 UGADI SUBHAKANKSHALU OFFERS',
        'title': 'Ugadi New Year Mega Grocery Sale!',
        'subtitle':
            'Special discounts on Raw Mangoes, Jaggery, Neem, Oils & Pooja Samagri',
        'couponCode': 'UGADI50',
        'badgeText': 'UGADI SPECIAL',
        'primaryColor': const Color(0xFF15803D),
        'secondaryColor': const Color(0xFF065F46),
      };
    } else if (month == 8 || month == 9) {
      return {
        'festivalName': '🙏 VINAYAKA CHAVITHI & DASARA UTSAV',
        'title': 'Grand Festival Pooja & Sweet Essentials',
        'subtitle':
            'Up to 45% OFF on Fresh Fruits, Flowers, Pure Ghee, Rava & Dry Fruits',
        'couponCode': 'UTSAV45',
        'badgeText': 'FESTIVE SALE',
        'primaryColor': const Color(0xFF9333EA),
        'secondaryColor': const Color(0xFF581C87),
      };
    } else if (month == 10 || month == 11) {
      return {
        'festivalName': '🪔 DEEPAVALI PANDUGA SPECIAL',
        'title': 'Diwali Mega Dhamaka Super Savers!',
        'subtitle':
            'Up to 50% OFF on Cooking Oils, Dry Fruits, Sweets, Snacks & Pooja Needs',
        'couponCode': 'DIWALI50',
        'badgeText': 'MEGA FESTIVAL',
        'primaryColor': const Color(0xFFB91C1C),
        'secondaryColor': const Color(0xFF7F1D1D),
      };
    } else if (month == 12) {
      return {
        'festivalName': '🎄 CHRISTMAS & NEW YEAR CARNIVAL',
        'title': 'Year-End Party & Bakery Super Sale!',
        'subtitle':
            'Big savings on Cakes, Chocolates, Cold Drinks, Dry Fruits & Groceries',
        'couponCode': 'NEWYEAR50',
        'badgeText': 'YEAR END SALE',
        'primaryColor': const Color(0xFFBE123C),
        'secondaryColor': const Color(0xFF881337),
      };
    }

    return {
      'festivalName': '🎉 PANDUGA SPECIAL SUPER SAVERS',
      'title': 'Festival Combo & Family Pack Deals!',
      'subtitle':
          'Up to 40% OFF on Milk, Ghee, Sona Masoori Rice, Oils & Fresh Veggies',
      'couponCode': 'FESTIVAL40',
      'badgeText': 'FESTIVAL OFFER',
      'primaryColor': const Color(0xFFC2410C),
      'secondaryColor': const Color(0xFF7C2D12),
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('festival_banners')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final Map<String, dynamic> fallback = _getSeasonalDefaultFestival();
        Map<String, dynamic> activeData = fallback;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final raw =
              snapshot.data!.docs.first.data() as Map<String, dynamic>? ?? {};
          activeData = {
            'festivalName':
                (raw['festivalName'] ?? fallback['festivalName']).toString(),
            'title': (raw['title'] ?? fallback['title']).toString(),
            'subtitle': (raw['subtitle'] ?? fallback['subtitle']).toString(),
            'couponCode':
                (raw['couponCode'] ?? fallback['couponCode']).toString(),
            'badgeText': (raw['badgeText'] ?? fallback['badgeText']).toString(),
            'primaryColor': fallback['primaryColor'],
            'secondaryColor': fallback['secondaryColor'],
          };
        }

        final String festivalName = activeData['festivalName'].toString();
        final String title = activeData['title'].toString();
        final String subtitle = activeData['subtitle'].toString();
        final String couponCode = activeData['couponCode'].toString();
        final String badgeText = activeData['badgeText'].toString();
        final Color primaryColor = activeData['primaryColor'] as Color;
        final Color secondaryColor = activeData['secondaryColor'] as Color;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFFDE047),
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Festival Name Pill + Live Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFef08A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          festivalName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF451A03),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 12,
                            color: Color(0xFFFDE047),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Main Offer Title & Subtitle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFFEF3C7),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0x26FFFFFF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x66FDE047)),
                      ),
                      child: const Icon(
                        Icons.celebration_rounded,
                        color: Color(0xFFFDE047),
                        size: 26,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bottom Row: Copy Coupon Code + Shop Festival Offers Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: couponCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Festival Coupon "$couponCode" copied! Use at Checkout.',
                            ),
                            backgroundColor: const Color(0xFF00875A),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x26000000),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0x99FDE047),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.confirmation_number_outlined,
                              size: 13,
                              color: Color(0xFFFDE047),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'CODE: $couponCode',
                              style: const TextStyle(
                                color: Color(0xFFFDE047),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.copy_rounded,
                              size: 11,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (onShopFestivalTap != null)
                      InkWell(
                        onTap: onShopFestivalTap,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Shop Festival Deals',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
