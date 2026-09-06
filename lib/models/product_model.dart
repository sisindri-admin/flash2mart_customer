class CategoryModel {
  final String id;
  final String name;
  final String icon;

  CategoryModel({required this.id, required this.name, required this.icon});
}

class ProductModel {
  final String id;
  final String name;
  final String weight;
  final double price;
  final double originalPrice;
  final String imageUrl;

  ProductModel({
    required this.id,
    required this.name,
    required this.weight,
    required this.price,
    required this.originalPrice,
    required this.imageUrl,
  });
}