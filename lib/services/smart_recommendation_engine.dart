import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategorySectionGroup {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color bgTint;
  final List<QueryDocumentSnapshot> products;

  const CategorySectionGroup({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.bgTint,
    required this.products,
  });
}

class SmartRecommendationEngine {
  static const List<String> _dairyKeywords = [
    'milk',
    'curd',
    'dahi',
    'paneer',
    'butter',
    'ghee',
    'cheese',
    'lassi',
    'buttermilk',
    'cream',
    'dairy',
    'amul',
    'heritage',
    'dodla',
    'arokya',
    'tirumala',
    'nandini',
    'paalu',
    'perugu',
  ];

  static const List<String> _cookingKeywords = [
    'oil',
    'sunflower',
    'groundnut',
    'rice',
    'sona',
    'basmati',
    'atta',
    'wheat',
    'flour',
    'maida',
    'rava',
    'sooji',
    'dal',
    'toor',
    'moong',
    'urad',
    'chana',
    'sugar',
    'salt',
    'jaggery',
    'masala',
    'spice',
    'turmeric',
    'chilli',
    'coriander',
    'tamarind',
    'ghee',
    'tea',
    'coffee',
    'bread',
    'cooking',
    'grocery',
  ];

  static const List<String> _veggieFruitKeywords = [
    'tomato',
    'onion',
    'potato',
    'mirchi',
    'chilli',
    'ginger',
    'garlic',
    'lemon',
    'carrot',
    'beans',
    'brinjal',
    'okra',
    'bhendi',
    'cabbage',
    'cauliflower',
    'spinach',
    'palak',
    'coriander',
    'mint',
    'curry',
    'vegetable',
    'veggie',
    'fruit',
    'apple',
    'banana',
    'orange',
    'papaya',
    'pomegranate',
  ];

  static bool _matchesAny(String text, List<String> keywords) {
    final String lower = text.toLowerCase();
    for (final kw in keywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  static List<QueryDocumentSnapshot> getRelatedProducts({
    required String currentProductId,
    required String currentName,
    required String currentCategory,
    required List<QueryDocumentSnapshot> allDocs,
  }) {
    final List<QueryDocumentSnapshot> others =
        allDocs.where((d) => d.id != currentProductId).toList();
    if (others.isEmpty) return [];

    final String targetText = '$currentName $currentCategory'.toLowerCase();
    final bool isDairy = _matchesAny(targetText, _dairyKeywords);
    final bool isCooking = _matchesAny(targetText, _cookingKeywords);
    final bool isVeggie = _matchesAny(targetText, _veggieFruitKeywords);

    final List<String> nameWords = currentName
        .toLowerCase()
        .split(RegExp(r'[\s,()/-]+'))
        .where((w) => w.length >= 3)
        .toList();

    int scoreDoc(QueryDocumentSnapshot doc) {
      final data = doc.data() as Map<String, dynamic>;
      final String name =
          (data['name'] ?? data['title'] ?? '').toString().toLowerCase();
      final String cat = (data['category'] ?? '').toString().toLowerCase();
      final String desc = (data['description'] ?? '').toString().toLowerCase();
      final String combined = '$name $cat $desc';
      final int stock = ((data['stock'] ?? 1) as num).toInt();

      int score = stock > 0 ? 10 : 0;

      for (final w in nameWords) {
        if (name.contains(w)) score += 50;
      }

      if (isDairy && _matchesAny(combined, _dairyKeywords)) {
        score += 40;
      }
      if (isCooking && _matchesAny(combined, _cookingKeywords)) {
        score += 35;
      }
      if (isVeggie && _matchesAny(combined, _veggieFruitKeywords)) {
        score += 35;
      }

      if (currentCategory.isNotEmpty &&
          cat.contains(currentCategory.toLowerCase())) {
        score += 25;
      }

      if (isDairy && _matchesAny(combined, _cookingKeywords)) {
        score += 18;
      }

      return score;
    }

    final List<QueryDocumentSnapshot> sorted =
        List<QueryDocumentSnapshot>.from(others);
    sorted.sort((a, b) => scoreDoc(b).compareTo(scoreDoc(a)));
    return sorted;
  }

  static List<QueryDocumentSnapshot> getCookingAndCompanionProducts({
    required String currentProductId,
    required String currentName,
    required List<QueryDocumentSnapshot> allDocs,
  }) {
    final List<QueryDocumentSnapshot> others =
        allDocs.where((d) => d.id != currentProductId).toList();
    if (others.isEmpty) return [];

    final List<QueryDocumentSnapshot> cookingMatches = others.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final String combined =
          '${data['name'] ?? ''} ${data['category'] ?? ''} ${data['description'] ?? ''}'
              .toLowerCase();
      return _matchesAny(combined, _cookingKeywords) ||
          _matchesAny(combined, _dairyKeywords) ||
          _matchesAny(combined, _veggieFruitKeywords);
    }).toList();

    if (cookingMatches.isNotEmpty) {
      return cookingMatches;
    }
    return others;
  }

  static List<CategorySectionGroup> buildCategorySections(
    List<QueryDocumentSnapshot> allDocs, {
    String? excludeProductId,
  }) {
    final List<QueryDocumentSnapshot> pool = excludeProductId == null
        ? allDocs
        : allDocs.where((d) => d.id != excludeProductId).toList();

    if (pool.isEmpty) return [];

    final List<CategorySectionGroup> groups = [];

    final List<QueryDocumentSnapshot> dairyDocs = pool.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final String text =
          '${data['name'] ?? ''} ${data['category'] ?? ''}'.toLowerCase();
      return _matchesAny(text, _dairyKeywords);
    }).toList();

    if (dairyDocs.isNotEmpty) {
      groups.add(
        CategorySectionGroup(
          title: 'Milk, Curd & Fresh Dairy',
          subtitle: 'Farm fresh milk packets, curd, paneer & ghee',
          icon: Icons.egg_alt_rounded,
          accentColor: const Color(0xFF0284C7),
          bgTint: const Color(0xFFF0F9FF),
          products: dairyDocs,
        ),
      );
    }

    final List<QueryDocumentSnapshot> veggieDocs = pool.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final String text =
          '${data['name'] ?? ''} ${data['category'] ?? ''}'.toLowerCase();
      return text.contains('vegetable') ||
          text.contains('fruit') ||
          _matchesAny(text, _veggieFruitKeywords);
    }).toList();

    if (veggieDocs.isNotEmpty) {
      groups.add(
        CategorySectionGroup(
          title: 'Fresh Vegetables & Fruits',
          subtitle: 'Handpicked daily from local farms',
          icon: Icons.eco_rounded,
          accentColor: const Color(0xFF16A34A),
          bgTint: const Color(0xFFF0FDF4),
          products: veggieDocs,
        ),
      );
    }

    final List<QueryDocumentSnapshot> groceryDocs = pool.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final String text =
          '${data['name'] ?? ''} ${data['category'] ?? ''}'.toLowerCase();
      return text.contains('grocery') ||
          text.contains('supermarket') ||
          _matchesAny(text, _cookingKeywords);
    }).toList();

    if (groceryDocs.isNotEmpty) {
      groups.add(
        CategorySectionGroup(
          title: 'Cooking & Daily Grocery',
          subtitle: 'Oils, rice, dals, atta, spices & kitchen staples',
          icon: Icons.soup_kitchen_rounded,
          accentColor: const Color(0xFFD97706),
          bgTint: const Color(0xFFFFFBEB),
          products: groceryDocs,
        ),
      );
    }

    final List<QueryDocumentSnapshot> pharmaDocs = pool.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final String cat = (data['category'] ?? '').toString().toLowerCase();
      return cat.contains('medicine') || cat.contains('pharma');
    }).toList();

    if (pharmaDocs.isNotEmpty) {
      groups.add(
        CategorySectionGroup(
          title: 'Medicines & Wellness',
          subtitle: 'Fast doorstep healthcare & essentials',
          icon: Icons.medical_services_rounded,
          accentColor: const Color(0xFFDC2626),
          bgTint: const Color(0xFFFEF2F2),
          products: pharmaDocs,
        ),
      );
    }

    final List<QueryDocumentSnapshot> elecDocs = pool.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final String cat = (data['category'] ?? '').toString().toLowerCase();
      return cat.contains('electronic');
    }).toList();

    if (elecDocs.isNotEmpty) {
      groups.add(
        CategorySectionGroup(
          title: 'Electronics & Accessories',
          subtitle: 'Everyday gadgets & home essentials',
          icon: Icons.devices_other_rounded,
          accentColor: const Color(0xFF7C3AED),
          bgTint: const Color(0xFFF5F3FF),
          products: elecDocs,
        ),
      );
    }

    if (groups.isEmpty && pool.isNotEmpty) {
      groups.add(
        CategorySectionGroup(
          title: 'Popular Store Picks',
          subtitle: 'Top rated essentials delivered in 15 mins',
          icon: Icons.local_mall_rounded,
          accentColor: const Color(0xFF00875A),
          bgTint: const Color(0xFFF0FDF4),
          products: pool,
        ),
      );
    }

    return groups;
  }

  static CategorySectionGroup generateEndlessSection({
    required int batchIndex,
    required List<QueryDocumentSnapshot> allDocs,
  }) {
    const List<Map<String, dynamic>> themes = [
      {
        'title': 'Daily Cooking & Kitchen Needs',
        'subtitle': 'Must-have ingredients for your kitchen today',
        'icon': Icons.restaurant_rounded,
        'color': Color(0xFF00875A),
        'bg': Color(0xFFF0FDF4),
      },
      {
        'title': 'Trending in Nellore Today',
        'subtitle': 'Most ordered products in Podalakur Rd & Nellore',
        'icon': Icons.trending_up_rounded,
        'color': Color(0xFF2563EB),
        'bg': Color(0xFFEFF6FF),
      },
      {
        'title': 'Super Savers & Budget Picks',
        'subtitle': 'Best value everyday groceries & packs',
        'icon': Icons.savings_rounded,
        'color': Color(0xFFD97706),
        'bg': Color(0xFFFFFBEB),
      },
      {
        'title': 'Fresh Morning & Dairy Essentials',
        'subtitle': 'Milk, curd, veggies & breakfast favorites',
        'icon': Icons.wb_sunny_rounded,
        'color': Color(0xFF0284C7),
        'bg': Color(0xFFF0F9FF),
      },
      {
        'title': 'Recommended Store Favorites',
        'subtitle': 'Curated based on what you viewed',
        'icon': Icons.workspace_premium_rounded,
        'color': Color(0xFF7C3AED),
        'bg': Color(0xFFF5F3FF),
      },
    ];

    final theme = themes[batchIndex % themes.length];
    if (allDocs.isEmpty) {
      return CategorySectionGroup(
        title: theme['title'] as String,
        subtitle: theme['subtitle'] as String,
        icon: theme['icon'] as IconData,
        accentColor: theme['color'] as Color,
        bgTint: theme['bg'] as Color,
        products: const [],
      );
    }

    final int count = allDocs.length;
    final int takeCount = count >= 6 ? 6 : count;
    final List<QueryDocumentSnapshot> rotated = List.generate(takeCount, (i) {
      final int idx = (batchIndex * 3 + i) % count;
      return allDocs[idx];
    });

    return CategorySectionGroup(
      title: theme['title'] as String,
      subtitle: theme['subtitle'] as String,
      icon: theme['icon'] as IconData,
      accentColor: theme['color'] as Color,
      bgTint: theme['bg'] as Color,
      products: rotated,
    );
  }
}
