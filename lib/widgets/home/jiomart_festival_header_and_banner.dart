import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class JioMartTopHeaderAndFestivalSection extends StatefulWidget {
  final bool isQuickMode;
  final ValueChanged<bool> onModeChanged;
  final String currentAddress;
  final VoidCallback onAddressTap;
  final VoidCallback onProfileTap;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final List<QueryDocumentSnapshot> allProducts;

  const JioMartTopHeaderAndFestivalSection({
    super.key,
    required this.isQuickMode,
    required this.onModeChanged,
    required this.currentAddress,
    required this.onAddressTap,
    required this.onProfileTap,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.allProducts,
  });

  @override
  State<JioMartTopHeaderAndFestivalSection> createState() =>
      _JioMartTopHeaderAndFestivalSectionState();
}

class _JioMartTopHeaderAndFestivalSectionState
    extends State<JioMartTopHeaderAndFestivalSection> {
  static const List<String> _rotatingSearchHints = [
    'Search for "Fruits"',
    'Search for "Atta"',
    'Search for "Milk & Curd"',
    'Search for "Rice & Oil"',
    'Search for "Stationery"',
    'Search for "Vegetables"',
  ];

  int _hintIndex = 0;
  Timer? _hintTimer;
  final Map<String, Uint8List> _base64Cache = {};

  static const List<Map<String, dynamic>> _topCategoryTabs = [
    {'id': 'All', 'label': 'My Home', 'icon': Icons.shopping_bag_rounded},
    {
      'id': 'Grocery / Supermarket',
      'label': 'Groceries',
      'icon': Icons.kitchen_rounded,
    },
    {
      'id': 'Vegetables & Fruits',
      'label': 'Fresh Veggies',
      'icon': Icons.eco_rounded,
    },
    {
      'id': 'Milk & Dairy',
      'label': 'Dairy & Curd',
      'icon': Icons.egg_alt_rounded,
    },
    {
      'id': 'Electronics Store',
      'label': 'Mobiles',
      'icon': Icons.smartphone_rounded,
    },
    {
      'id': 'Electronics',
      'label': 'Electronics',
      'icon': Icons.headphones_rounded,
    },
    {
      'id': 'Medicines & Pharmacy',
      'label': 'Pharmacy',
      'icon': Icons.medical_services_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _hintTimer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (!mounted) return;
      setState(() {
        _hintIndex = (_hintIndex + 1) % _rotatingSearchHints.length;
      });
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    final String clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final int? val = int.tryParse('FF$clean', radix: 16);
      if (val != null) return Color(val);
    }
    return fallback;
  }

  Widget _buildImage(String imageStr, {double iconSize = 36}) {
    final String trimmed = imageStr.trim();
    if (trimmed.isEmpty) {
      return Icon(
        Icons.shopping_basket_rounded,
        size: iconSize,
        color: const Color(0xFFD97706),
      );
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      Uint8List? bytes = _base64Cache[trimmed];
      if (bytes == null) {
        try {
          final String cleanBase64 =
              trimmed.contains(',') ? trimmed.split(',').last : trimmed;
          bytes = base64Decode(cleanBase64.trim());
          _base64Cache[trimmed] = bytes;
        } catch (_) {
          return Icon(
            Icons.shopping_basket_rounded,
            size: iconSize,
            color: const Color(0xFFD97706),
          );
        }
      }
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.shopping_basket_rounded,
          size: iconSize,
          color: const Color(0xFFD97706),
        ),
      );
    }

    return Image.network(
      trimmed,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.shopping_basket_rounded,
        size: iconSize,
        color: const Color(0xFFD97706),
      ),
    );
  }

  List<String> _findImagesForKeywords(List<String> keywords) {
    final List<String> matches = [];
    for (final doc in widget.allProducts) {
      final data = doc.data() as Map<String, dynamic>;
      final String text =
          '${data['name'] ?? ''} ${data['category'] ?? ''}'.toLowerCase();
      final String img =
          (data['imageBase64'] ?? data['imageUrl'] ?? data['image'] ?? '')
              .toString()
              .trim();
      if (img.isEmpty) continue;
      for (final kw in keywords) {
        if (text.contains(kw)) {
          matches.add(img);
          break;
        }
      }
      if (matches.length >= 2) break;
    }

    if (matches.isEmpty) {
      for (final doc in widget.allProducts) {
        final data = doc.data() as Map<String, dynamic>;
        final String img =
            (data['imageBase64'] ?? data['imageUrl'] ?? data['image'] ?? '')
                .toString()
                .trim();
        if (img.isNotEmpty) matches.add(img);
        if (matches.length >= 2) break;
      }
    }
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('app_config')
          .doc('festival_banner')
          .snapshots(),
      builder: (context, snapshot) {
        final Map<String, dynamic> config =
            (snapshot.data?.data() as Map<String, dynamic>?) ?? {};

        final bool showFestivalBanner =
            (config['isActive'] as bool?) ?? true;
        final String festivalTitle =
            (config['festivalTitle'] ?? 'Diwali').toString().trim();
        final String festivalSubtitle =
            (config['festivalSubtitle'] ?? 'Feasting Prep').toString().trim();
        final String promoBannerTitle =
            (config['promoBannerTitle'] ?? 'FESTIVE GIFTS').toString().trim();
        final String promoBannerDiscount =
            (config['promoBannerDiscount'] ?? 'Up To 50% Off').toString().trim();
        final String deliveryHeadline = widget.isQuickMode
            ? (config['quickDeliveryText'] ??
                    'Delivery Before 10:00 AM • 15 Mins')
                .toString()
            : 'Scheduled Full Catalog Delivery';

        final Color headerPrimary = _parseColor(
          config['primaryColorHex']?.toString(),
          const Color(0xFFC81E45),
        );
        final Color headerDark = _parseColor(
          config['darkColorHex']?.toString(),
          const Color(0xFF9F1239),
        );

        String areaBold = 'Podalakur Road- ';
        String addressRest = widget.currentAddress;
        if (widget.currentAddress.contains('-')) {
          final parts = widget.currentAddress.split('-');
          areaBold = '${parts.first.trim()}- ';
          addressRest = parts.sublist(1).join('-').trim();
        } else if (widget.currentAddress.contains(',')) {
          final parts = widget.currentAddress.split(',');
          areaBold = '${parts.first.trim()}- ';
          addressRest = parts.sublist(1).join(',').trim();
        }

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [headerPrimary, headerDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => widget.onModeChanged(true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 44,
                              decoration: BoxDecoration(
                                color: widget.isQuickMode
                                    ? const Color(0xFF881337)
                                    : Colors.white.withAlpha(220),
                                borderRadius: BorderRadius.circular(14),
                                border: widget.isQuickMode
                                    ? Border.all(
                                        color: const Color(0xFFFACC15),
                                        width: 1.2,
                                      )
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.bolt_rounded,
                                    color: Color(0xFFFACC15),
                                    size: 22,
                                  ),
                                  Text(
                                    'Quick',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      color: widget.isQuickMode
                                          ? const Color(0xFFFDE047)
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => widget.onModeChanged(false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 44,
                              decoration: BoxDecoration(
                                color: !widget.isQuickMode
                                    ? const Color(0xFF881337)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  'ShopAll',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: !widget.isQuickMode
                                        ? const Color(0xFFFDE047)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.onAddressTap,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Delivery by',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  deliveryHeadline,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Flexible(
                                      child: RichText(
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: areaBold,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                            TextSpan(
                                              text: addressRest,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: widget.onProfileTap,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Color(0x40FFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE7F3),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF1E293B),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: widget.searchController,
                              onChanged: widget.onSearchChanged,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: _rotatingSearchHints[_hintIndex],
                                hintStyle: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (widget.searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.cancel_rounded,
                                size: 18,
                                color: Color(0xFF475569),
                              ),
                              onPressed: widget.onClearSearch,
                            ),
                          Container(
                            width: 1,
                            height: 22,
                            color: const Color(0xFFCBD5E1),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.mic_none_rounded,
                              color: Color(0xFF0F172A),
                              size: 22,
                            ),
                            tooltip: 'Voice Search',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Type or select any category below to filter products instantly!',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 58,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _topCategoryTabs.length,
                      itemBuilder: (context, index) {
                        final tab = _topCategoryTabs[index];
                        final String id = tab['id'] as String;
                        final String label = tab['label'] as String;
                        final IconData icon = tab['icon'] as IconData;
                        final bool isSelected = widget.selectedCategory == id;

                        return GestureDetector(
                          onTap: () => widget.onCategorySelected(id),
                          child: Container(
                            width: 78,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  icon,
                                  size: 22,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w900
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 3.5,
                                  width: isSelected ? 52 : 0,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (showFestivalBanner && widget.searchQuery.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      headerDark,
                      const Color(0xFFB45309),
                      const Color(0xFFFDE68A),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFFDE047),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Text(
                              festivalTitle,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFEF08A),
                                letterSpacing: 0.8,
                                shadows: [
                                  Shadow(
                                    color: Color(0x66000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              festivalSubtitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFFDE047),
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 172,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _buildFestiveSubCard(
                            title: 'Rice & Cereals',
                            keywords: const ['rice', 'sona', 'basmati', 'dal'],
                            fallbackIcon: Icons.rice_bowl_rounded,
                            onTap: () => widget
                                .onCategorySelected('Grocery / Supermarket'),
                          ),
                          _buildFestiveSubCard(
                            title: 'Atta & Flours',
                            keywords: const [
                              'atta',
                              'flour',
                              'wheat',
                              'rava',
                              'besan',
                            ],
                            fallbackIcon: Icons.bakery_dining_rounded,
                            onTap: () => widget
                                .onCategorySelected('Grocery / Supermarket'),
                          ),
                          _buildFestiveSubCard(
                            title: 'Oil & Ghee',
                            keywords: const ['oil', 'sunflower', 'ghee', 'gold'],
                            fallbackIcon: Icons.water_drop_rounded,
                            onTap: () => widget
                                .onCategorySelected('Grocery / Supermarket'),
                          ),
                          _buildFestiveSubCard(
                            title: 'Milk & Curd',
                            keywords: const ['milk', 'curd', 'paneer', 'butter'],
                            fallbackIcon: Icons.egg_alt_rounded,
                            onTap: () =>
                                widget.onCategorySelected('Milk & Dairy'),
                          ),
                          _buildFestiveSubCard(
                            title: 'Fresh Veggies',
                            keywords: const [
                              'tomato',
                              'onion',
                              'vegetable',
                              'fruit',
                            ],
                            fallbackIcon: Icons.eco_rounded,
                            onTap: () => widget
                                .onCategorySelected('Vegetables & Fruits'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF3E8FF),
                      Color(0xFFE9D5FF),
                      Color(0xFFFDF4FF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD8B4FE)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promoBannerTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF581C87),
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Special festive packs, sweets & daily essentials',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF6B21A8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC026D3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        promoBannerDiscount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFestiveSubCard({
    required String title,
    required List<String> keywords,
    required IconData fallbackIcon,
    required VoidCallback onTap,
  }) {
    final List<String> images = _findImagesForKeywords(keywords);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 118,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF9F1239),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: images.isEmpty
                  ? Center(
                      child: Icon(
                        fallbackIcon,
                        size: 54,
                        color: const Color(0xFFD97706),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        if (images.length > 1)
                          Positioned(
                            right: 4,
                            bottom: 4,
                            width: 64,
                            height: 76,
                            child: _buildImage(images[1]),
                          ),
                        Positioned(
                          left: images.length > 1 ? 4 : 14,
                          top: 2,
                          width: 72,
                          height: 88,
                          child: _buildImage(images[0]),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
