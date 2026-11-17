import 'dart:async';
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
  Timer? _timer;

  final List<Map<String, dynamic>> _bannerList = [
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
      if (_currentPage < _bannerList.length - 1) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 158,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _bannerList.length,
            itemBuilder: (context, index) {
              final Map<String, dynamic> item = _bannerList[index];
              final String title = (item['title'] ?? '').toString();
              final String subtitle = (item['subtitle'] ?? '').toString();
              final String tag = (item['tag'] ?? 'SPECIAL OFFER').toString();
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
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
                            child: Icon(
                              bannerIcon,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
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
            _bannerList.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF00875A)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}