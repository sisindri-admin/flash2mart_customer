import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../widgets/home/jiomart_filters_bottom_sheet.dart';
import '../widgets/home/jiomart_popular_product_card.dart';

class CategoriesDirectoryScreen extends StatefulWidget {
  final String currentAddress;
  final VoidCallback onAddressTap;
  final VoidCallback onProfileTap;

  const CategoriesDirectoryScreen({
    super.key,
    required this.currentAddress,
    required this.onAddressTap,
    required this.onProfileTap,
  });

  @override
  State<CategoriesDirectoryScreen> createState() =>
      _CategoriesDirectoryScreenState();
}

class _CategoriesDirectoryScreenState extends State<CategoriesDirectoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedSubCategoryTitle;
  List<String> _selectedKeywords = const [];
  JioMartFilterSelection _activeFilter = const JioMartFilterSelection();
  static final Map<String, Uint8List> _imgCache = {};

  static const List<Map<String, dynamic>> _freshGroup = [
    {
      'title': 'Fresh\nVegetables',
      'keywords': ['vegetable', 'tomato', 'onion', 'potato', 'mirchi', 'carrot'],
      'icon': Icons.eco_rounded,
      'color': Color(0xFF16A34A),
    },
    {
      'title': 'Fresh Fruits',
      'keywords': ['fruit', 'apple', 'banana', 'orange', 'mango', 'papaya'],
      'icon': Icons.apple_rounded,
      'color': Color(0xFFDC2626),
    },
    {
      'title': 'Cakes, Rusk &\nMore',
      'keywords': ['cake', 'rusk', 'bakery', 'cookie'],
      'icon': Icons.cake_rounded,
      'color': Color(0xFF9333EA),
    },
    {
      'title': 'Breads &\nChapatis',
      'keywords': ['bread', 'chapati', 'roti', 'bun'],
      'icon': Icons.breakfast_dining_rounded,
      'color': Color(0xFFD97706),
    },
    {
      'title': 'Milk & Milk\nProducts',
      'keywords': [
        'milk',
        'curd',
        'dahi',
        'buttermilk',
        'lassi',
        'heritage',
        'amul',
      ],
      'icon': Icons.local_drink_rounded,
      'color': Color(0xFF0284C7),
    },
    {
      'title': 'Cheese,\nPaneer & Tofu',
      'keywords': ['cheese', 'paneer', 'butter', 'ghee', 'tofu'],
      'icon': Icons.egg_alt_rounded,
      'color': Color(0xFFEAB308),
    },
    {
      'title': 'Ice Cream &\nFrozen',
      'keywords': ['ice cream', 'frozen', 'kulfi', 'cone'],
      'icon': Icons.icecream_rounded,
      'color': Color(0xFFEC4899),
    },
  ];

  static const List<Map<String, dynamic>> _packagedFoodsGroup = [
    {
      'title': 'Chips &\nNamkeens',
      'keywords': ['chips', 'namkeen', 'snack', 'mixture', 'kurkure', 'lays'],
      'icon': Icons.fastfood_rounded,
      'color': Color(0xFFEA580C),
    },
    {
      'title': 'Biscuits &\nCookies',
      'keywords': ['biscuit', 'cookie', 'good day', 'marie', 'oreo'],
      'icon': Icons.cookie_rounded,
      'color': Color(0xFFB45309),
    },
    {
      'title': 'Chocolates &\nCandies',
      'keywords': ['chocolate', 'candy', 'dairy milk', 'toffee'],
      'icon': Icons.redeem_rounded,
      'color': Color(0xFF7C3AED),
    },
    {
      'title': 'Indian Sweets',
      'keywords': ['sweet', 'gulab', 'rasgulla', 'soan', 'laddu'],
      'icon': Icons.auto_awesome_rounded,
      'color': Color(0xFFDC2626),
    },
    {
      'title': 'Drinks &\nJuices',
      'keywords': ['drink', 'juice', 'soda', 'cola', 'water', 'tea', 'coffee'],
      'icon': Icons.local_cafe_rounded,
      'color': Color(0xFF059669),
    },
    {
      'title': 'Breakfast\nCereals',
      'keywords': ['oats', 'corn', 'muesli', 'cereal', 'poha'],
      'icon': Icons.rice_bowl_rounded,
      'color': Color(0xFFD97706),
    },
    {
      'title': 'Noodles, Pasta\n& Vermicelli',
      'keywords': ['noodle', 'maggi', 'pasta', 'vermicelli', 'semiya'],
      'icon': Icons.ramen_dining_rounded,
      'color': Color(0xFFDC2626),
    },
    {
      'title': 'Ready To Cook',
      'keywords': ['ready', 'instant', 'mix', 'soup', 'masala'],
      'icon': Icons.soup_kitchen_rounded,
      'color': Color(0xFF0284C7),
    },
  ];

  static const List<Map<String, dynamic>> _staplesAndHomeGroup = [
    {
      'title': 'Rice &\nCereals',
      'keywords': ['rice', 'sona', 'basmati', 'brown rice'],
      'icon': Icons.rice_bowl_rounded,
      'color': Color(0xFF00875A),
    },
    {
      'title': 'Atta &\nFlours',
      'keywords': ['atta', 'flour', 'maida', 'rava', 'besan'],
      'icon': Icons.bakery_dining_rounded,
      'color': Color(0xFFB45309),
    },
    {
      'title': 'Edible Oils\n& Ghee',
      'keywords': ['oil', 'sunflower', 'groundnut', 'ghee'],
      'icon': Icons.water_drop_rounded,
      'color': Color(0xFFD97706),
    },
    {
      'title': 'Dals &\nPulses',
      'keywords': ['dal', 'toor', 'moong', 'urad', 'chana', 'pulse'],
      'icon': Icons.grain_rounded,
      'color': Color(0xFFCA8A04),
    },
    {
      'title': 'Salt, Sugar\n& Jaggery',
      'keywords': ['salt', 'sugar', 'jaggery', 'bellam'],
      'icon': Icons.kitchen_rounded,
      'color': Color(0xFF2563EB),
    },
    {
      'title': 'Masalas &\nSpices',
      'keywords': ['masala', 'spice', 'turmeric', 'chilli powder'],
      'icon': Icons.whatshot_rounded,
      'color': Color(0xFFDC2626),
    },
    {
      'title': 'Medicines &\nWellness',
      'keywords': ['medicine', 'pharma', 'health', 'tablet'],
      'icon': Icons.medical_services_rounded,
      'color': Color(0xFF059669),
    },
    {
      'title': 'Electronics &\nHome',
      'keywords': ['electronic', 'mobile', 'cable', 'bulb', 'appliance'],
      'icon': Icons.devices_other_rounded,
      'color': Color(0xFF4F46E5),
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _buildMiniThumb(
    String imageStr,
    IconData fallbackIcon,
    Color iconCol,
  ) {
    final String trimmed = imageStr.trim();
    if (trimmed.isEmpty) {
      return Icon(fallbackIcon, size: 36, color: iconCol);
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      Uint8List? bytes = _imgCache[trimmed];
      if (bytes == null) {
        try {
          final String clean =
              trimmed.contains(',') ? trimmed.split(',').last : trimmed;
          bytes = base64Decode(clean.trim());
          _imgCache[trimmed] = bytes;
        } catch (_) {
          return Icon(fallbackIcon, size: 36, color: iconCol);
        }
      }
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            Icon(fallbackIcon, size: 36, color: iconCol),
      );
    }

    return Image.network(
      trimmed,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) =>
          Icon(fallbackIcon, size: 36, color: iconCol),
    );
  }

  String _findMatchingImage(
    List<QueryDocumentSnapshot> allDocs,
    List<String> keywords,
  ) {
    for (final doc in allDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final String text =
          '${data['name'] ?? ''} ${data['category'] ?? ''}'.toLowerCase();
      final String img =
          (data['imageBase64'] ?? data['imageUrl'] ?? data['image'] ?? '')
              .toString()
              .trim();
      if (img.isEmpty) continue;
      for (final kw in keywords) {
        if (text.contains(kw)) return img;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    String areaHeadline = 'Podalakur Road';
    String addressRest = widget.currentAddress;
    if (widget.currentAddress.contains('-')) {
      final parts = widget.currentAddress.split('-');
      areaHeadline = parts.first.trim();
      addressRest = parts.sublist(1).join('-').trim();
    } else if (widget.currentAddress.contains(',')) {
      final parts = widget.currentAddress.split(',');
      areaHeadline = parts.first.trim();
      addressRest = parts.sublist(1).join(',').trim();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        final List<QueryDocumentSnapshot> allDocs = snapshot.data?.docs ?? [];

        if (_selectedSubCategoryTitle != null) {
          return _buildSubCategoryDrilldownView(
            context,
            allDocs,
            addressRest,
          );
        }

        return SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFF59E0B),
                      Color(0xFFFBBF24),
                      Color(0xFFFEF3C7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.onAddressTap,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Delivery to',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF451A03),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  areaHeadline,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        addressRest,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF451A03),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: Color(0xFF451A03),
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
                              color: Color(0x66FFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Color(0xFF451A03),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
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
                              controller: _searchCtrl,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v.trim()),
                              decoration: const InputDecoration(
                                hintText:
                                    'Search for "stationery", "milk", "rice"',
                                hintStyle: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.cancel_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                          const Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: Icon(
                              Icons.mic_none_rounded,
                              color: Color(0xFF0F172A),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategoryGroupSection(
                        groupTitle: 'Fresh',
                        items: _freshGroup,
                        allDocs: allDocs,
                      ),
                      const SizedBox(height: 20),
                      _buildCategoryGroupSection(
                        groupTitle: 'Biscuits, Drinks & Packaged Foods',
                        items: _packagedFoodsGroup,
                        allDocs: allDocs,
                      ),
                      const SizedBox(height: 20),
                      _buildCategoryGroupSection(
                        groupTitle: 'Cooking & Household Essentials',
                        items: _staplesAndHomeGroup,
                        allDocs: allDocs,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryGroupSection({
    required String groupTitle,
    required List<Map<String, dynamic>> items,
    required List<QueryDocumentSnapshot> allDocs,
  }) {
    final filteredItems = _searchQuery.isEmpty
        ? items
        : items.where((item) {
            final String t = (item['title'] as String).toLowerCase();
            final List<String> kws =
                (item['keywords'] as List).map((e) => e.toString()).toList();
            return t.contains(_searchQuery.toLowerCase()) ||
                kws.any((k) => k.contains(_searchQuery.toLowerCase()));
          }).toList();

    if (filteredItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          groupTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.68,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            final String title = item['title'] as String;
            final List<String> keywords =
                (item['keywords'] as List).map((e) => e.toString()).toList();
            final IconData fallbackIcon = item['icon'] as IconData;
            final Color iconColor = item['color'] as Color;
            final String matchedImg = _findMatchingImage(allDocs, keywords);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSubCategoryTitle = title.replaceAll('\n', ' ');
                  _selectedKeywords = keywords;
                });
              },
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9EE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Center(
                        child: _buildMiniThumb(
                          matchedImg,
                          fallbackIcon,
                          iconColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 30,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubCategoryDrilldownView(
    BuildContext context,
    List<QueryDocumentSnapshot> allDocs,
    String shortAddress,
  ) {
    List<QueryDocumentSnapshot> matchingDocs = allDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final String combined =
          '${data['name'] ?? ''} ${data['category'] ?? ''} ${data['description'] ?? ''}'
              .toLowerCase();
      for (final kw in _selectedKeywords) {
        if (combined.contains(kw.toLowerCase())) return true;
      }
      return false;
    }).toList();

    if (matchingDocs.isEmpty) {
      matchingDocs = allDocs;
    }

    if (_activeFilter.hasAnyFilter) {
      matchingDocs = matchingDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final String name = (data['name'] ?? '').toString().toLowerCase();
        final String cat = (data['category'] ?? '').toString();
        final double price = ((data['price'] ?? 0) as num).toDouble();
        final double mrp = ((data['marketPrice'] ?? price) as num).toDouble();
        final int disc =
            mrp > price && mrp > 0 ? (((mrp - price) / mrp) * 100).round() : 0;

        if (_activeFilter.selectedBrands.isNotEmpty) {
          final bool brandMatch = _activeFilter.selectedBrands
              .any((b) => name.contains(b.toLowerCase()));
          if (!brandMatch) return false;
        }
        if (_activeFilter.selectedCategories.isNotEmpty) {
          if (!_activeFilter.selectedCategories.contains(cat)) return false;
        }
        if (_activeFilter.selectedDiscount.isNotEmpty) {
          final int minD = int.tryParse(_activeFilter.selectedDiscount) ?? 0;
          if (disc < minD) return false;
        }
        if (_activeFilter.selectedPriceRange == 'Under ₹50' && price >= 50) {
          return false;
        }
        if (_activeFilter.selectedPriceRange == '₹50 - ₹199' &&
            (price < 50 || price > 199)) {
          return false;
        }
        if (_activeFilter.selectedPriceRange == '₹200 & Above' && price < 200) {
          return false;
        }
        return true;
      }).toList();
    }

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            color: Colors.white,
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSubCategoryTitle = null;
                      _activeFilter = const JioMartFilterSelection();
                    });
                  },
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.chevron_left_rounded, size: 24),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onAddressTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedSubCategoryTitle ?? 'Category',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                'Delivering to : ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0078AD),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  shortAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 14,
                                color: Color(0xFF475569),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.search_rounded, size: 20),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            color: Colors.white,
            child: Row(
              children: [
                InkWell(
                  onTap: () async {
                    final result = await JioMartFiltersBottomSheet.show(
                      context,
                      allProducts: allDocs,
                      currentSelection: _activeFilter,
                    );
                    if (result != null) {
                      setState(() => _activeFilter = result);
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _activeFilter.hasAnyFilter
                          ? const Color(0xFFEFF6FF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _activeFilter.hasAnyFilter
                            ? const Color(0xFF0078AD)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: Color(0xFF0078AD),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0078AD),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () async {
                    final result = await JioMartFiltersBottomSheet.show(
                      context,
                      allProducts: allDocs,
                      currentSelection: _activeFilter,
                    );
                    if (result != null) {
                      setState(() => _activeFilter = result);
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Brands',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 180),
              itemCount: matchingDocs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.48,
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
              ),
              itemBuilder: (context, index) {
                final doc = matchingDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                final String pId = doc.id;
                final String pName =
                    (data['name'] ?? data['title'] ?? 'Product').toString();
                final double pPrice =
                    ((data['price'] ?? 0) as num).toDouble();
                final double pMrp =
                    ((data['marketPrice'] ?? pPrice) as num).toDouble();
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
            ),
          ),
        ],
      ),
    );
  }
}
