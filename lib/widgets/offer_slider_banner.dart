import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OfferSliderBanner extends StatefulWidget {
  const OfferSliderBanner({super.key});

  @override
  State<OfferSliderBanner> createState() => _OfferSliderBannerState();
}

class _OfferSliderBannerState extends State<OfferSliderBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _activeCount = 3;
  Timer? _timer;

  final List<Map<String, dynamic>> _defaultBanners = [
    {
      'title': 'Super Saver Grocery Deals',
      'subtitle': 'Up to 40% OFF on daily staples & oils',
      'tag': 'MEGA SALE',
      'imageName': 'banner1.jpeg',
      'colors': [const Color(0xFF00875A), const Color(0xFF047857)],
      'icon': Icons.shopping_basket_rounded,
    },
    {
      'title': '15 Mins Superfast Delivery',
      'subtitle': 'FREE Delivery on all orders above ₹200',
      'tag': 'FLASH EXPRESS',
      'imageName': 'banner2.jpeg',
      'colors': [const Color(0xFF1D4ED8), const Color(0xFF1E3A8A)],
      'icon': Icons.bolt_rounded,
    },
    {
      'title': '100% Farm Fresh Veggies',
      'subtitle': 'Direct from local farms every morning',
      'tag': 'FRESH HARVEST',
      'imageName': 'banner3.jpeg',
      'colors': [const Color(0xFFB45309), const Color(0xFF78350F)],
      'icon': Icons.eco_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_activeCount <= 1) return;
      if (_currentPage < _activeCount - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildGradientFallback(
    String title,
    String subtitle,
    String tag,
    List<Color> gradientColors,
    IconData bannerIcon,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade400,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0x26FFFFFF),
              shape: BoxShape.circle,
            ),
            child: Icon(bannerIcon, size: 40, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminBannerImage(
    String rawImg,
    String title,
    String subtitle,
    String tag,
  ) {
    final clean = rawImg.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            clean,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildGradientFallback(
              title,
              subtitle,
              tag,
              const [Color(0xFF00875A), Color(0xFF065F46)],
              Icons.local_offer_rounded,
            ),
          ),
          if (title.isNotEmpty)
            Positioned(
              left: 14,
              bottom: 12,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  subtitle.isNotEmpty ? '$title • $subtitle' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    if (clean.isNotEmpty) {
      try {
        final b64 = clean.contains(',') ? clean.split(',').last : clean;
        final Uint8List bytes = base64Decode(b64.trim());
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
            if (title.isNotEmpty)
              Positioned(
                left: 14,
                bottom: 12,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    subtitle.isNotEmpty ? '$title • $subtitle' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        );
      } catch (_) {}
    }
    return _buildGradientFallback(
      title,
      subtitle,
      tag,
      const [Color(0xFF00875A), Color(0xFF065F46)],
      Icons.local_offer_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('banners')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final List<Map<String, dynamic>> liveBanners = [];
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          for (final doc in snapshot.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            liveBanners.add({
              'isAdmin': true,
              'title': (d['title'] ?? '').toString(),
              'subtitle': (d['subtitle'] ?? '').toString(),
              'tag': (d['targetCategory'] ?? '').toString().isNotEmpty
                  ? (d['targetCategory'] ?? '').toString().toUpperCase()
                  : 'FEATURED OFFER',
              'rawImg': (d['imageBase64'] ?? d['imageUrl'] ?? '').toString(),
            });
          }
        }

        final banners = liveBanners.isNotEmpty ? liveBanners : _defaultBanners;
        _activeCount = banners.length;
        final safePage = _currentPage >= banners.length ? 0 : _currentPage;

        return Column(
          children: [
            SizedBox(
              height: 158,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final Map<String, dynamic> item = banners[index];
                  final String title = (item['title'] ?? '').toString();
                  final String subtitle = (item['subtitle'] ?? '').toString();
                  final String tag = (item['tag'] ?? 'SPECIAL OFFER').toString();

                  if (item['isAdmin'] == true) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildAdminBannerImage(
                        (item['rawImg'] ?? '').toString(),
                        title,
                        subtitle,
                        tag,
                      ),
                    );
                  }

                  final String imageName = (item['imageName'] ?? '').toString();
                  final List<Color> gradientColors =
                      (item['colors'] as List<Color>?) ??
                          [const Color(0xFF00875A), const Color(0xFF065F46)];
                  final IconData bannerIcon =
                      (item['icon'] as IconData?) ?? Icons.local_offer_rounded;
                  final String fullImagePath =
                      kIsWeb ? 'icon/$imageName' : 'assets/icon/$imageName';

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      fullImagePath,
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildGradientFallback(
                          title,
                          subtitle,
                          tag,
                          gradientColors,
                          bannerIcon,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: safePage == index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: safePage == index
                        ? const Color(0xFF00875A)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
