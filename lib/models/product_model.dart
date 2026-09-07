import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon;

  CategoryModel({required this.id, required this.name, required this.icon});

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '🛒',
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String weight;
  final double price;
  final double originalPrice;
  final String imageUrl;
  final String categoryId;
  final bool isAvailable;

  ProductModel({
    required this.id,
    required this.name,
    required this.weight,
    required this.price,
    required this.originalPrice,
    required this.imageUrl,
    required this.categoryId,
    required this.isAvailable,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      weight: data['weight'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      originalPrice: (data['originalPrice'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      categoryId: data['categoryId'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
    );
  }
}