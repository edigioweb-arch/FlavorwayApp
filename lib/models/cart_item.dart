import 'package:flutter/foundation.dart';

class CartItem {
  CartItem({
    required this.id,
    required this.productId,
    required this.restaurantId,
    required this.name,
    required this.image,
    required this.restaurantName,
    required this.price,
    required this.currencyCode,
    this.quantity = 1,
    this.options = const {},
    this.optionValueIds = const [],
  });

  final String id;
  final int productId;
  final int restaurantId;
  final String name;
  final String image;
  final String restaurantName;
  final String currencyCode;
  double price;
  int quantity;
  Map<String, dynamic> options;
  List<int> optionValueIds;

  double get totalPrice => price * quantity;

  String get fingerprint =>
      '$productId::${[...optionValueIds]..sort((a, b) => a.compareTo(b))}';

  CartItem copyWith({
    String? id,
    int? productId,
    int? restaurantId,
    String? name,
    String? image,
    String? restaurantName,
    String? currencyCode,
    double? price,
    int? quantity,
    Map<String, dynamic>? options,
    List<int>? optionValueIds,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      image: image ?? this.image,
      restaurantName: restaurantName ?? this.restaurantName,
      currencyCode: currencyCode ?? this.currencyCode,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      options: options ?? this.options,
      optionValueIds: optionValueIds ?? this.optionValueIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CartItem &&
        other.productId == productId &&
        other.restaurantId == restaurantId &&
        listEquals(other.optionValueIds, optionValueIds);
  }

  @override
  int get hashCode => Object.hash(
        productId,
        restaurantId,
        Object.hashAll(optionValueIds),
      );
}
