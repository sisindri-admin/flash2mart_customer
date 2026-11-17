class CartItem {
  final String id;
  final String name;
  final double price;
  final double originalAddedPrice;
  final String unit; // e.g., '1 kg', '500 g'
  final String imageUrl;
  int quantity;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    double? originalAddedPrice,
    required this.unit,
    required this.imageUrl,
    this.quantity = 1,
    DateTime? addedAt,
  })  : originalAddedPrice = originalAddedPrice ?? price,
        addedAt = addedAt ?? DateTime.now();

  double get totalPrice => price * quantity;

  bool get hasPriceChanged => (price - originalAddedPrice).abs() >= 0.01;

  double get priceDifference => price - originalAddedPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'originalAddedPrice': originalAddedPrice,
      'unit': unit,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final double currentPrice = ((map['price'] ?? 0) as num).toDouble();
    final double savedOriginalPrice =
        ((map['originalAddedPrice'] ?? currentPrice) as num).toDouble();
    final int qty = ((map['quantity'] ?? 1) as num).toInt();
    final DateTime parsedAddedAt =
        DateTime.tryParse((map['addedAt'] ?? '').toString()) ?? DateTime.now();

    return CartItem(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? 'Product').toString(),
      price: currentPrice,
      originalAddedPrice: savedOriginalPrice,
      unit: (map['unit'] ?? '1 unit').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      quantity: qty > 0 ? qty : 1,
      addedAt: parsedAddedAt,
    );
  }
}