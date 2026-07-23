import '../models/cart_item.dart';
import 'package:flutter/foundation.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  double get totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice) +
      2000; // + livraison

  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere(
        (i) => i.id == item.id && mapEquals(i.options, item.options));
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int newQuantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0 && newQuantity > 0) {
      _items[index].quantity = newQuantity;
      notifyListeners();
    } else if (newQuantity <= 0) {
      removeItem(id);
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
