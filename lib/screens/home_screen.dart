import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../services/smart_recommendation_engine.dart';
import '../widgets/bottom_order_bar.dart';
import '../widgets/custom_bottom_navbar.dart';
import '../widgets/home/active_order_floating_banner.dart';
import '../widgets/home/home_product_sections.dart';
import '../widgets/home/home_trust_and_promo_widgets.dart';
import '../widgets/offer_slider_banner.dart';
import '../widgets/product_card.dart';
import 'checkout_screen.dart';
import 'help_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final ScrollController _homeScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressEditController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _activeQuickFilter = 'all';
  int _endlessBatchCount = 2;

  String _currentAddress = 'Fetch Live Location...';
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveLocation();
    _homeScrollController.addListener(_onHomeScroll);
  }

  void _onHomeScroll() {
    if (!_homeScrollController.hasClients) return;
    final maxScroll = _homeScrollController.position.maxScrollExtent;
    final currentScroll = _homeScrollController.position.pixels;
    if (maxScroll - currentScroll <= 450) {
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
    _addressEditController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _currentAddress = 'GPS Off - Select Manually';
            _isLoadingLocation = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _currentAddress = 'Permission Denied';
              _isLoadingLocation = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _currentAddress = 'Enable Location in Settings';
            _isLoadingLocation = false;
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        List<String> addressParts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null &&
            place.subLocality!.isNotEmpty &&
            place.subLocality != place.street) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }

        final String fullAddress = addressParts.join(', ');

        setState(() {
          _currentAddress =
              fullAddress.isNotEmpty ? fullAddress : 'Location Detected';
          _addressEditController.text = _currentAddress;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentAddress = 'Vedayapalem, Main Road, Nellore - 524004';
          _addressEditController.text = _currentAddress;
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _showLocationBottomSheet() {
    _addressEditController.text = _currentAddress;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Delivery Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _fetchLiveLocation();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x1400875A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.my_location, color: Color(0xFF00875A)),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use Current GPS Location',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00875A),
                            ),
                          ),
                          Text(
                            'Using satellite precise location for 15-min delivery',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Edit / Customize Complete Address:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressEditController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter Door No, Street Name, Area...',
                  prefixIcon: const Icon(
                    Icons.edit_location_alt_outlined,
                    color: Color(0xFF00875A),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF00875A),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ActionChip(
                    avatar:
                        const Icon(Icons.home, size: 16, color: Colors.blue),
                    label: const Text('Home'),
                    onPressed: () {
                      _addressEditController.text =
                          'D.No: 12-3-45, Home Street, Vedayapalem, Nellore';
                    },
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(
                      Icons.work,
                      size: 16,
                      color: Colors.orange,
                    ),
                    label: const Text('Work'),
                    onPressed: () {
                      _addressEditController.text =
                          'Plot 402, Tech Hub, Magunta Layout, Nellore';
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00875A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_addressEditController.text.trim().isNotEmpty) {
                      setState(() {
                        _currentAddress = _addressEditController.text.trim();
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'CONFIRM LOCATION',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCardFromDoc(
    QueryDocumentSnapshot doc, {
    String keyPrefix = 'product',
  }) {
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

    final String merchantId = (data['merchantId'] ?? '').toString();
    final String category =
        (data['category'] ?? 'Grocery / Supermarket').toString();
    final String description = (data['description'] ?? '').toString();

    return Selector<CartProvider, int>(
      selector: (context, cart) => cart.items[productId]?.quantity ?? 0,
      builder: (context, currentQty, child) {
        return ProductCard(
          key: ValueKey('${keyPrefix}_$productId'),
          id: productId,
          name: productName,
          price: productPrice,
          marketPrice: marketPrice,
          unit: productUnit,
          imageUrl: imageUrl,
          stock: productStock,
          merchantId: merchantId,
          category: category,
          description: description,
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
      child: Column(
        children: [
          _buildAttractiveHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                final bool isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                final List<QueryDocumentSnapshot> allDocs =
                    snapshot.data?.docs ?? [];

                final List<QueryDocumentSnapshot> filteredDocs =
                    allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String name = (data['name'] ?? data['title'] ?? '')
                      .toString()
                      .toLowerCase();
                  final String category =
                      (data['category'] ?? '').toString().toLowerCase();
                  final double price = ((data['price'] ?? 0) as num).toDouble();
                  final double marketPrice =
                      ((data['marketPrice'] ?? price) as num).toDouble();
                  final int stock = ((data['stock'] ?? 1) as num).toInt();

                  if (_searchQuery.isNotEmpty && !name.contains(_searchQuery)) {
                    return false;
                  }
                  if (_selectedCategory != 'All' &&
                      !category.contains(_selectedCategory.toLowerCase())) {
                    return false;
                  }
                  if (_activeQuickFilter == 'offers' &&
                      !(marketPrice > price)) {
                    return false;
                  }
                  if (_activeQuickFilter == 'under99' && !(price <= 99)) {
                    return false;
                  }
                  if (_activeQuickFilter == 'instock' && !(stock > 0)) {
                    return false;
                  }
                  return true;
                }).toList();

                if (_activeQuickFilter == 'price_asc') {
                  filteredDocs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final double aPrice =
                        ((aData['price'] ?? 0) as num).toDouble();
                    final double bPrice =
                        ((bData['price'] ?? 0) as num).toDouble();
                    return aPrice.compareTo(bPrice);
                  });
                }

                final bool showCuratedCarousels = _searchQuery.isEmpty &&
                    _selectedCategory == 'All' &&
                    _activeQuickFilter == 'all' &&
                    allDocs.isNotEmpty;

                return CustomScrollView(
                  controller: _homeScrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          const OfferSliderBanner(),
                          const HomeTrustBadgeStrip(),
                          HomeCategoryGridSection(
                            selectedCategory: _selectedCategory,
                            onCategorySelected: (cat) {
                              setState(() => _selectedCategory = cat);
                            },
                          ),
                          if (showCuratedCarousels)
                            HomeProductSections(
                              allDocs: allDocs,
                              onCartUpdated: () {},
                            ),
                          const SizedBox(height: 10),
                          HomeQuickFilterBar(
                            activeFilter: _activeQuickFilter,
                            onFilterSelected: (filterId) {
                              setState(() => _activeQuickFilter = filterId);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedCategory == 'All'
                                      ? 'All Fresh Products'
                                      : _selectedCategory,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${filteredDocs.length} Items',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      const SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverToBoxAdapter(
                          child: HomeProductSkeletonGrid(),
                        ),
                      )
                    else if (snapshot.hasError)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      )
                    else if (filteredDocs.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 36,
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'No matching products found',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Try clearing search or switching categories',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedCategory = 'All';
                                    _activeQuickFilter = 'all';
                                  });
                                },
                                icon:
                                    const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Reset All Filters'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Main Filtered 3-Column Grid (Image 3 style)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildProductCardFromDoc(
                                filteredDocs[index],
                                keyPrefix: 'main',
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

                      // Endless / Infinite Category & Discovery Stream (3-Column Image 3 style)
                      SliverToBoxAdapter(
                        child: Column(
                          children:
                              List.generate(_endlessBatchCount, (batchIdx) {
                            final group =
                                SmartRecommendationEngine.generateEndlessSection(
                              batchIndex: batchIdx,
                              allDocs: filteredDocs,
                            );
                            if (group.products.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 18, 12, 4),
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
                                                  fontSize: 14.5,
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
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: group.products.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 0.48,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 14,
                                    ),
                                    itemBuilder: (context, idx) {
                                      return _buildProductCardFromDoc(
                                        group.products[idx],
                                        keyPrefix: 'endless_${batchIdx}_$idx',
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
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 36),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 1: Categories Tab (Grouped Categories + 3-Column Image 3 Product Cards)
  Widget _buildCategoriesBody() {
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: const Color(0xFF00875A),
            child: const Row(
              children: [
                Icon(Icons.dashboard_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Shop by Categories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                final List<QueryDocumentSnapshot> allDocs =
                    snapshot.data?.docs ?? [];
                if (allDocs.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00875A)),
                  );
                }
                final List<CategorySectionGroup> groups =
                    SmartRecommendationEngine.buildCategorySections(allDocs);
                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    HomeCategoryGridSection(
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (cat) {
                        setState(() {
                          _selectedCategory = cat;
                          _currentIndex = 0;
                        });
                      },
                    ),
                    ...groups.map((group) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
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
                                            fontSize: 14.5,
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
                                return _buildProductCardFromDoc(
                                  group.products[idx],
                                  keyPrefix: 'cat_${group.title}_$idx',
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 3: Offers Tab (Super Saver Deals in 3-Column Image 3 Grid + Support Access)
  Widget _buildOffersBody() {
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF00875A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.local_offer_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Special Offers & Super Savers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0x26FFFFFF),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpScreen()),
                    );
                  },
                  icon: const Icon(Icons.support_agent_rounded, size: 16),
                  label: const Text(
                    'Help',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                final List<QueryDocumentSnapshot> allDocs =
                    snapshot.data?.docs ?? [];
                final List<QueryDocumentSnapshot> offerDocs =
                    allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final double price = ((data['price'] ?? 0) as num).toDouble();
                  final double marketPrice =
                      ((data['marketPrice'] ?? price) as num).toDouble();
                  return marketPrice > price && price > 0;
                }).toList();

                final List<QueryDocumentSnapshot> displayDocs =
                    offerDocs.isNotEmpty ? offerDocs : allDocs;

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    const SizedBox(height: 10),
                    const OfferSliderBanner(),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
                      child: Text(
                        'Top Discounted Deals Today',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayDocs.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.48,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 14,
                        ),
                        itemBuilder: (context, idx) {
                          return _buildProductCardFromDoc(
                            displayDocs[idx],
                            keyPrefix: 'offer_$idx',
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeBody(),
      _buildCategoriesBody(),
      const MyOrdersScreen(),
      _buildOffersBody(),
    ];

    final int safeIndex =
        (_currentIndex < pages.length && _currentIndex >= 0) ? _currentIndex : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (safeIndex == 0) const ActiveOrderFloatingBanner(),
          Selector<CartProvider, int>(
            selector: (context, cart) => cart.totalQuantity,
            builder: (context, totalQuantity, child) {
              if (totalQuantity <= 0) return const SizedBox.shrink();

              final cartProvider =
                  Provider.of<CartProvider>(context, listen: false);
              return BottomOrderBar(
                totalQuantity: totalQuantity,
                totalAmount: cartProvider.totalAmount,
                selectedAddress: _currentAddress,
                onViewCartPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CheckoutScreen(selectedAddress: _currentAddress),
                    ),
                  );
                },
              );
            },
          ),
          CustomBottomNavBar(
            currentIndex: safeIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttractiveHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00875A), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Flash2Mart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt, size: 12, color: Colors.black),
                              Text(
                                '15 MINS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _showLocationBottomSheet,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _isLoadingLocation
                                  ? 'Detecting location...'
                                  : _currentAddress,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        currentAddress: _currentAddress,
                        onAddressTap: _showLocationBottomSheet,
                      ),
                    ),
                  );
                },
                child: const CircleAvatar(
                  backgroundColor: Color(0x33FFFFFF),
                  child: Icon(Icons.person_outline, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search milk, fresh vegetables, rice, snacks...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF00875A),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}