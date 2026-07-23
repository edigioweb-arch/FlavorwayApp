class CartItem {
  final String id;
  final String name;
  final String image;
  final String restaurantName;
  double price;
  int quantity;
  Map<String, dynamic> options;

  CartItem({
    required this.id,
    required this.name,
    required this.image,
    required this.restaurantName,
    required this.price,
    this.quantity = 1,
    this.options = const {},
  });

  double get totalPrice => price * quantity;
}
