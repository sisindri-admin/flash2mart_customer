import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/header_widget.dart';
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // 1. TOP HEADER & LIVE LOCATION & SEARCH
          HomeHeaderWidget(
            searchController: _searchController,
            onSearchChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
          ),

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
              label: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF00875A),
              backgroundColor: Colors.white,
              onSelected: (val) => setState(() => _selectedCategory = cat),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00875A)));
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

        if (docs.isEmpty) {
          return const Center(child: Text('ఫలితాలు ఏవీ దొరకలేదు.'));
        }

        return GridView.builder(
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ProductCard(data: data);
          },
        );
      },
    );
  }
}