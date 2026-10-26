import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class JioMartFilterSelection {
  final Set<String> selectedBrands;
  final Set<String> selectedCategories;
  final String selectedDiscount;
  final String selectedPriceRange;

  const JioMartFilterSelection({
    this.selectedBrands = const {},
    this.selectedCategories = const {},
    this.selectedDiscount = '',
    this.selectedPriceRange = '',
  });

  bool get hasAnyFilter =>
      selectedBrands.isNotEmpty ||
      selectedCategories.isNotEmpty ||
      selectedDiscount.isNotEmpty ||
      selectedPriceRange.isNotEmpty;
}

class JioMartFiltersBottomSheet extends StatefulWidget {
  final List<QueryDocumentSnapshot> allProducts;
  final JioMartFilterSelection initialSelection;

  const JioMartFiltersBottomSheet({
    super.key,
    required this.allProducts,
    required this.initialSelection,
  });

  static Future<JioMartFilterSelection?> show(
    BuildContext context, {
    required List<QueryDocumentSnapshot> allProducts,
    required JioMartFilterSelection currentSelection,
  }) {
    return showModalBottomSheet<JioMartFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JioMartFiltersBottomSheet(
        allProducts: allProducts,
        initialSelection: currentSelection,
      ),
    );
  }

  @override
  State<JioMartFiltersBottomSheet> createState() =>
      _JioMartFiltersBottomSheetState();
}

class _JioMartFiltersBottomSheetState extends State<JioMartFiltersBottomSheet> {
  String _activeLeftTab = 'Brands';
  final TextEditingController _brandSearchCtrl = TextEditingController();
  String _brandSearchQuery = '';

  late Set<String> _brands;
  late Set<String> _categories;
  late String _discount;
  late String _priceRange;

  static const List<String> _leftTabs = [
    'Brands',
    'Categories',
    'Country of Origin',
    'Departments',
    'Discount',
    'Price',
  ];

  @override
  void initState() {
    super.initState();
    _brands = Set<String>.from(widget.initialSelection.selectedBrands);
    _categories = Set<String>.from(widget.initialSelection.selectedCategories);
    _discount = widget.initialSelection.selectedDiscount;
    _priceRange = widget.initialSelection.selectedPriceRange;
  }

  @override
  void dispose() {
    _brandSearchCtrl.dispose();
    super.dispose();
  }

  Map<String, int> _extractBrandCounts() {
    final Map<String, int> counts = {
      'Heritage': 4,
      'Amul': 5,
      'Aashirvaad': 3,
      'Fortune': 3,
      'Good Life': 4,
      'Jersey': 2,
      'Saffola': 2,
      'Daawat': 2,
    };

    for (final doc in widget.allProducts) {
      final data = doc.data() as Map<String, dynamic>;
      final String name = (data['name'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        final String firstWord = name.split(' ').first;
        if (firstWord.length >= 3) {
          counts[firstWord] = (counts[firstWord] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  Map<String, int> _extractCategoryCounts() {
    final Map<String, int> counts = {
      'Vegetables & Fruits': 0,
      'Grocery / Supermarket': 0,
      'Milk & Dairy': 0,
      'Medicines & Pharmacy': 0,
      'Electronics Store': 0,
    };
    for (final doc in widget.allProducts) {
      final data = doc.data() as Map<String, dynamic>;
      final String cat =
          (data['category'] ?? 'Grocery / Supermarket').toString().trim();
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts;
  }

  void _clearAll() {
    setState(() {
      _brands.clear();
      _categories.clear();
      _discount = '';
      _priceRange = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> activeChipLabels = [
      ..._brands,
      ..._categories,
      if (_discount.isNotEmpty) '$_discount% & above',
      if (_priceRange.isNotEmpty) _priceRange,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: const BoxDecoration(
              color: Color(0xB31E293B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.76,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (activeChipLabels.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 36,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: activeChipLabels.length,
                          itemBuilder: (context, idx) {
                            final label = activeChipLabels[idx];
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _brands.remove(label);
                                        _categories.remove(label);
                                        if ('$label'.contains('%')) {
                                          _discount = '';
                                        }
                                        if (label == _priceRange) {
                                          _priceRange = '';
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF94A3B8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 140,
                      color: const Color(0xFFF8FAFC),
                      child: ListView.builder(
                        itemCount: _leftTabs.length,
                        itemBuilder: (context, index) {
                          final tab = _leftTabs[index];
                          final bool isSelected = _activeLeftTab == tab;

                          return GestureDetector(
                            onTap: () => setState(() => _activeLeftTab = tab),
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEFF6FF)
                                    : Colors.transparent,
                                border: Border(
                                  right: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF0078AD)
                                        : Colors.transparent,
                                    width: 3.5,
                                  ),
                                ),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                tab,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFF0078AD)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: _buildRightPaneContent(),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEFF6FF),
                              foregroundColor: const Color(0xFF0078AD),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: _clearAll,
                            child: const Text(
                              'Clear all',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0078AD),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(
                                context,
                                JioMartFilterSelection(
                                  selectedBrands: _brands,
                                  selectedCategories: _categories,
                                  selectedDiscount: _discount,
                                  selectedPriceRange: _priceRange,
                                ),
                              );
                            },
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightPaneContent() {
    if (_activeLeftTab == 'Brands') {
      final brandMap = _extractBrandCounts();
      final entries = brandMap.entries
          .where(
            (e) => e.key.toLowerCase().contains(_brandSearchQuery.toLowerCase()),
          )
          .toList();

      return Column(
        children: [
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF475569),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _brandSearchCtrl,
                    onChanged: (v) => setState(() => _brandSearchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, idx) {
                final entry = entries[idx];
                final bool checked = _brands.contains(entry.key);
                return CheckboxListTile(
                  value: checked,
                  activeColor: const Color(0xFF0078AD),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${entry.key} (${entry.value})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _brands.add(entry.key);
                      } else {
                        _brands.remove(entry.key);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    if (_activeLeftTab == 'Categories' || _activeLeftTab == 'Departments') {
      final catMap = _extractCategoryCounts();
      final entries = catMap.entries.toList();
      return ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, idx) {
          final entry = entries[idx];
          final bool checked = _categories.contains(entry.key);
          return CheckboxListTile(
            value: checked,
            activeColor: const Color(0xFF0078AD),
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${entry.key} (${entry.value})',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _categories.add(entry.key);
                } else {
                  _categories.remove(entry.key);
                }
              });
            },
          );
        },
      );
    }

    if (_activeLeftTab == 'Discount') {
      final List<Map<String, String>> discounts = [
        {'id': '10', 'label': '10% Off or more'},
        {'id': '20', 'label': '20% Off or more'},
        {'id': '30', 'label': '30% Off or more'},
      ];
      return ListView(
        children: discounts.map((d) {
          final String id = d['id']!;
          return CheckboxListTile(
            value: _discount == id,
            activeColor: const Color(0xFF0078AD),
            contentPadding: EdgeInsets.zero,
            title: Text(d['label']!),
            onChanged: (val) {
              setState(() => _discount = val == true ? id : '');
            },
          );
        }).toList(),
      );
    }

    if (_activeLeftTab == 'Price') {
      final List<Map<String, String>> prices = [
        {'id': 'Under ₹50', 'label': 'Under ₹50'},
        {'id': '₹50 - ₹199', 'label': '₹50 - ₹199'},
        {'id': '₹200 & Above', 'label': '₹200 & Above'},
      ];
      return ListView(
        children: prices.map((p) {
          final String id = p['id']!;
          return CheckboxListTile(
            value: _priceRange == id,
            activeColor: const Color(0xFF0078AD),
            contentPadding: EdgeInsets.zero,
            title: Text(p['label']!),
            onChanged: (val) {
              setState(() => _priceRange = val == true ? id : '');
            },
          );
        }).toList(),
      );
    }

    return ListView(
      children: [
        CheckboxListTile(
          value: true,
          activeColor: const Color(0xFF0078AD),
          contentPadding: EdgeInsets.zero,
          title: const Text('India (100% Local & Fresh)'),
          onChanged: (_) {},
        ),
      ],
    );
  }
}
