import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../widgets/bottom_order_bar.dart';
import '../widgets/custom_bottom_navbar.dart';
import '../widgets/product_card.dart';
import '../widgets/offer_slider_banner.dart';
import 'checkout_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';
import 'help_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final ValueNotifier<bool> _showCartPopupNotifier = ValueNotifier<bool>(false);
  Timer? _cartTimer;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressEditController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';

  String _currentAddress = "Fetch Live Location...";
  bool _isLoadingLocation = false;

  final List<String> _categories = [
    'All',
    'Grocery / Supermarket',
    'Electronics Store',
    'Vegetables & Fruits',
    'Medicines & Pharmacy',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveLocation();
  }

  @override
  void dispose() {
    _cartTimer?.cancel();
    _showCartPopupNotifier.dispose();
    _searchController.dispose();
    _addressEditController.dispose();
    super.dispose();
  }

  void _triggerCartPopup() {
    _cartTimer?.cancel();
    _showCartPopupNotifier.value = true;

    _cartTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _showCartPopupNotifier.value = false;
      }
    });
  }

  Future<void> _fetchLiveLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _currentAddress = "GPS Off - Select Manually";
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
              _currentAddress = "Permission Denied";
              _isLoadingLocation = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _currentAddress = "Enable Location in Settings";
            _isLoadingLocation = false;
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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

        final fullAddress = addressParts.join(', ');

        setState(() {
          _currentAddress = fullAddress.isNotEmpty ? fullAddress : "Location Detected";
          _addressEditController.text = _currentAddress;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = "Vedayapalem, Main Road, Nellore - 524004";
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
                    'Delivery Location',
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
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00875A).withOpacity(0.08),
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
                            'Fetch Current GPS Location',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00875A),
                            ),
                          ),
                          Text(
                            'Using satellite precise location',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Edit / Customize Address:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressEditController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter Door No, Street Name, Area...',
                  prefixIcon: const Icon(Icons.edit_location_alt_outlined, color: Color(0xFF00875A)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00875A), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.home, size: 16, color: Colors.blue),
                    label: const Text('Home'),
                    onPressed: () {
                      _addressEditController.text = "D.No: 12-3-45, Home Street, Vedayapalem, Nellore";
                    },
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.work, size: 16, color: Colors.orange),
                    label: const Text('Work'),
                    onPressed: () {
                      _addressEditController.text = "Plot 402, Tech Hub, Magunta Layout, Nellore";
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
                    'UPDATE LOCATION',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const OfferSliderBanner(),
                      _buildCategoriesList(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: _buildProductsSliverGrid(),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpBody() {
    return const HelpScreen();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeBody(),
      const MyOrdersScreen(),
      CheckoutScreen(selectedAddress: _currentAddress),
      _buildHelpBody(),
    ];

    final int safeIndex = (_currentIndex < pages.length && _currentIndex >= 0) ? _currentIndex : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _showCartPopupNotifier,
            builder: (context, showPopup, child) {
              return Selector<CartProvider, int>(
                selector: (context, cart) => cart.totalQuantity,
                builder: (context, totalQuantity, child) {
                  if (totalQuantity <= 0 || !showPopup) return const SizedBox.shrink();

                  final cartProvider = Provider.of<CartProvider>(context, listen: false);
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: showPopup ? 1.0 : 0.0,
                    child: BottomOrderBar(
                      totalQuantity: totalQuantity,
                      totalAmount: cartProvider.totalAmount,
                      selectedAddress: _currentAddress,
                      onViewCartPressed: () {
                        setState(() {
                          _currentIndex = 2;
                        });
                        _showCartPopupNotifier.value = false;
                      },
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
        color: Color(0xFF00875A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
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
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                  fontWeight: FontWeight.bold,
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
                          const Icon(Icons.location_on, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _isLoadingLocation ? "Detecting location..." : _currentAddress,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
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
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.person_outline, color: Colors.white),
                ),
              )
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search milk, rice, vegetables...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Color(0xFF00875A)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        key: const PageStorageKey('categories_list'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF00875A),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? const Color(0xFF00875A) : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (val) => setState(() => _selectedCategory = cat),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsSliverGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: Color(0xFF00875A)),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: Text('ఉత్పత్తులు అందుబాటులో లేవు.')),
          );
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? data['title'] ?? '').toString().toLowerCase();

          if (_searchQuery.isNotEmpty && !name.contains(_searchQuery)) return false;

          if (_selectedCategory != 'All') {
            final cat = (data['category'] ?? '').toString().toLowerCase();
            if (!cat.contains(_selectedCategory.toLowerCase())) return false;
          }
          return true;
        }).toList();

        if (docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: Text('ఫలితాలు ఏవీ దొరకలేదు.')),
          );
        }

        return SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final productId = doc.id;
              final productName = data['name'] ?? data['title'] ?? 'Product';
              final productPrice = ((data['price'] ?? 0) as num).toDouble();
              final double marketPrice = ((data['marketPrice'] ?? productPrice) as num).toDouble();
              final productUnit = data['unit'] ?? data['weight'] ?? '1 unit';
              final imageUrl = data['imageBase64'] ?? data['imageUrl'] ?? data['image'] ?? '';
              final int productStock = ((data['stock'] ?? 1) as num).toInt();

              // Merchant/Category details passed directly from Firestore product doc
              final String merchantId = data['merchantId'] ?? '';
              final String category = data['category'] ?? 'Grocery / Supermarket';
              final String description = data['description'] ?? '';

              return Selector<CartProvider, int>(
                selector: (context, cart) => cart.items[productId]?.quantity ?? 0,
                builder: (context, currentQty, child) {
                  return ProductCard(
                    key: ValueKey('product_$productId'),
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
                      _triggerCartPopup();
                    },
                    onRemove: () {
                      context.read<CartProvider>().removeSingleItem(productId);
                      _triggerCartPopup();
                    },
                  );
                },
              );
            },
            childCount: docs.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.63,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
        );
      },
    );
  }
}