import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_skeleton_grid.dart';
import '../widgets/home/home_trust_and_promo_widgets.dart';
import 'checkout_screen.dart';

class SubCategoryExplorerScreen extends StatefulWidget {
  final String mainCategoryName;
  final String subCategoryName;
  final String subCategoryImage;
  final List<Map<String, dynamic>> allSubCategories;
  final List<Map<String, dynamic>> childCategories;
  final String deliveryAddress;

  const SubCategoryExplorerScreen({
    super.key,
    required this.mainCategoryName,
    required this.subCategoryName,
    this.subCategoryImage = '',
    this.allSubCategories = const [],
    this.childCategories = const [],
    this.deliveryAddress = 'Nellore',
  });

  @override
  State<SubCategoryExplorerScreen> createState() => _SubCategoryExplorerScreenState();
}

class _SubCategoryExplorerScreenState extends State<SubCategoryExplorerScreen> {
  late String _selectedSubCategory;
  String _selectedChildFilter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _selectedSubCategory = widget.subCategoryName.isNotEmpty ? widget.subCategoryName : 'All';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getActiveChildChips() {
    if (_selectedSubCategory == 'All') return const [];
    for (final sub in widget.allSubCategories) {
      final sName = (sub['name'] ?? '').toString().trim();
      if (sName.toLowerCase() == _selectedSubCategory.toLowerCase()) {
        if (sub['childCategories'] is List) {
          return (sub['childCategories'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }
    if (_selectedSubCategory.toLowerCase() == widget.subCategoryName.toLowerCase()) {
      return widget.childCategories;
    }
    return const [];
  }

  Widget _buildThumb(String name, String imgStr, bool isSelected) {
    final trimmed = imgStr.trim();
    if (trimmed.isNotEmpty) {
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return Image.network(
          trimmed,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Icon(
            Icons.category_rounded,
            color: isSelected ? const Color(0xFF00875A) : const Color(0xFF64748B),
            size: 17,
          ),
        );
      }
      try {
        final clean = trimmed.contains(',') ? trimmed.split(',').last : trimmed;
        return Image.memory(base64Decode(clean.trim()), fit: BoxFit.cover);
      } catch (_) {}
    }
    return Icon(
      name == 'All' ? Icons.grid_view_rounded : Icons.local_mall_rounded,
      color: isSelected ? const Color(0xFF00875A) : const Color(0xFF64748B),
      size: 17,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build Left Sidebar: Top 'All' + All Sibling Sub-Categories (with selected one highlighted!)
    final List<Map<String, dynamic>> leftRailItems = [
      {'name': 'All', 'imageUrl': ''},
    ];

    if (widget.allSubCategories.isNotEmpty) {
      leftRailItems.addAll(widget.allSubCategories);
    } else if (widget.subCategoryName.isNotEmpty && widget.subCategoryName != 'All') {
      leftRailItems.add({
        'name': widget.subCategoryName,
        'imageUrl': widget.subCategoryImage,
      });
    }

    final List<Map<String, dynamic>> childChips = _getActiveChildChips();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search items...',
                  border: InputBorder.none,
                  isDense: true,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedSubCategory == 'All' ? widget.mainCategoryName : _selectedSubCategory,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    'Delivering to: ${widget.deliveryAddress}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF00875A), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search_rounded, color: const Color(0xFF0F172A)),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              // LEFT SIDE VERTICAL RAIL: 'All' + Sibling Sub-Categories (e.g. Mango [selected], Apple, Grapes)
              Container(
                width: 68,
                color: const Color(0xFFF8FAFC),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: leftRailItems.length,
                  itemBuilder: (context, idx) {
                    final item = leftRailItems[idx];
                    final String itemName = (item['name'] ?? 'Item').toString();
                    final String itemImg = (item['imageBase64'] ?? item['imageUrl'] ?? '').toString();
                    final bool isSel = _selectedSubCategory.toLowerCase() == itemName.toLowerCase();

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSubCategory = itemName;
                          _selectedChildFilter = 'All';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? Colors.white : const Color(0xFFF8FAFC),
                          border: Border(
                            left: BorderSide(
                              color: isSel ? const Color(0xFF00875A) : Colors.transparent,
                              width: 3.5,
                            ),
                            bottom: const BorderSide(color: Color(0xFFE2E8F0), width: 0.4),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: CategoryColorPalette.getColors(itemName, index: idx).bgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel
                                      ? CategoryColorPalette.getColors(itemName, index: idx).accentColor
                                      : CategoryColorPalette.getColors(itemName, index: idx).borderColor,
                                  width: isSel ? 1.5 : 1.0,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _buildThumb(itemName, itemImg, isSel),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              itemName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                                color: isSel ? const Color(0xFF00875A) : const Color(0xFF0F172A),
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(width: 1, color: const Color(0xFFE2E8F0)),

              // RIGHT SIDE: Optional Child Filter Chips + 2-Column Products Grid
              Expanded(
                child: Column(
                  children: [
                    if (childChips.isNotEmpty)
                      Container(
                        height: 42,
                        color: Colors.white,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          children: [
                            _buildChildChip('All'),
                            ...childChips.map((ch) => _buildChildChip((ch['name'] ?? '').toString())),
                          ],
                        ),
                      ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('products')
                            .where('isApproved', isEqualTo: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const ShimmerProductSkeletonGrid(crossAxisCount: 2, itemCount: 6, childAspectRatio: 0.68);
                          }

                          final allApproved = snapshot.hasData
                              ? snapshot.data!.docs.where((doc) {
                                  final d = doc.data() as Map<String, dynamic>;
                                  final bool isApp = d['isApproved'] == true;
                                  final String s = (d['status'] ?? d['approvalStatus'] ?? '').toString().toLowerCase();
                                  return isApp && s != 'pending' && s != 'pending_approval' && s != 'rejected' && s != 'paused';
                                }).toList()
                              : <QueryDocumentSnapshot>[];

                          final filtered = allApproved.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final pName = (data['name'] ?? data['title'] ?? '').toString().toLowerCase();
                            final pCat = (data['category'] ?? '').toString().toLowerCase();
                            final pSub = (data['subCategory'] ?? '').toString().toLowerCase();
                            final pChild = (data['childCategory'] ?? '').toString().toLowerCase();

                            final mainCat = widget.mainCategoryName.toLowerCase().trim();
                            final selSub = _selectedSubCategory.toLowerCase().trim();

                            // 1. Main category check
                            if (mainCat != 'all' && !pCat.contains(mainCat) && !pSub.contains(selSub)) {
                              return false;
                            }

                            // 2. Strict Selected Sub-Category filter (e.g. Mango -> ONLY Mango products!)
                            if (selSub != 'all' && selSub != mainCat) {
                              final bool matchesSub = (pSub == selSub) ||
                                  pSub.contains(selSub) ||
                                  (pChild == selSub) ||
                                  pChild.contains(selSub) ||
                                  (pSub.isEmpty && pName.contains(selSub));
                              if (!matchesSub) return false;
                            }

                            // 3. Optional Level-3 Child filter chip
                            if (_selectedChildFilter != 'All') {
                              final ch = _selectedChildFilter.toLowerCase().trim();
                              final bool matchesChild = (pChild == ch) ||
                                  pChild.contains(ch) ||
                                  (pChild.isEmpty && pName.contains(ch));
                              if (!matchesChild) return false;
                            }

                            if (_searchQuery.isNotEmpty && !pName.contains(_searchQuery)) {
                              return false;
                            }

                            return true;
                          }).toList();

                          if (filtered.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.shopping_basket_outlined, size: 46, color: Color(0xFF94A3B8)),
                                    const SizedBox(height: 10),
                                    Text(
                                      _selectedSubCategory == 'All'
                                          ? 'No products in ${widget.mainCategoryName} yet.'
                                          : 'No products in $_selectedSubCategory yet.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF334155)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
                            itemCount: filtered.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 4,
                            ),
                            itemBuilder: (context, idx) {
                              final doc = filtered[idx];
                              final data = doc.data() as Map<String, dynamic>;
                              final pId = doc.id;
                              final pName = (data['name'] ?? data['title'] ?? 'Product').toString();
                              final pPrice = ((data['price'] ?? 0) as num).toDouble();
                              final pMrp = ((data['marketPrice'] ?? pPrice) as num).toDouble();
                              final pUnit = (data['unit'] ?? data['weight'] ?? '1 unit').toString();
                              final pImg = (data['imageBase64'] ?? data['imageUrl'] ?? data['image'] ?? '').toString();
                              final pStock = ((data['stock'] ?? 1) as num).toInt();
                              final pMerch = (data['merchantId'] ?? '').toString();
                              final pCat = (data['category'] ?? '').toString();
                              final pDesc = (data['description'] ?? '').toString();
                              final bool isCombo = data['isCombo'] == true || data['isComboOffer'] == true;
                              final String comboItems = (data['comboItems'] ?? '').toString();
                              final List<String> comboImages = (data['images'] is List)
                                  ? (data['images'] as List).map((e) => e.toString()).toList()
                                  : const [];
                              final List<Map<String, dynamic>> comboList = (data['comboProductsList'] is List)
                                  ? (data['comboProductsList'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
                                  : const [];

                              return Selector<CartProvider, int>(
                                selector: (c, cart) => cart.items[pId]?.quantity ?? 0,
                                builder: (c, qty, _) {
                                  return ProductCard(
                                    key: ValueKey('subexp_${_selectedSubCategory}_${_selectedChildFilter}_$pId'),
                                    id: pId,
                                    name: pName,
                                    price: pPrice,
                                    marketPrice: pMrp,
                                    unit: pUnit,
                                    imageUrl: pImg,
                                    stock: pStock,
                                    merchantId: pMerch,
                                    category: pCat,
                                    description: pDesc,
                                    isCombo: isCombo,
                                    comboItems: comboItems,
                                    comboImages: comboImages,
                                    comboProductsList: comboList,
                                    quantityInCart: qty,
                                    onAdd: () => context.read<CartProvider>().addItem(
                                          id: pId,
                                          name: pName,
                                          price: pPrice,
                                          unit: pUnit,
                                          imageUrl: pImg,
                                        ),
                                    onRemove: () => context.read<CartProvider>().removeSingleItem(pId),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Floating View Cart Pill if items in cart
          Positioned(
            bottom: 16,
            left: 20,
            right: 20,
            child: Consumer<CartProvider>(
              builder: (context, cart, _) {
                if (cart.totalQuantity == 0) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CheckoutScreen(selectedAddress: widget.deliveryAddress)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00875A),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${cart.totalQuantity} items • ₹${cart.totalAmount.toInt()}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5),
                        ),
                        const Row(
                          children: [
                            Text('View Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5)),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                          ],
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
    );
  }

  Widget _buildChildChip(String label) {
    final bool isSel = _selectedChildFilter.toLowerCase() == label.toLowerCase();
    return GestureDetector(
      onTap: () => setState(() => _selectedChildFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF00875A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSel ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );
  }
}
