import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class CategoryThemeColors {
  final Color bgColor;
  final Color borderColor;
  final Color accentColor;
  const CategoryThemeColors(this.bgColor, this.borderColor, this.accentColor);
}

class CategoryColorPalette {
  static const List<CategoryThemeColors> _rotating = [
    CategoryThemeColors(Color(0xFFF0FDF4), Color(0xFFBBF7D0), Color(0xFF16A34A)), // Mint Green
    CategoryThemeColors(Color(0xFFFFFBEB), Color(0xFFFDE68A), Color(0xFFD97706)), // Warm Amber
    CategoryThemeColors(Color(0xFFF0F9FF), Color(0xFFBAE6FD), Color(0xFF0284C7)), // Ice Blue
    CategoryThemeColors(Color(0xFFFFF1F2), Color(0xFFFECDD3), Color(0xFFE11D48)), // Soft Rose
    CategoryThemeColors(Color(0xFFFAF5FF), Color(0xFFE9D5FF), Color(0xFF7C3AED)), // Soft Lavender
    CategoryThemeColors(Color(0xFFF0FDFA), Color(0xFF99F6E4), Color(0xFF0D9488)), // Soft Teal
  ];

  static CategoryThemeColors getColors(String name, {int index = 0}) {
    final lower = name.toLowerCase().trim();
    if (lower == 'all' || lower == 'all items') {
      return const CategoryThemeColors(Color(0xFFEFF6FF), Color(0xFFBFDBFE), Color(0xFF0284C7));
    }
    if (lower.contains('non-veg') || lower.contains('nonveg') || lower.contains('meat') || lower.contains('chicken') || lower.contains('mutton')) {
      return const CategoryThemeColors(Color(0xFFFFF1F2), Color(0xFFFECDD3), Color(0xFFE11D48));
    }
    if (lower.contains('sea') || lower.contains('fish') || lower.contains('dairy') || lower.contains('milk') || lower.contains('curd')) {
      return const CategoryThemeColors(Color(0xFFF0F9FF), Color(0xFFBAE6FD), Color(0xFF0284C7));
    }
    if (lower.contains('fruit') || lower.contains('veg') || lower.contains('mango') || lower.contains('apple') || lower.contains('leafy')) {
      return const CategoryThemeColors(Color(0xFFF0FDF4), Color(0xFFBBF7D0), Color(0xFF16A34A));
    }
    if (lower.contains('grocery') || lower.contains('atta') || lower.contains('rice') || lower.contains('oil') || lower.contains('dal') || lower.contains('bread')) {
      return const CategoryThemeColors(Color(0xFFFFFBEB), Color(0xFFFDE68A), Color(0xFFD97706));
    }
    if (lower.contains('combo') || lower.contains('snack') || lower.contains('sweet') || lower.contains('drink') || lower.contains('grape')) {
      return const CategoryThemeColors(Color(0xFFFAF5FF), Color(0xFFE9D5FF), Color(0xFF7C3AED));
    }
    if (lower.contains('medicine') || lower.contains('pharma')) {
      return const CategoryThemeColors(Color(0xFFFEF2F2), Color(0xFFFECACA), Color(0xFFDC2626));
    }
    return _rotating[index % _rotating.length];
  }
}

class CategoryItemMeta {
  final String id;
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final String imageStr;
  final String emoji;

  const CategoryItemMeta({
    required this.id,
    required this.label,
    required this.icon,
    required this.bgColor,
    this.borderColor = const Color(0xFFE2E8F0),
    required this.iconColor,
    this.imageStr = '',
    this.emoji = '',
  });
}

class HomeTrustBadgeStrip extends StatelessWidget {
  const HomeTrustBadgeStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrustItem(
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
            title: '15 Mins Delivery',
            subtitle: 'Superfast doorstep',
          ),
          Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
          _buildTrustItem(
            icon: Icons.verified_rounded,
            iconColor: const Color(0xFF16A34A),
            bgColor: const Color(0xFFDCFCE7),
            title: '100% Farm Fresh',
            subtitle: 'Quality checked',
          ),
          Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
          _buildTrustItem(
            icon: Icons.payments_rounded,
            iconColor: const Color(0xFF2563EB),
            bgColor: const Color(0xFFDBEAFE),
            title: 'COD Available',
            subtitle: 'Easy replacements',
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class HomeCategoryGridSection extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const HomeCategoryGridSection({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const List<CategoryItemMeta> categories = [
    CategoryItemMeta(
      id: 'All',
      label: 'All Items',
      icon: Icons.grid_view_rounded,
      bgColor: Color(0xFFE0F2FE),
      iconColor: Color(0xFF0284C7),
    ),
    CategoryItemMeta(
      id: 'Vegetables & Fruits',
      label: 'Veggies & Fruits',
      icon: Icons.eco_rounded,
      bgColor: Color(0xFFDCFCE7),
      iconColor: Color(0xFF16A34A),
    ),
    CategoryItemMeta(
      id: 'Grocery / Supermarket',
      label: 'Daily Grocery',
      icon: Icons.shopping_basket_rounded,
      bgColor: Color(0xFFFEF3C7),
      iconColor: Color(0xFFD97706),
    ),
    CategoryItemMeta(
      id: 'Medicines & Pharmacy',
      label: 'Pharmacy',
      icon: Icons.medical_services_rounded,
      bgColor: Color(0xFFFEE2E2),
      iconColor: Color(0xFFDC2626),
    ),
    CategoryItemMeta(
      id: 'Electronics Store',
      label: 'Electronics',
      icon: Icons.devices_other_rounded,
      bgColor: Color(0xFFF3E8FF),
      iconColor: Color(0xFF9333EA),
    ),
  ];

  static final Map<String, MemoryImage> _catImageCache = {};

  Widget _buildCategoryVisual(CategoryItemMeta item, bool isSelected) {
    final img = item.imageStr.trim();
    if (img.isNotEmpty) {
      if (img.startsWith('http://') || img.startsWith('https://')) {
        return ClipOval(
          child: Image.network(
            img,
            width: 34,
            height: 34,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              item.icon,
              color: isSelected ? Colors.white : item.iconColor,
              size: 18,
            ),
          ),
        );
      }
      if (img.startsWith('data:image') || img.length > 40) {
        MemoryImage? mem = _catImageCache[img];
        if (mem == null) {
          try {
            final clean = img.contains(',') ? img.split(',').last : img;
            final Uint8List bytes = base64Decode(clean.trim());
            mem = MemoryImage(bytes);
            _catImageCache[img] = mem;
          } catch (_) {}
        }
        if (mem != null) {
          return ClipOval(
            child: Image(
              image: mem,
              width: 34,
              height: 34,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          );
        }
      }
    }
    if (item.emoji.trim().isNotEmpty) {
      return Center(
        child: Text(
          item.emoji.trim(),
          style: const TextStyle(fontSize: 16),
        ),
      );
    }
    return Icon(
      item.icon,
      color: isSelected ? Colors.white : item.iconColor,
      size: 18,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        List<CategoryItemMeta> displayCategories = List.from(categories);

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final activeDocs = snapshot.data!.docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['isActive'] != false;
          }).toList();

          activeDocs.sort((a, b) {
            final aOrd = ((a.data() as Map<String, dynamic>)['order'] ?? 99);
            final bOrd = ((b.data() as Map<String, dynamic>)['order'] ?? 99);
            final int aInt = aOrd is num ? aOrd.toInt() : 99;
            final int bInt = bOrd is num ? bOrd.toInt() : 99;
            return aInt.compareTo(bInt);
          });

          if (activeDocs.isNotEmpty) {
            displayCategories = [
              categories.first, // Keep 'All Items'
              ...activeDocs.asMap().entries.map((entry) {
                final idx = entry.key;
                final doc = entry.value;
                final data = doc.data() as Map<String, dynamic>;
                final String name = (data['name'] ?? data['title'] ?? 'Category').toString();
                final String imgStr = (data['imageBase64'] ?? data['imageUrl'] ?? '').toString();
                final String iconField = (data['icon'] ?? '').toString();
                final String emoji = (iconField.isNotEmpty && !iconField.startsWith('http') && iconField.length <= 6) ? iconField : '';
                final pal = CategoryColorPalette.getColors(name, index: idx);

                return CategoryItemMeta(
                  id: name,
                  label: name,
                  icon: Icons.category_rounded,
                  bgColor: pal.bgColor,
                  borderColor: pal.borderColor,
                  iconColor: pal.accentColor,
                  imageStr: imgStr.isNotEmpty ? imgStr : (iconField.startsWith('http') ? iconField : ''),
                  emoji: emoji,
                );
              }),
            ];
          }
        }

        return SizedBox(
          height: 58,
          child: ListView.builder(
            key: const PageStorageKey('visual_categories_list'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: displayCategories.length,
            itemBuilder: (context, index) {
              final item = displayCategories[index];
              final bool isSelected = selectedCategory == item.id;

              return GestureDetector(
                onTap: () => onCategorySelected(item.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 58,
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? const Color(0xFF00875A) : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: item.bgColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? item.iconColor : item.borderColor,
                            width: isSelected ? 1.6 : 1.0,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildCategoryVisual(item, isSelected),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight:
                              isSelected ? FontWeight.w900 : FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFF00875A)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class HomeQuickFilterBar extends StatelessWidget {
  final String activeFilter;
  final ValueChanged<String> onFilterSelected;

  const HomeQuickFilterBar({
    super.key,
    required this.activeFilter,
    required this.onFilterSelected,
  });

  static const List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'All Products', 'icon': Icons.apps_rounded},
    {'id': 'offers', 'label': 'Best Offers %', 'icon': Icons.local_offer_rounded},
    {'id': 'under99', 'label': 'Under ₹99', 'icon': Icons.currency_rupee_rounded},
    {'id': 'instock', 'label': 'In Stock', 'icon': Icons.check_circle_outline_rounded},
    {'id': 'price_asc', 'label': 'Price: Low to High', 'icon': Icons.sort_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final f = _filters[index];
          final String id = f['id'] as String;
          final String label = f['label'] as String;
          final IconData icon = f['icon'] as IconData;
          final bool isSelected = activeFilter == id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onFilterSelected(id),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected ? Colors.amber : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
