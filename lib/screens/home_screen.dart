import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../widgets/bottom_order_bar.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Grocery / Supermarket',
    'Electronics Store',
    'Vegetables & Fruits',
    'Medicines & Pharmacy',
  ];

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP HEADER WITH FLASH2MART BRANDING
            _buildAttractiveHeader(),

            // 2. CATEGORIES FILTER
            _buildCategoriesList(),

            // 3. LIVE PRODUCTS GRID
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildProductsGrid(),
              ),
            ),
          ],
        ),
      ),
      // 4. BOTTOM ORDER BAR
      bottomNavigationBar: cartProvider.totalQuantity > 0
          ? BottomOrderBar(
              totalQuantity: cartProvider.totalQuantity,
              totalAmount: cartProvider.totalAmount,
              selectedAddress: "Nellore (Current Location)",
              onViewCartPressed: () {
                // TODO: Cart Screen కి నెవిగేట్ చేయండి
              },
            )
          : null,
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
          // Top Row: Brand & Location
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
                  const SizedBox(height: 2),
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white70, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Vedayapalem, Nellore Urban',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
                    ],
                  ),
                ],
              ),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.person_outline, color: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 14),

          // Search Bar
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
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
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

  Widget _buildProductsGrid() {
    final cartProvider = Provider.of<CartProvider>(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00875A)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('ఉత్పత్తులు అందుబాటులో లేవు.'));
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
          return const Center(child: Text('ఫలితాలు ఏవీ దొరకలేదు.'));
        }

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final productId = doc.id;
            final productName = data['name'] ?? data['title'] ?? 'Product';
            final productPrice = ((data['price'] ?? 0) as num).toDouble();
            final productUnit = data['unit'] ?? data['weight'] ?? '1 unit';
            final imageUrl = data['imageBase64'] ?? data['imageUrl'] ?? data['image'] ?? '';

            final currentQty = cartProvider.items[productId]?.quantity ?? 0;

            return ProductCard(
              id: productId,
              name: productName,
              price: productPrice,
              unit: productUnit,
              imageUrl: imageUrl,
              quantityInCart: currentQty,
              onAdd: () {
                cartProvider.addItem(
                  id: productId,
                  name: productName,
                  price: productPrice,
                  unit: productUnit,
                  imageUrl: imageUrl,
                );
              },
              onRemove: () {
                cartProvider.removeSingleItem(productId);
              },
            );
          },
        );
      },
    );
  }
}