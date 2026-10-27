import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<String> offerImages;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.offerImages = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SafeArea(
        top: false,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFAFFFFFF),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPillNavItem(
                index: 0,
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
              ),
              _buildPillNavItem(
                index: 1,
                label: 'Categories',
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
              ),
              _buildPillNavItem(
                index: 2,
                label: 'Search',
                icon: Icons.search_rounded,
                activeIcon: Icons.search_rounded,
              ),
              _buildPillNavItem(
                index: 3,
                label: 'Buy Again',
                icon: Icons.shopping_basket_outlined,
                activeIcon: Icons.shopping_basket_rounded,
              ),
              _buildTodayOfferNavItem(
                index: 4,
                isSelected: currentIndex == 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEEEEE) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 17.5,
                color: isSelected
                    ? const Color(0xFFE11D48)
                    : const Color(0xFF52525B),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF09090B)
                      : const Color(0xFF27272A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayOfferNavItem({
    required int index,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF1F2) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Requirement 2: Big animated circle with combo colors showing "COMBO" then real product images scrolling UPWARD
              _RotatingOfferCircleIcon(
                isSelected: isSelected,
                offerImages: offerImages,
              ),
              const SizedBox(height: 2),
              Text(
                'Today Offer',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFFE11D48)
                      : const Color(0xFF27272A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Attractive circular icon with larger size (30x30) with multi-color combo gradient
/// where first "COMBO" text appears, and then real offer product images scroll UPWARD smoothly!
class _RotatingOfferCircleIcon extends StatefulWidget {
  final bool isSelected;
  final List<String> offerImages;

  const _RotatingOfferCircleIcon({
    required this.isSelected,
    this.offerImages = const [],
  });

  @override
  State<_RotatingOfferCircleIcon> createState() =>
      _RotatingOfferCircleIconState();
}

class _RotatingOfferCircleIconState extends State<_RotatingOfferCircleIcon> {
  static final Map<String, MemoryImage> _sharedMemoryImageCache = {};
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2100), (_) {
      if (mounted) {
        setState(() {
          final int totalItems = 1 + widget.offerImages.length;
          _currentIndex = (_currentIndex + 1) % totalItems;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildProductThumbnail(String rawImage) {
    final String trimmed = rawImage.trim();
    if (trimmed.isEmpty) {
      return const Icon(
        Icons.local_offer_rounded,
        size: 14,
        color: Colors.white,
      );
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      MemoryImage? memImg = _sharedMemoryImageCache[trimmed];
      if (memImg == null) {
        try {
          final clean =
              trimmed.contains(',') ? trimmed.split(',').last : trimmed;
          final Uint8List bytes = base64Decode(clean.trim());
          memImg = MemoryImage(bytes);
          _sharedMemoryImageCache[trimmed] = memImg;
        } catch (_) {
          return const Icon(
            Icons.shopping_bag_rounded,
            size: 14,
            color: Colors.white,
          );
        }
      }
      return Image(
        image: memImg,
        fit: BoxFit.cover,
        width: 30,
        height: 30,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.shopping_bag_rounded,
          size: 14,
          color: Colors.white,
        ),
      );
    }

    return Image.network(
      trimmed,
      fit: BoxFit.cover,
      width: 30,
      height: 30,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.shopping_bag_rounded,
        size: 14,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Index 0 is always the bold "COMBO" text
    // Index 1..N are real offer product images
    final bool isComboText = _currentIndex == 0 || widget.offerImages.isEmpty;
    final String currentImage = (!isComboText &&
            _currentIndex - 1 < widget.offerImages.length)
        ? widget.offerImages[_currentIndex - 1]
        : '';

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF5722), // Vibrant Coral
            Color(0xFFE11D48), // Rose Red
            Color(0xFFF59E0B), // Festive Amber
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isSelected
                ? const Color(0x66E11D48)
                : const Color(0x33FF5722),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final inTween = Tween<Offset>(
              begin: const Offset(0.0, 1.0), // Scroll UPWARD
              end: Offset.zero,
            );
            return ClipRect(
              child: SlideTransition(
                position: inTween.animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              ),
            );
          },
          child: isComboText
              ? const SizedBox(
                  key: ValueKey('combo_text'),
                  child: Text(
                    'COMBO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                )
              : ClipOval(
                  key: ValueKey('prod_img_$_currentIndex'),
                  child: _buildProductThumbnail(currentImage),
                ),
        ),
      ),
    );
  }
}