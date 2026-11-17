import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FestivalOfferBanner extends StatefulWidget {
  final VoidCallback? onShopFestivalTap;

  const FestivalOfferBanner({
    super.key,
    this.onShopFestivalTap,
  });

  @override
  State<FestivalOfferBanner> createState() => _FestivalOfferBannerState();
}

class _FestivalOfferBannerState extends State<FestivalOfferBanner> {
  late final Stream<QuerySnapshot> _bannerStream;

  @override
  void initState() {
    super.initState();
    _bannerStream = FirebaseFirestore.instance
        .collection('festival_banners')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots();
  }

  Map<String, dynamic> _getSeasonalDefaultFestival() {
    final int month = DateTime.now().month;
    if (month == 1) {
      return {
        'festivalName': '🌾 SANKRANTI PANDUGA OFFERS',
        'title': 'Sankranti Special Grocery Sale!',
        'subtitle': 'Up to 40% OFF on Jaggery, Rice, Ghee & Dry Fruits',
        'couponCode': 'PANDUGA40',
        'primaryColor': const Color(0xFFB45309),
        'secondaryColor': const Color(0xFF78350F),
      };
    } else if (month == 3 || month == 4) {
      return {
        'festivalName': '🥭 UGADI SPECIAL OFFERS',
        'title': 'Ugadi Festival Super Savers!',
        'subtitle': 'Special discounts on Mangoes, Jaggery, Oils & Pooja Items',
        'couponCode': 'UGADI50',
        'primaryColor': const Color(0xFF15803D),
        'secondaryColor': const Color(0xFF065F46),
      };
    } else if (month == 8 || month == 9) {
      return {
        'festivalName': '🙏 VINAYAKA CHAVITHI & DASARA',
        'title': 'Festival Pooja & Sweet Essentials',
        'subtitle': 'Up to 45% OFF on Fruits, Pure Ghee, Rava & Dry Fruits',
        'couponCode': 'UTSAV45',
        'primaryColor': const Color(0xFF7E22CE),
        'secondaryColor': const Color(0xFF4C1D95),
      };
    } else if (month == 10 || month == 11) {
      return {
        'festivalName': '🪔 DEEPAVALI PANDUGA SPECIAL',
        'title': 'Diwali Mega Grocery Savers!',
        'subtitle': 'Up to 50% OFF on Oils, Dry Fruits, Sweets & Pooja Needs',
        'couponCode': 'DIWALI50',
        'primaryColor': const Color(0xFFB91C1C),
        'secondaryColor': const Color(0xFF7F1D1D),
      };
    } else if (month == 12) {
      return {
        'festivalName': '🎄 CHRISTMAS & NEW YEAR SALE',
        'title': 'Year-End Bakery & Grocery Fest!',
        'subtitle': 'Big savings on Cakes, Chocolates, Drinks & Daily Staples',
        'couponCode': 'NEWYEAR50',
        'primaryColor': const Color(0xFFBE123C),
        'secondaryColor': const Color(0xFF881337),
      };
    }

    return {
      'festivalName': '🎉 PANDUGA SPECIAL OFFERS',
      'title': 'Festival Family Pack Super Deals!',
      'subtitle': 'Up to 40% OFF on Milk, Ghee, Rice, Oils & Fresh Veggies',
      'couponCode': 'FESTIVAL40',
      'primaryColor': const Color(0xFFC2410C),
      'secondaryColor': const Color(0xFF7C2D12),
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _bannerStream,
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
            'primaryColor': fallback['primaryColor'],
            'secondaryColor': fallback['secondaryColor'],
          };
        }

        final String festivalName = activeData['festivalName'].toString();
        final String title = activeData['title'].toString();
        final String subtitle = activeData['subtitle'].toString();
        final String couponCode = activeData['couponCode'].toString();
        final Color primaryColor = activeData['primaryColor'] as Color;
        final Color secondaryColor = activeData['secondaryColor'] as Color;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
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
                        color: const Color(0xFFFEF08A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        festivalName,
                        style: const TextStyle(
                          color: Color(0xFF451A03),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFEF3C7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: widget.onShopFestivalTap ??
                    () {
                      Clipboard.setData(ClipboardData(text: couponCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Festival code "$couponCode" copied!'),
                          backgroundColor: const Color(0xFF00875A),
                        ),
                      );
                    },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Explore >',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
