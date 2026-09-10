class CartItem {
  final String id;
  final String name;
  final double price;
  final String unit; // e.g., '1 kg', '500 g'
  final String imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.imageUrl,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
}