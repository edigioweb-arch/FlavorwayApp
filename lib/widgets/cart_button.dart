import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';

class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartService>().itemCount;
    return IconButton(
      key: const Key('home-cart'),
      tooltip: 'Mon panier ($count articles)',
      onPressed: () => Navigator.pushNamed(context, '/cart'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count', key: const Key('cart-quantity')),
        child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
      ),
    );
  }
}
