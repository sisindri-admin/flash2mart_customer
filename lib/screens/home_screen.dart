import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location_model.dart';
import '../providers/cart_provider.dart';
import '../services/location_service.dart';
import '../services/smart_recommendation_engine.dart';
import '../widgets/address_selection_bottom_sheet.dart';
import '../widgets/home/active_order_floating_banner.dart';
import '../widgets/home/home_product_sections.dart';
import '../widgets/home/jiomart_festival_header_and_banner.dart';
import '../widgets/home/jiomart_filters_bottom_sheet.dart';
import '../widgets/home/jiomart_floating_cart_and_navbar.dart';
import '../widgets/home/jiomart_popular_product_card.dart';
import 'categories_directory_screen.dart';
import 'checkout_screen.dart';
import 'my_orders_screen.dart';
import 'offers_zone_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // 0: Home, 1: Categories, 2: Buy Again (Orders), 3: Offers
  bool _isQuickMode = true;

  final ScrollController _homeScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  JioMartFilterSelection _activeFilters = const JioMartFilterSelection();
  int _endlessBatchCount = 2;

  String _currentAddress = LocationService.defaultNelloreAddress;
  final List<UserAddress> _savedAddresses = [
    UserAddress(
      id: 'default_podalakur',
      title: 'Home',
      houseNo: '5/523',
      area: 'Podalakur Rd, Telugu Ganga Colony, Nellore - 524004',
      landmark: 'Podalakur Road',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialAddress();
    _homeScrollController.addListener(_onHomeScroll);
  }

  Future<void> _loadInitialAddress() async {
    final detected = await LocationService.getCurrentAddress();
    if (mounted && detected.isNotEmpty) {
      setState(() {
        _currentAddress = detected;
      });
    }
  }

  void _onHomeScroll() {
    if (!_homeScrollController.hasClients) return;
    final maxScroll = _homeScrollController.position.maxScrollExtent;
    final currentScroll = _homeScrollController.position.pixels;
    if (maxScroll - currentScroll <= 480) {
      setState(() {
        _endlessBatchCount += 2;
      });
    }
  }

  @override
  void dispose() {
    _homeScrollController.removeListener(_onHomeScroll);
    _homeScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openLocationSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddressSelectionBottomSheet(
          initialGpsAddress: _currentAddress,
          savedAddresses: _savedAddresses,
          onAddressSelected: (String title, String fullAddress) {
            setState(() {
              _currentAddress = fullAddress;
            });
          },
          onAddressSaved: (UserAddress newAddress) {
            setState(() {
              _savedAddresses.removeWhere(
                (a) => a.title == newAddress.title && newAddress.title != 'Other',
              );
              _savedAddresses.add(newAddress);
              _currentAddress = newAddress.fullAddress;
            });
          },
        );
      },
    );
  }

  void _openProfileScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          currentAddress: _currentAddress,
          onAddressTap: _openLocationSelectionSheet,
        ),
      ),
    );
  }

  Widget _buildPopularProductCard(QueryDocumentSnapshot doc, {String prefix = 'pop'}) {
    final data = doc.data() as Map<String, dynamic>;
    final String productId = doc.id;
    final String productName =
        (data['name'] ?? data['title'] ?? 'Product').toString();
    final double productPrice = ((data['price'] ?? 0) as num).toDouble();
    final double marketPrice =
        ((data['marketPrice'] ?? productPrice) as num).toDouble();
    final String productUnit =
        (data['unit'] ?? data['weight'] ?? '1 unit').toString();
    final String imageUrl =
        (data['imageBase64'] ?? data['imageUrl'] ?? data['image'] ?? '')
            .toString();
    final int productStock = ((data['stock'] ?? 1) as num).toInt();

    return Selector<CartProvider, int>(
      selector: (context, cart) => cart.items[productId]?.quantity ?? 0,
      builder: (context, currentQty, child) {
        return JioMartPopularProductCard(
          key: ValueKey('${prefix}_$productId'),
          id: productId,
          name: productName,
          price: productPrice,
          marketPrice: marketPrice,
          unit: productUnit,
          imageUrl: imageUrl,
          stock: productStock,
          merchantId: (data['merchantId'] ?? '').toString(),
          category: (data['category'] ?? 'Groceries').toString(),
          description: (data['description'] ?? '').toString(),
          quantityInCart: currentQty,
          onAdd: () {
            context.read<CartProvider>().addItem(
                  id: productId,
                  name: productName,
                  price: productPrice,
                  unit: productUnit,
                  imageUrl: imageUrl,
                );
          },
          onRemove: () {
            context.read<CartProvider>().removeSingleItem(productId);
          },
        );
      },
    );
  }

  Widget _buildHomeBody() {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          final bool isLoading =
              snapshot.connectionState == ConnectionState.waiting;
          final List<QueryDocumentSnapshot> allDocs =
              snapshot.data?.docs ?? [];

          // Filter products by search, top category tab, and Split-Pane Filters
          final List<QueryDocumentSnapshot> filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final String name =
                (data['name'] ?? data['title'] ?? '').toString().toLowerCase();
            final String category =
                (data['category'] ?? '').toString().toLowerCase();
            final double price = ((data['price'] ?? 0) as num).toDouble();
            final double mrp = ((data['marketPrice'] ?? price) as num).toDouble();
            final int disc =
                mrp > price && mrp > 0 ? (((mrp - price) / mrp) * 100).round() : 0;

            if (_searchQuery.isNotEmpty &&
                !name.contains(_searchQuery) &&
                !category.contains(_searchQuery)) {
              return false;
            }

            if (_selectedCategory != 'All') {
              if (_selectedCategory == 'Milk & Dairy') {
                final bool dairyMatch = name.contains('milk') ||
                    name.contains('curd') ||
                    name.contains('paneer') ||
                    name.contains('butter') ||
                    name.contains('ghee') ||
                    category.contains('dairy');
                if (!dairyMatch) return false;
              } else if (!category.contains(_selectedCategory.toLowerCase())) {
                return false;
              }
            }

            if (_activeFilters.selectedBrands.isNotEmpty) {
              final bool brandMatch = _activeFilters.selectedBrands
                  .any((b) => name.contains(b.toLowerCase()));
              if (!brandMatch) return false;
            }
            if (_activeFilters.selectedCategories.isNotEmpty) {
              final bool catMatch = _activeFilters.selectedCategories.any(
                (c) => category.contains(c.toLowerCase()),
              );
              if (!catMatch) return false;
            }
            if (_activeFilters.selectedDiscount.isNotEmpty) {
              final int minD =
                  int.tryParse(_activeFilters.selectedDiscount) ?? 0;
              if (disc < minD) return false;
            }
            if (_activeFilters.selectedPriceRange == 'Under ₹50' && price >= 50) {
              return false;
            }
            if (_activeFilters.selectedPriceRange == '₹50 - ₹199' &&
                (price < 50 || price > 199)) {
              return false;
            }
            if (_activeFilters.selectedPriceRange == '₹200 & Above' &&
                price < 200) {
              return false;
            }

            return true;
          }).toList();

          return CustomScrollView(
            controller: _homeScrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. TOP JIOMART HEADER + QUICK/SHOPALL + ADMIN FESTIVAL HERO & 3 CARDS
              SliverToBoxAdapter(
                child: JioMartTopHeaderAndFestivalSection(
                  isQuickMode: _isQuickMode,
                  onModeChanged: (val) => setState(() => _isQuickMode = val),
                  currentAddress: _currentAddress,
                  onAddressTap: _openLocationSelectionSheet,
                  onProfileTap: _openProfileScreen,
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  onSearchChanged: (v) =>
                      setState(() => _searchQuery = v.trim().toLowerCase()),
                  onClearSearch: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (cat) =>
                      setState(() => _selectedCategory = cat),
                  allProducts: allDocs,
                ),
              ),

              // 2. "Popular Near You" HEADER + FILTER / BRANDS PILLS (Screenshots 4 & 6)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory == 'All'
                            ? 'Popular Near You'
                            : _selectedCategory,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () async {
                              final res = await JioMartFiltersBottomSheet.show(
                                context,
                                allProducts: allDocs,
                                currentSelection: _activeFilters,
                              );
                              if (res != null) {
                                setState(() => _activeFilters = res);
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _activeFilters.hasAnyFilter
                                    ? const Color(0xFFEFF6FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _activeFilters.hasAnyFilter
                                      ? const Color(0xFF0078AD)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 14,
                                    color: Color(0xFF0078AD),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Filter',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0078AD),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () async {
                              final res = await JioMartFiltersBottomSheet.show(
                                context,
                                allProducts: allDocs,
                                currentSelection: _activeFilters,
                              );
                              if (res != null) {
                                setState(() => _activeFilters = res);
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Text(
                                    'Brands',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 15,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. 3-COLUMN "Popular Near You" PRODUCT GRID (Screenshot 4)
              if (isLoading)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverToBoxAdapter(
                    child: HomeProductSkeletonGrid(),
                  ),
                )
              else if (filteredDocs.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No matching products found',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedCategory = 'All';
                              _activeFilters = const JioMartFilterSelection();
                            });
                          },
                          child: const Text('Reset All Filters'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildPopularProductCard(
                          filteredDocs[index],
                          prefix: 'pop_main',
                        );
                      },
                      childCount: filteredDocs.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.48,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 14,
                    ),
                  ),
                ),

                // 4. CATEGORY-WISE CAROUSELS & RECOMMENDATIONS
                if (_searchQuery.isEmpty)
                  SliverToBoxAdapter(
                    child: HomeProductSections(
                      allDocs: allDocs,
                      onCartUpdated: () {},
                    ),
                  ),

                // 5. ENDLESS / INFINITE SCROLL 3-COLUMN CATEGORY BATCHES
                SliverToBoxAdapter(
                  child: Column(
                    children: List.generate(_endlessBatchCount, (batchIdx) {
                      final group =
                          SmartRecommendationEngine.generateEndlessSection(
                        batchIndex: batchIdx,
                        allDocs: filteredDocs,
                      );
                      if (group.products.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: group.bgTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    group.icon,
                                    color: group.accentColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: group.accentColor,
                                          ),
                                        ),
                                        Text(
                                          group.subtitle,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: group.products.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.48,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 14,
                              ),
                              itemBuilder: (context, idx) {
                                return _buildPopularProductCard(
                                  group.products[idx],
                                  prefix: 'endless_${batchIdx}_$idx',
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],

              // Bottom Clearance for Floating Blue Cart Pill + Pill Nav Bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 210),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeBody(),
      CategoriesDirectoryScreen(
        currentAddress: _currentAddress,
        onAddressTap: _openLocationSelectionSheet,
        onProfileTap: _openProfileScreen,
      ),
      const MyOrdersScreen(), // "Buy Again" & Live Orders tab
      OffersZoneScreen(currentAddress: _currentAddress), // "Offers" tab
    ];

    final int safeIndex =
        (_currentIndex < pages.length && _currentIndex >= 0) ? _currentIndex : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(
            index: safeIndex,
            children: pages,
          ),

          // Active Order Banner + Floating Blue View Cart Pill + Free Delivery Scooter Strip + 4-Tab Pill Navbar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (safeIndex == 0) const ActiveOrderFloatingBanner(),
                JioMartFloatingCartAndBottomArea(
                  currentTabIndex: safeIndex,
                  onTabSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
                  onViewCartPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CheckoutScreen(selectedAddress: _currentAddress),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}