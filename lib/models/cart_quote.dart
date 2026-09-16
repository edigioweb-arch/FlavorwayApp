class CartQuoteLineItem {
  const CartQuoteLineItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.optionsTotal,
    required this.lineTotal,
    required this.selectedOptionValueIds,
  });

  final int productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double optionsTotal;
  final double lineTotal;
  final List<int> selectedOptionValueIds;

  factory CartQuoteLineItem.fromJson(Map<String, dynamic> json) {
    final rawIds = (json['selected_option_value_ids'] as List?) ?? const [];

    return CartQuoteLineItem(
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      optionsTotal: (json['options_total'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0,
      selectedOptionValueIds:
          rawIds.map((value) => (value as num).toInt()).toList(growable: false),
    );
  }
}

class CartQuote {
  const CartQuote({
    required this.restaurantId,
    required this.currency,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discountTotal,
    required this.total,
    required this.pricingVersion,
    this.requiresManualQuote = false,
  });

  final int restaurantId;
  final String currency;
  final List<CartQuoteLineItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discountTotal;
  final double total;
  final String pricingVersion;
  final bool requiresManualQuote;

  factory CartQuote.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];

    return CartQuote(
      restaurantId: (json['restaurant_id'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] ?? 'XAF').toString(),
      items: rawItems
          .whereType<Map>()
          .map((item) =>
              CartQuoteLineItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      discountTotal: (json['discount_total'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      pricingVersion: (json['pricing_version'] ?? '').toString(),
      requiresManualQuote: json['requires_manual_quote'] == true,
    );
  }
}
