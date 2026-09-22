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

/// Always reachable while browsing a restaurant, using the shared cart.
class RestaurantCartBar extends StatelessWidget {
  const RestaurantCartBar({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartService>().itemCount;
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 8, 40, 8),
          child: Center(
            heightFactor: 1,
            child: SizedBox(
              width: 220,
              child: FilledButton.icon(
                key: const Key('restaurant-view-cart'),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4B1F5C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(90)),
                ),
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                label: const Text('Voir le panier',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
