import 'dart:async';
import 'package:flutter/foundation.dart'; // kIsWeb ని ఉపయోగించడానికి
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

  // ఇమేజ్ పేర్లు
  final List<Map<String, dynamic>> _bannerList = [
    {
      'title': 'Diwali Offers',
      'imageName': 'banner1.jpeg',
    },
    {
      'title': 'Flash Delivery',
      'imageName': 'banner2.jpeg',
    },
    {
      'title': 'Fresh Veggies',
      'imageName': 'banner3.jpeg',
    },
  ];

  @override
  void initState() {
    super.initState();
    // ప్రతి 5 సెకన్లకు ఒకసారి 800ms వేగంతో స్మూత్‌గా స్లైడ్ అవుతుంది
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
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _bannerList.length,
            itemBuilder: (context, index) {
              final Map<String, dynamic> item = _bannerList[index];
              final String title = (item['title'] ?? '').toString();
              final String imageName = (item['imageName'] ?? '').toString();

              // Mobile and Web రన్ టైమ్‌కి సరిపోయేలా ఆటో పాత్ హ్యాండ్లింగ్
              final String fullImagePath = kIsWeb
                  ? 'icon/$imageName'
                  : 'assets/icon/$imageName';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  fullImagePath,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF00875A),
                      child: Center(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Dots Indicator
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