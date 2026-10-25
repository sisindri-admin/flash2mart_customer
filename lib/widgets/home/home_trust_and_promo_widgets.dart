import 'package:flutter/material.dart';

class CategoryItemMeta {
  final String id;
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const CategoryItemMeta({
    required this.id,
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Row(
            children: [
              Text(
                'Shop by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(width: 6),
              Text(
                '• Fresh & Verified',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00875A),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 98,
          child: ListView.builder(
            key: const PageStorageKey('visual_categories_list'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final item = categories[index];
              final bool isSelected = selectedCategory == item.id;

              return GestureDetector(
                onTap: () => onCategorySelected(item.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 82,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00875A)
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00875A)
                              : item.bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          color: isSelected ? Colors.white : item.iconColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF00875A)
                              : const Color(0xFF334155),
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
