import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

class ProductImageCarouselWidget extends StatefulWidget {
  final String productId;
  final String productName;
  final String primaryImageUrl;
  final List<String> extraImages;
  final String unit;
  final int discountPercent;
  final String deliveryLocation;
  final VoidCallback? onChangeLocationTap;

  const ProductImageCarouselWidget({
    super.key,
    required this.productId,
    required this.productName,
    required this.primaryImageUrl,
    this.extraImages = const [],
    required this.unit,
    required this.discountPercent,
    this.deliveryLocation = 'Nellore - 524004',
    this.onChangeLocationTap,
  });

  @override
  State<ProductImageCarouselWidget> createState() =>
      _ProductImageCarouselWidgetState();
}

class _ProductImageCarouselWidgetState extends State<ProductImageCarouselWidget> {
  final PageController _pageController = PageController();
  int _currentSlide = 0;
  Timer? _countdownTimer;
  Duration _remainingSaleTime = const Duration(
    days: 8,
    hours: 1,
    minutes: 2,
    seconds: 44,
  );

  late final List<_SlideSpec> _slides;

  @override
  void initState() {
    super.initState();
    _slides = _buildSlidesList();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSaleTime.inSeconds > 0) {
          _remainingSaleTime -= const Duration(seconds: 1);
        } else {
          _remainingSaleTime = const Duration(hours: 4, minutes: 30);
        }
      });
    });
  }

  List<_SlideSpec> _buildSlidesList() {
    final List<String> uniqueUrls = [];
    if (widget.primaryImageUrl.trim().isNotEmpty) {
      uniqueUrls.add(widget.primaryImageUrl.trim());
    }
    for (final img in widget.extraImages) {
      final String clean = img.trim();
      if (clean.isNotEmpty && !uniqueUrls.contains(clean)) {
        uniqueUrls.add(clean);
      }
    }

    if (uniqueUrls.length > 1) {
      return uniqueUrls
          .asMap()
          .entries
          .map(
            (e) => _SlideSpec(
              imageUrl: e.value,
              mode: _SlideMode.standard,
              caption: 'View ${e.key + 1} of ${uniqueUrls.length}',
            ),
          )
          .toList();
    }

    final String img = uniqueUrls.isNotEmpty ? uniqueUrls.first : '';
    return [
      _SlideSpec(
        imageUrl: img,
        mode: _SlideMode.standard,
        caption: 'Front Pack View',
      ),
      _SlideSpec(
        imageUrl: img,
        mode: _SlideMode.zoomedDetail,
        caption: 'Close-Up Quality View',
      ),
      _SlideSpec(
        imageUrl: img,
        mode: _SlideMode.freshnessHighlight,
        caption: '100% Fresh & Quality Checked',
      ),
      _SlideSpec(
        imageUrl: img,
        mode: _SlideMode.packSpecHighlight,
        caption: 'Net Pack: ${widget.unit} • 15 Mins Delivery',
      ),
    ];
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildRawImage(String imageStr, {double iconSize = 80}) {
    if (imageStr.trim().isEmpty) {
      return Icon(
        Icons.shopping_bag_outlined,
        size: iconSize,
        color: Colors.green.shade200,
      );
    }

    if (!imageStr.startsWith('http://') && !imageStr.startsWith('https://')) {
      try {
        final cleanBase64 =
            imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        final bytes = base64Decode(cleanBase64.trim());
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.shopping_bag_outlined,
            size: iconSize,
            color: Colors.green.shade200,
          ),
        );
      } catch (_) {
        return Icon(
          Icons.shopping_bag_outlined,
          size: iconSize,
          color: Colors.green.shade200,
        );
      }
    }

    return Image.network(
      imageStr,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.shopping_bag_outlined,
        size: iconSize,
        color: Colors.green.shade200,
      ),
    );
  }

  void _openFullScreenGallery(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (ctx) {
        int activeModalIndex = initialIndex;
        final PageController modalController =
            PageController(initialPage: initialIndex);

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Dialog(
              backgroundColor: Colors.black,
              insetPadding: EdgeInsets.zero,
              child: SafeArea(
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: modalController,
                      itemCount: _slides.length,
                      onPageChanged: (idx) {
                        setModalState(() => activeModalIndex = idx);
                      },
                      itemBuilder: (context, idx) {
                        return InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: _buildRawImage(
                                _slides[idx].imageUrl,
                                iconSize: 120,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x99000000),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${activeModalIndex + 1} / ${_slides.length} • Pinch to Zoom',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int days = _remainingSaleTime.inDays;
    final int hours = _remainingSaleTime.inHours % 24;
    final int mins = _remainingSaleTime.inMinutes % 60;
    final int secs = _remainingSaleTime.inSeconds % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. DELIVERING TO LOCATION STRIP (Screenshot 1)
        InkWell(
          onTap: widget.onChangeLocationTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Delivering to ',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                Flexible(
                  child: Text(
                    widget.deliveryLocation,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),

        // 2. SALE COUNTDOWN TIMER STRIP (Screenshot 1)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFEF08A), Color(0xFFFDE047), Color(0xFFFACC15)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.discountPercent > 0
                      ? 'UP TO ${widget.discountPercent}% OFF'
                      : 'FLASH DEAL',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Sale Ends in ',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  _buildTimeBox(days.toString().padLeft(2, '0')),
                  const Text(
                    ' d : ',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  _buildTimeBox(hours.toString().padLeft(2, '0')),
                  const Text(
                    ' h : ',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  _buildTimeBox(mins.toString().padLeft(2, '0')),
                  const Text(
                    ' m : ',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  _buildTimeBox(secs.toString().padLeft(2, '0')),
                  const Text(
                    ' s',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3. SWIPEABLE MULTI-SLIDE PRODUCT IMAGE SHOWCASE CARD
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF3E8FF), Color(0xFFF8FAFC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Container(
            height: 290,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _slides.length,
                        onPageChanged: (idx) {
                          setState(() => _currentSlide = idx);
                        },
                        itemBuilder: (context, index) {
                          final slide = _slides[index];
                          return GestureDetector(
                            onTap: () => _openFullScreenGallery(context, index),
                            child: _buildSlideContent(slide, index),
                          );
                        },
                      ),
                    ),
                    // Slide Caption & Indicator Dots
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 4),
                      child: Column(
                        children: [
                          Text(
                            _slides[_currentSlide].caption,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _slides.length,
                              (idx) => GestureDetector(
                                onTap: () {
                                  _pageController.animateToPage(
                                    idx,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  width: _currentSlide == idx ? 18 : 7,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: _currentSlide == idx
                                        ? const Color(0xFF00875A)
                                        : const Color(0xFFCBD5E1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Left / Right Quick Slide Arrows for Easy Navigation
                if (_currentSlide > 0)
                  Positioned(
                    left: 8,
                    top: 115,
                    child: _buildSlideArrow(
                      icon: Icons.chevron_left_rounded,
                      onTap: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                  ),
                if (_currentSlide < _slides.length - 1)
                  Positioned(
                    right: 8,
                    top: 115,
                    child: _buildSlideArrow(
                      icon: Icons.chevron_right_rounded,
                      onTap: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                  ),

                // Bottom-Left Product Code Pill (like s-691714525 in Screenshot 1)
                Positioned(
                  bottom: 38,
                  left: 12,
                  child: Text(
                    'f2m-${widget.productId.length > 8 ? widget.productId.substring(0, 8) : widget.productId}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Bottom-Right Gallery / Zoom Floating Button (Screenshot 1)
                Positioned(
                  bottom: 34,
                  right: 12,
                  child: InkWell(
                    onTap: () => _openFullScreenGallery(context, _currentSlide),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.collections_bookmark_outlined,
                        size: 18,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlideContent(_SlideSpec slide, int index) {
    switch (slide.mode) {
      case _SlideMode.standard:
        return Padding(
          padding: const EdgeInsets.all(18.0),
          child: Center(
            child: index == 0
                ? Hero(
                    tag: 'product_image_${widget.productId}',
                    child: _buildRawImage(slide.imageUrl, iconSize: 100),
                  )
                : _buildRawImage(slide.imageUrl, iconSize: 100),
          ),
        );
      case _SlideMode.zoomedDetail:
        return ClipRect(
          child: Center(
            child: Transform.scale(
              scale: 1.32,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildRawImage(slide.imageUrl, iconSize: 100),
              ),
            ),
          ),
        );
      case _SlideMode.freshnessHighlight:
        return Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFF0FDF4),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: _buildRawImage(slide.imageUrl, iconSize: 70),
              ),
              const SizedBox(width: 12),
              const Expanded(
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF16A34A),
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'QUALITY ASSURED',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      '100% Genuine & Hygienically Packed',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '✓ Multi-stage freshness check\n✓ Sourced from verified partner\n✓ Instant doorstep replacement',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case _SlideMode.packSpecHighlight:
        return Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFEFF6FF),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: _buildRawImage(slide.imageUrl, iconSize: 70),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'EXPRESS 15 MINS',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pack Unit: ${widget.unit}\nFast local store dispatch\nCash on Delivery available',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildSlideArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xE6FFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildTimeBox(String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        val,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

enum _SlideMode {
  standard,
  zoomedDetail,
  freshnessHighlight,
  packSpecHighlight,
}

class _SlideSpec {
  final String imageUrl;
  final _SlideMode mode;
  final String caption;

  const _SlideSpec({
    required this.imageUrl,
    required this.mode,
    required this.caption,
  });
}
