import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/restaurant_model.dart';
import '../services/cart_service.dart';

/// Only an unambiguous, uncustomized cart line can be edited from the list.
class ProductQuickAdd extends StatelessWidget {
  const ProductQuickAdd(
      {super.key, required this.dish, required this.onOpenDetail});

  final RestaurantDishModel dish;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final productId = int.tryParse(dish.id);
    final restaurantId = int.tryParse(dish.restaurantId);
    final lines = cart.items
        .where((item) =>
            item.productId == productId && item.restaurantId == restaurantId)
        .toList();
    final needsDetail =
        dish.options.any((option) => option.isActive && option.isRequired) ||
            lines.any((item) =>
                item.optionValueIds.isNotEmpty || item.options.isNotEmpty) ||
            lines.length > 1;
    final line = !needsDetail && lines.isNotEmpty ? lines.single : null;

    void add() {
      if (needsDetail || productId == null || restaurantId == null) {
        onOpenDetail();
        return;
      }
      try {
        cart.addItem(CartItem(
          id: '${dish.id}-',
          productId: productId,
          restaurantId: restaurantId,
          name: dish.name,
          image: dish.image ?? '',
          restaurantName: dish.menuName ?? 'Restaurant FlavorWay',
          price: dish.price,
          currencyCode: dish.currencyCode,
        ));
      } on StateError catch (error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          tooltip: 'Ajouter ${dish.name}',
          color: const Color(0xFFF36A2D),
          onPressed: dish.isAvailable ? add : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
        if (line != null) ...[
          Text('${line.quantity}', key: ValueKey('quantity-${dish.id}')),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: 'Retirer ${dish.name}',
            onPressed: () => cart.updateQuantity(line.id, line.quantity - 1),
            icon: const Icon(Icons.remove),
          ),
        ],
      ],
    );
  }
}
