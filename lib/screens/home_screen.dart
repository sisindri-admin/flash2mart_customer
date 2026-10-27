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
    _addressEditController.dispose();
    super.dispose();
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

  /// Requirement 1, 3, 5:
  /// - Uses cached `_productsStream` & `_cachedProductDocs` so products NEVER blink!
  /// - Places `_buildScrollableTopHeader()` INSIDE `CustomScrollView` so when scrolling up,
  ///   the Flash2Mart App Icon & Header smoothly scroll up with the page!
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
              // 1. SCROLLABLE TOP HEADER (Flash2Mart App Icon + Brand + Location + Help + Search)
              // Scrolls up cleanly when the customer scrolls down the page!
              SliverToBoxAdapter(
                child: _buildScrollableTopHeader(),
              ),

              // 2. CLEAN BANNERS, CATEGORIES & FILTERS
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    FestivalOfferBanner(
                      onShopFestivalTap: () {
                        setState(() {
                          _activeQuickFilter = 'offers';
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

              // Extra bottom padding so products can scroll cleanly behind/above the hovering bottom bars
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

  /// Tab 3: Offers Tab
  Widget _buildOffersBody() {
    return SafeArea(
      bottom: false,
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
                      'Festival & Super Saver Offers',
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
              stream: _productsStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  _cachedProductDocs = snapshot.data!.docs;
                }
                final List<QueryDocumentSnapshot> allDocs = _cachedProductDocs;
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
                  padding: const EdgeInsets.only(bottom: 195),
                  children: [
                    const FestivalOfferBanner(),
                    const SizedBox(height: 6),
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
      const MyOrdersScreen(),
      _buildOffersBody(),
    ];

    final int safeIndex =
        (_currentIndex < pages.length && _currentIndex >= 0) ? _currentIndex : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      // Requirement 4: Use Stack so Shop for ₹199 badge, Cart badge, and Bottom Navbar
      // HOVER directly over the screen and the screen content is visible behind them!
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
                        // Flash2Mart App Icon (scrolls up with header!)
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

              // Small Help Icon next to Profile Icon -> Navigates to HelpScreen
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

          // Isolated Rotating Search Bar Widget (so its timer NEVER rebuilds the product grid!)
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

/// Standalone StatefulWidget for the rotating search bar hints so its 2.3-second timer
/// ONLY rebuilds the hint text and NEVER triggers setState on HomeScreen!
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
                      final bool isIncoming =
                          child.key == ValueKey<int>(_hintIndex);
                      final Tween<Offset> slideTween = isIncoming
                          ? Tween<Offset>(
                              begin: const Offset(0.0, 0.95),
                              end: Offset.zero,
                            )
                          : Tween<Offset>(
                              begin: const Offset(0.0, -0.95),
                              end: Offset.zero,
                            );
                      return ClipRect(
                        child: SlideTransition(
                          position: slideTween.animate(
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