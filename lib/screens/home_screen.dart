import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Column(
        children: [
          // 1. TOP HEADER & SEARCH BAR
          _buildHeader(user),

          // 2. CATEGORIES FILTER
          _buildCategoriesList(),

          // 3. LIVE PRODUCTS GRID FROM MERCHANTS DATABASE
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildProductsGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF00875A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚡ 15 MINS DELIVERY', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 2),
                  Text('Netaji Nagar, Nellore', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search milk, rice, brinjal...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(cat, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
              selected: isSelected,
              selectedColor: const Color(0xFF00875A),
              onSelected: (val) => setState(() => _selectedCategory = cat),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsGrid() {
    return StreamBuilder<QuerySnapshot>(
      // Same Merchant Database 'products' Collection
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('ప్రస్తుతం ఉత్పత్తులు అందుబాటులో లేవు.'));
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

        return GridView.builder(
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String name = data['name'] ?? data['title'] ?? 'Product';
            final double price = (data['price'] ?? 0).toDouble();
            final String imageBase64 = data['imageBase64'] ?? '';
            final String merchantId = data['merchantId'] ?? '';

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: imageBase64.isNotEmpty
                          ? Image.memory(base64Decode(imageBase64), fit: BoxFit.cover)
                          : const Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (merchantId.isNotEmpty) _MerchantName(merchantId: merchantId),
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00875A),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: () {},
                              child: const Text('ADD', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MerchantName extends StatelessWidget {
  final String merchantId;
  const _MerchantName({required this.merchantId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('merchants').doc(merchantId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final storeName = data?['storeName'] ?? '';
          if (storeName.isNotEmpty) {
            return Text(
              storeName,
              style: const TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold),
              maxLines: 1,
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}