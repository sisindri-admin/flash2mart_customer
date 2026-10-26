import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  final Map<String, Map<String, dynamic>> _liveCatalogCache = {};

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot>? _productsSubscription;
  String? _activeUserId;
  bool _isRestoringCart = false;

  CartProvider() {
    _initializePersistentCartAndPriceSync();
  }

  Map<String, CartItem> get items => _items;

  int get itemCount => _items.length;

  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  List<CartItem> get priceChangedItems =>
      _items.values.where((item) => item.hasPriceChanged).toList();

  bool get hasAnyPriceChanges => priceChangedItems.isNotEmpty;

  void _initializePersistentCartAndPriceSync() {
    // 1. Listen to real-time product catalog changes so cart prices stay 100% up-to-date
    //    even if a customer opens the app 10 days after adding items to the cart.
    _productsSubscription = FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        _liveCatalogCache[doc.id] = doc.data();
      }
      _reconcileCartWithLiveCatalog();
    }, onError: (_) {});

    // 2. Listen to Firebase Auth state changes to restore & sync user's saved cart on login/app start
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        if (_activeUserId != user.uid) {
          _activeUserId = user.uid;
          _restoreCartFromFirestore(user.uid);
        }
      } else {
        _activeUserId = null;
      }
    }, onError: (_) {});
  }

  Future<void> _restoreCartFromFirestore(String uid) async {
    if (_isRestoringCart) return;
    _isRestoringCart = true;

    try {
      final DocumentSnapshot<Map<String, dynamic>> cartDoc =
          await FirebaseFirestore.instance.collection('carts').doc(uid).get();

      final Map<String, CartItem> guestItems = Map<String, CartItem>.from(_items);
      final Map<String, CartItem> restored = {};

      if (cartDoc.exists && cartDoc.data() != null) {
        final data = cartDoc.data()!;
        final List<dynamic> rawList = (data['items'] as List<dynamic>?) ?? [];
        for (final raw in rawList) {
          if (raw is Map) {
            final map = Map<String, dynamic>.from(raw);
            final item = CartItem.fromMap(map);
            if (item.id.isNotEmpty && item.quantity > 0) {
              restored[item.id] = item;
            }
          }
        }
      }

      // Merge any items added before login into the restored cart
      for (final entry in guestItems.entries) {
        if (restored.containsKey(entry.key)) {
          final existing = restored.remove(entry.key)!;
          restored[entry.key] = CartItem(
            id: existing.id,
            name: entry.value.name.isNotEmpty ? entry.value.name : existing.name,
            price: entry.value.price,
            originalAddedPrice: existing.originalAddedPrice,
            unit: entry.value.unit.isNotEmpty ? entry.value.unit : existing.unit,
            imageUrl: entry.value.imageUrl.isNotEmpty
                ? entry.value.imageUrl
                : existing.imageUrl,
            quantity: existing.quantity,
            addedAt: existing.addedAt,
          );
        } else {
          restored[entry.key] = entry.value;
        }
      }

      _items
        ..clear()
        ..addAll(restored);

      _reconcileCartWithLiveCatalog(saveAfterReconcile: true);
      notifyListeners();
    } catch (e) {
      debugPrint('Error restoring persistent cart: $e');
    } finally {
      _isRestoringCart = false;
    }
  }

  void _reconcileCartWithLiveCatalog({bool saveAfterReconcile = false}) {
    if (_items.isEmpty || _liveCatalogCache.isEmpty) {
      if (saveAfterReconcile) _persistCartToFirestore();
      return;
    }

    bool anyChanged = false;
    final List<String> keys = _items.keys.toList();

    for (final productId in keys) {
      final CartItem currentItem = _items[productId]!;
      final Map<String, dynamic>? liveData = _liveCatalogCache[productId];
      if (liveData == null) continue;

      final double livePrice = ((liveData['price'] ?? currentItem.price) as num).toDouble();
      final String liveName =
          (liveData['name'] ?? liveData['title'] ?? currentItem.name).toString();
      final String liveUnit =
          (liveData['unit'] ?? liveData['weight'] ?? currentItem.unit).toString();
      final String liveImg = (liveData['imageBase64'] ??
              liveData['imageUrl'] ??
              liveData['image'] ??
              currentItem.imageUrl)
          .toString();

      if ((livePrice - currentItem.price).abs() >= 0.01 ||
          liveName != currentItem.name ||
          liveUnit != currentItem.unit ||
          (currentItem.imageUrl.isEmpty && liveImg.isNotEmpty)) {
        _items[productId] = CartItem(
          id: currentItem.id,
          name: liveName,
          price: livePrice,
          originalAddedPrice: currentItem.originalAddedPrice,
          unit: liveUnit,
          imageUrl: liveImg.isNotEmpty ? liveImg : currentItem.imageUrl,
          quantity: currentItem.quantity,
          addedAt: currentItem.addedAt,
        );
        anyChanged = true;
      }
    }

    if (anyChanged) {
      notifyListeners();
    }
    if (anyChanged || saveAfterReconcile) {
      _persistCartToFirestore();
    }
  }

  Future<void> _persistCartToFirestore() async {
    final String? uid = _activeUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    try {
      final List<Map<String, dynamic>> serializedItems =
          _items.values.map((item) => item.toMap()).toList();

      await FirebaseFirestore.instance.collection('carts').doc(uid).set({
        'userId': uid,
        'items': serializedItems,
        'itemCount': _items.length,
        'totalQuantity': totalQuantity,
        'totalAmount': totalAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving persistent cart: $e');
    }
  }

  void addItem({
    required String id,
    required String name,
    required double price,
    required String unit,
    required String imageUrl,
  }) {
    final Map<String, dynamic>? liveData = _liveCatalogCache[id];
    final double effectiveLivePrice = liveData != null
        ? ((liveData['price'] ?? price) as num).toDouble()
        : price;

    if (_items.containsKey(id)) {
      final existingItem = _items.remove(id)!;
      _items[id] = CartItem(
        id: existingItem.id,
        name: name.isNotEmpty ? name : existingItem.name,
        price: effectiveLivePrice,
        originalAddedPrice: existingItem.originalAddedPrice,
        unit: unit.isNotEmpty ? unit : existingItem.unit,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : existingItem.imageUrl,
        quantity: existingItem.quantity + 1,
        addedAt: existingItem.addedAt,
      );
    } else {
      _items[id] = CartItem(
        id: id,
        name: name,
        price: effectiveLivePrice,
        originalAddedPrice: effectiveLivePrice,
        unit: unit,
        imageUrl: imageUrl,
        quantity: 1,
        addedAt: DateTime.now(),
      );
    }
    notifyListeners();
    _persistCartToFirestore();
  }

  void removeSingleItem(String id) {
    if (!_items.containsKey(id)) return;
    if (_items[id]!.quantity > 1) {
      final existingItem = _items[id]!;
      _items[id] = CartItem(
        id: existingItem.id,
        name: existingItem.name,
        price: existingItem.price,
        originalAddedPrice: existingItem.originalAddedPrice,
        unit: existingItem.unit,
        imageUrl: existingItem.imageUrl,
        quantity: existingItem.quantity - 1,
        addedAt: existingItem.addedAt,
      );
    } else {
      _items.remove(id);
    }
    notifyListeners();
    _persistCartToFirestore();
  }

  void removeItemCompletely(String id) {
    _items.remove(id);
    notifyListeners();
    _persistCartToFirestore();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    _persistCartToFirestore();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _productsSubscription?.cancel();
    super.dispose();
  }
}