import '../models/cart_item.dart';
import '../models/cart_quote.dart';
import 'api_client.dart';

class CheckoutQuotePayload {
  const CheckoutQuotePayload({
    required this.restaurantId,
    required this.items,
    this.deliveryCityId,
    this.deliveryZoneAreaId,
    this.deliveryZoneAreaName,
    this.deliveryAddressLine,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.paymentMethod,
    this.promoCode,
  });

  final int restaurantId;
  final List<CartItem> items;
  final String? deliveryCityId;
  final String? deliveryZoneAreaId;
  final String? deliveryZoneAreaName;
  final String? deliveryAddressLine;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? paymentMethod;
  final String? promoCode;

  Map<String, dynamic> toJson() {
    return {
      'restaurant_id': restaurantId,
      'items': items
          .map(
            (item) => {
              'product_id': item.productId,
              'quantity': item.quantity,
              'option_value_ids': item.optionValueIds,
            },
          )
          .toList(growable: false),
      'delivery_address': {
        if (deliveryCityId != null && deliveryCityId!.isNotEmpty)
          'city_id': int.tryParse(deliveryCityId!),
        if (deliveryZoneAreaId != null && deliveryZoneAreaId!.isNotEmpty)
          'delivery_zone_area_id': int.tryParse(deliveryZoneAreaId!),
        if (deliveryZoneAreaName != null && deliveryZoneAreaName!.isNotEmpty)
          'delivery_zone_area_name': deliveryZoneAreaName,
        if (deliveryAddressLine != null && deliveryAddressLine!.isNotEmpty)
          'address_line': deliveryAddressLine,
        if (deliveryLatitude != null) 'latitude': deliveryLatitude,
        if (deliveryLongitude != null) 'longitude': deliveryLongitude,
      },
      'payment_method': paymentMethod,
      'promo_code': promoCode,
    };
  }
}

class CheckoutQuoteService {
  CheckoutQuoteService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<CartQuote> fetchQuote(CheckoutQuotePayload payload) async {
    final response = await _client.postJson(
      '/api/v1/checkout/quote',
      body: payload.toJson(),
    );

    return CartQuote.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }
}
