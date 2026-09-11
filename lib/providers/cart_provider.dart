import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount => _items.length;

  int get totalQuantity => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  void addItem({
    required String id,
    required String name,
    required double price,
    required String unit,
    required String imageUrl,
  }) {
    if (_items.containsKey(id)) {
      // ఇప్పటికే ఉన్న Item లో Image URL ఖాళీగా కాకుండా ఉంటే అప్‌డేట్ చేస్తుంది
      final existingItem = _items[id]!;
      _items[id] = CartItem(
        id: existingItem.id,
        name: existingItem.name,
        price: existingItem.price,
        unit: existingItem.unit,
        imageUrl: (imageUrl.isNotEmpty) ? imageUrl : existingItem.imageUrl,
        quantity: existingItem.quantity + 1,
      );
    } else {
      _items[id] = CartItem(
        id: id,
        name: name,
        price: price,
        unit: unit,
        imageUrl: imageUrl,
        quantity: 1,
      );
    }
    notifyListeners();
  }

  void removeSingleItem(String id) {
    if (!_items.containsKey(id)) return;
    if (_items[id]!.quantity > 1) {
      final existingItem = _items[id]!;
      _items[id] = CartItem(
        id: existingItem.id,
        name: existingItem.name,
        price: existingItem.price,
        unit: existingItem.unit,
        imageUrl: existingItem.imageUrl,
        quantity: existingItem.quantity - 1,
      );
    } else {
      _items.remove(id);
    }
    notifyListeners();
  }

  void removeItemCompletely(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}