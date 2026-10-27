import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../services/smart_recommendation_engine.dart';
import '../widgets/bottom_order_bar.dart';
import '../widgets/custom_bottom_navbar.dart';
import '../widgets/home/active_order_floating_banner.dart';
import '../widgets/home/festival_offer_banner.dart';
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

  // Search Tab Controller
  final TextEditingController _dedicatedSearchController =
      TextEditingController();
  String _dedicatedSearchQuery = '';

  // Today Offers Tab Category Filter
  String _selectedOfferCategory = 'All';

  // Cached single Firestore stream + cached docs so products NEVER blink on rebuild!
  late final Stream<QuerySnapshot> _productsStream;
  List<QueryDocumentSnapshot> _cachedProductDocs = const [];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _activeQuickFilter = 'all';
  int _endlessBatchCount = 2;

  String _currentAddress = 'Fetch Live Location...';
  double? _currentLat;
  double? _currentLng;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _productsStream =
        FirebaseFirestore.instance.collection('products').snapshots();
    _fetchLiveLocation();
    _homeScrollController.addListener(_onHomeScroll);
  }

  void _onHomeScroll() {
    if (!_homeScrollController.hasClients) return;
    final maxScroll = _homeScrollController.position.maxScrollExtent;
    final currentScroll = _homeScrollController.position.pixels;
    if (maxScroll - currentScroll <= 420 && _endlessBatchCount < 14) {
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
    _dedicatedSearchController.dispose();
    _addressEditController.dispose();
    super.dispose();
  }

  List<String> _extractOfferImageUrls() {
    final List<String> list = [];
    for (final doc in _cachedProductDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final String img =
          (data['imageUrl'] ?? data['imageBase64'] ?? data['image'] ?? '')
              .toString()
              .trim();
      if (img.isNotEmpty) {
        list.add(img);
        if (list.length >= 8) break;
      }
    }
    return list;
  }

  Future<void> _saveUserLiveCoordinatesToFirestore(
    double lat,
    double lng,
    String address,
  ) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .set({
        'address': address,
        'customerLocation': GeoPoint(lat, lng),
        'latitude': lat,
        'longitude': lng,
        'customerLat': lat,
        'customerLng': lng,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _fetchLiveLocation() async {
    if (mounted) {
      setState(() => _isLoadingLocation = true);
    }
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _currentAddress = 'GPS Off - Select Manually';
            _currentLat ??= 14.4426;
            _currentLng ??= 79.9865;
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
              _currentLat ??= 14.4426;
              _currentLng ??= 79.9865;
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
            _currentLat ??= 14.4426;
            _currentLng ??= 79.9865;
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

      _currentLat = position.latitude;
      _currentLng = position.longitude;

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

        _saveUserLiveCoordinatesToFirestore(
          position.latitude,
          position.longitude,
          _currentAddress,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentAddress = 'Vedayapalem, Main Road, Nellore - 524004';
          _currentLat ??= 14.4426;
          _currentLng ??= 79.9865;
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
                            'Saves exact GPS Lat-Long for Delivery Partner',
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
                  onPressed: () async {
                    final String typed = _addressEditController.text.trim();
                    if (typed.isNotEmpty) {
                      setState(() {
                        _currentAddress = typed;
                      });
                      try {
                        final List<Location> locs =
                            await locationFromAddress(typed);
                        if (locs.isNotEmpty && mounted) {
                          setState(() {
                            _currentLat = locs.first.latitude;
                            _currentLng = locs.first.longitude;
                          });
                          _saveUserLiveCoordinatesToFirestore(
                            locs.first.latitude,
                            locs.first.longitude,
                            typed,
                          );
                        }
                      } catch (_) {}
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
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

  /// Tab 0: Home Screen
  Widget _buildHomeBody() {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<QuerySnapshot>(
        stream: _productsStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            _cachedProductDocs = snapshot.data!.docs;
          }
          final List<QueryDocumentSnapshot> allDocs = _cachedProductDocs;
          final bool isInitialLoading =
              allDocs.isEmpty && snapshot.connectionState == ConnectionState.waiting;

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
            if (_activeQuickFilter == 'offers' && !(marketPrice > price)) {
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
              final double aPrice = ((aData['price'] ?? 0) as num).toDouble();
              final double bPrice = ((bData['price'] ?? 0) as num).toDouble();
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
              // 1. SCROLLABLE TOP HEADER (Flash2Mart App Icon + Title + Location + Help + Search)
              SliverToBoxAdapter(
                child: _buildScrollableTopHeader(),
              ),

              // 2. BANNERS, CATEGORIES & FILTERS
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    FestivalOfferBanner(
                      onShopFestivalTap: () {
                        setState(() {
                          _currentIndex = 4; // Switch to Today Offer
                        });
                      },
                    ),
                    const OfferSliderBanner(),
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
                    const SizedBox(height: 8),
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
                          Text(
                            '${filteredDocs.length} items',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. PRODUCT GRID
              if (isInitialLoading)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverToBoxAdapter(
                    child: HomeProductSkeletonGrid(),
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
                          size: 46,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No matching products found',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedCategory = 'All';
                              _activeQuickFilter = 'all';
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Reset All Filters'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Main 3-Column Clean Grid
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
                      childAspectRatio: 0.46,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 14,
                    ),
                  ),
                ),

                // Endless / Infinite Category Sections
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
                        padding: const EdgeInsets.fromLTRB(12, 18, 12, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              group.subtitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
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
                                childAspectRatio: 0.46,
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
                child: SizedBox(height: 195),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Tab 1: Categories Tab
  Widget _buildCategoriesBody() {
    return SafeArea(
      bottom: false,
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
              stream: _productsStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  _cachedProductDocs = snapshot.data!.docs;
                }
                final List<QueryDocumentSnapshot> allDocs = _cachedProductDocs;
                if (allDocs.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00875A)),
                  );
                }
                final List<CategorySectionGroup> groups =
                    SmartRecommendationEngine.buildCategorySections(allDocs);
                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 195),
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
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              group.subtitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
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
                                childAspectRatio: 0.46,
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

  /// Tab 2: Dedicated Search Tab (Requirement 3: Search with animated product names and icons scrolling UPWARD)
  Widget _buildSearchBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            color: const Color(0xFF00875A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.search_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Search Fresh Groceries & Essentials',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Requirement 3: Dedicated animated search bar where "search for milk" scrolls UPWARD with changing icons
                _DedicatedSearchBarWithRotatingHints(
                  controller: _dedicatedSearchController,
                  searchQuery: _dedicatedSearchQuery,
                  onQueryChanged: (val) {
                    setState(() {
                      _dedicatedSearchQuery = val;
                    });
                  },
                ),
              ],
            ),
          ),

          // Trending Search Suggestion Chips
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Trending: ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  ...[
                    'Milk & Curd',
                    'Tomato',
                    'Onion',
                    'Sona Masoori',
                    'Sunflower Oil',
                    'Atta',
                    'Biscuits',
                  ].map((chip) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        label: Text(chip),
                        labelStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        onPressed: () {
                          _dedicatedSearchController.text = chip;
                          setState(() {
                            _dedicatedSearchQuery = chip.toLowerCase();
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Search Results in 3-column clean grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _productsStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  _cachedProductDocs = snapshot.data!.docs;
                }
                final List<QueryDocumentSnapshot> allDocs = _cachedProductDocs;

                final List<QueryDocumentSnapshot> matchedDocs =
                    allDocs.where((doc) {
                  if (_dedicatedSearchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final String name = (data['name'] ?? data['title'] ?? '')
                      .toString()
                      .toLowerCase();
                  final String category =
                      (data['category'] ?? '').toString().toLowerCase();
                  return name.contains(_dedicatedSearchQuery) ||
                      category.contains(_dedicatedSearchQuery);
                }).toList();

                if (matchedDocs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 46,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No items matching "$_dedicatedSearchQuery"',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try searching for milk, rice, oil or fresh vegetables',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 195),
                  itemCount: matchedDocs.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.46,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, idx) {
                    return _buildProductCardFromDoc(
                      matchedDocs[idx],
                      keyPrefix: 'search_$idx',
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

  /// Tab 4: Today Offer Tab
  Widget _buildTodayOffersBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE11D48),
                  Color(0xFFBE123C),
                  Color(0xFF9F1239),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.celebration_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Today Offers & Combos',
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
                    backgroundColor: const Color(0x33FFFFFF),
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

          // Category Shortcut Pills for Today Offers
          Container(
            color: const Color(0xFFFFF1F2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...[
                    'All',
                    'Milk & Dairy',
                    'Vegetables',
                    'Grocery',
                    'Pharmacy',
                    'Snacks',
                  ].map((cat) {
                    final bool isSel = _selectedOfferCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedOfferCategory = cat;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFE11D48) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFFE11D48)
                                  : const Color(0xFFFECDD3),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isSel ? FontWeight.w900 : FontWeight.w600,
                              color:
                                  isSel ? Colors.white : const Color(0xFF9F1239),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _productsStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  _cachedProductDocs = snapshot.data!.docs;
                }
                final List<QueryDocumentSnapshot> allDocs = _cachedProductDocs;

                final List<QueryDocumentSnapshot> offerDocs =
                    allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String name = (data['name'] ?? data['title'] ?? '')
                      .toString()
                      .toLowerCase();
                  final String category =
                      (data['category'] ?? '').toString().toLowerCase();

                  if (_selectedOfferCategory != 'All') {
                    final sel = _selectedOfferCategory.toLowerCase();
                    if (!category.contains(sel) && !name.contains(sel)) {
                      return false;
                    }
                  }
                  return true;
                }).toList();

                final List<QueryDocumentSnapshot> displayDocs =
                    offerDocs.isNotEmpty ? offerDocs : allDocs;

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 195),
                  children: [
                    const FestivalOfferBanner(),
                    const SizedBox(height: 6),
                    const OfferSliderBanner(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedOfferCategory == 'All'
                                ? 'Today\'s Special Deals & Combos'
                                : '$_selectedOfferCategory Special Deals',
                            style: const TextStyle(
                              fontSize: 15.5,
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
                              color: const Color(0xFFFFE4E6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${displayDocs.length} Deals',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFBE123C),
                              ),
                            ),
                          ),
                        ],
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
                          childAspectRatio: 0.46,
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
      _buildSearchBody(),
      const MyOrdersScreen(),
      _buildTodayOffersBody(),
    ];

    final int safeIndex =
        (_currentIndex < pages.length && _currentIndex >= 0) ? _currentIndex : 0;

    final List<String> offerImages = _extractOfferImageUrls();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: safeIndex,
              children: pages,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
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
                            builder: (_) => CheckoutScreen(
                              selectedAddress: _currentAddress,
                              customerLat: _currentLat,
                              customerLng: _currentLng,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                CustomBottomNavBar(
                  currentIndex: safeIndex,
                  offerImages: offerImages,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Scrollable Header containing the Flash2Mart App Icon, Title, Location, Help & Search
  Widget _buildScrollableTopHeader() {
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
                        // Flash2Mart App Icon
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.flash_on_rounded,
                              color: Color(0xFF00875A),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Flash2Mart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt, size: 12, color: Colors.black),
                              Text(
                                '15 MINS',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
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
                                  ? 'Detecting live GPS location...'
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

              // Small Help Icon next to Profile Icon
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpScreen(),
                    ),
                  );
                },
                child: Tooltip(
                  message: 'Help & Support',
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Profile Icon
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
                  radius: 18,
                  backgroundColor: Color(0x33FFFFFF),
                  child: Icon(Icons.person_outline, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Bar on Home Screen
          _SearchBarWithRotatingHints(
            controller: _searchController,
            searchQuery: _searchQuery,
            onQueryChanged: (val) {
              setState(() => _searchQuery = val);
            },
          ),
        ],
      ),
    );
  }
}

/// Dedicated Search Bar for Tab 2 where 'Search for "Milk"' etc. scrolls UPWARD with changing icons!
class _DedicatedSearchBarWithRotatingHints extends StatefulWidget {
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onQueryChanged;

  const _DedicatedSearchBarWithRotatingHints({
    required this.controller,
    required this.searchQuery,
    required this.onQueryChanged,
  });

  @override
  State<_DedicatedSearchBarWithRotatingHints> createState() =>
      _DedicatedSearchBarWithRotatingHintsState();
}

class _DedicatedSearchBarWithRotatingHintsState
    extends State<_DedicatedSearchBarWithRotatingHints> {
  final FocusNode _focusNode = FocusNode();
  Timer? _hintTimer;
  int _hintIndex = 0;
  bool _isFocused = false;

  static const List<Map<String, dynamic>> _searchHints = [
    {'icon': Icons.egg_alt_rounded, 'text': 'Search for "Milk, Curd & Dairy"'},
    {'icon': Icons.eco_rounded, 'text': 'Search for "Fresh Tomatoes & Veggies"'},
    {'icon': Icons.soup_kitchen_rounded, 'text': 'Search for "Sona Masoori Rice & Atta"'},
    {'icon': Icons.water_drop_rounded, 'text': 'Search for "Sunflower Oil & Ghee"'},
    {'icon': Icons.cookie_rounded, 'text': 'Search for "Biscuits, Tea & Snacks"'},
    {'icon': Icons.local_fire_department_rounded, 'text': 'Search for "Masala, Spices & Dal"'},
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });
    _hintTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (mounted && widget.searchQuery.isEmpty && !_isFocused) {
        setState(() {
          _hintIndex = (_hintIndex + 1) % _searchHints.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showAnimatedHint = widget.searchQuery.isEmpty && !_isFocused;
    final currentHint = _searchHints[_hintIndex];
    final IconData hintIcon = currentHint['icon'] as IconData;
    final String hintText = currentHint['text'] as String;

    return Container(
      height: 44,
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
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (showAnimatedHint)
            Positioned(
              left: 42,
              right: 16,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
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
                    child: Row(
                      key: ValueKey<int>(_hintIndex),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hintIcon,
                          size: 15,
                          color: const Color(0xFF00875A),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            hintText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: (v) => widget.onQueryChanged(v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: showAnimatedHint ? '' : 'Type product name...',
              hintStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF00875A),
                size: 20,
              ),
              suffixIcon: widget.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onQueryChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone StatefulWidget for the rotating search bar hints on Home Screen
class _SearchBarWithRotatingHints extends StatefulWidget {
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onQueryChanged;

  const _SearchBarWithRotatingHints({
    required this.controller,
    required this.searchQuery,
    required this.onQueryChanged,
  });

  @override
  State<_SearchBarWithRotatingHints> createState() =>
      _SearchBarWithRotatingHintsState();
}

class _SearchBarWithRotatingHintsState
    extends State<_SearchBarWithRotatingHints> {
  final FocusNode _focusNode = FocusNode();
  Timer? _hintTimer;
  int _hintIndex = 0;
  bool _isFocused = false;

  static const List<String> _hints = [
    'Search "Fresh Milk, Curd & Pure Ghee" 🥛',
    'Search "Sona Masoori Rice & Toor Dal" 🌾',
    'Search "Farm Fresh Tomatoes & Onions" 🍅',
    'Search "Sunflower Oil, Atta & Masala" 🌻',
    'Search "Festival Sweets & Dry Fruits" 🪔',
    'Search "Cold Drinks, Biscuits & Snacks" 🍪',
    '"Order Now — 15 Mins Doorstep Delivery!" ⚡',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });
    _hintTimer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (mounted && widget.searchQuery.isEmpty && !_isFocused) {
        setState(() {
          _hintIndex = (_hintIndex + 1) % _hints.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showAnimatedHint = widget.searchQuery.isEmpty && !_isFocused;

    return Container(
      height: 44,
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
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (showAnimatedHint)
            Positioned(
              left: 46,
              right: 16,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      final inTween = Tween<Offset>(
                        begin: const Offset(0.0, 0.95),
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
                    child: SizedBox(
                      key: ValueKey<int>(_hintIndex),
                      width: double.infinity,
                      child: Text(
                        _hints[_hintIndex],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: (v) => widget.onQueryChanged(v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: showAnimatedHint
                  ? ''
                  : 'Search milk, vegetables, rice, snacks...',
              hintStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF00875A),
              ),
              suffixIcon: widget.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onQueryChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ],
      ),
    );
  }
}