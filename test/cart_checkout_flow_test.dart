import 'dart:async';
import 'package:flavorapps/models/cart_item.dart';
import 'package:flavorapps/models/cart_quote.dart';
import 'package:flavorapps/services/api_client.dart';
import 'package:flavorapps/services/cart_service.dart';
import 'package:flavorapps/services/checkout_quote_service.dart';
import 'package:flutter_test/flutter_test.dart';

class ControlledQuotes extends CheckoutQuoteService {
  final requests = <CheckoutQuotePayload>[];
  final responses = <Completer<CartQuote>>[];
  @override
  Future<CartQuote> fetchQuote(CheckoutQuotePayload payload) {
    requests.add(payload);
    final response = Completer<CartQuote>();
    responses.add(response);
    return response.future;
  }
}

CartItem item(
        {String id = '10', int quantity = 1, List<int> options = const []}) =>
    CartItem(
      id: id,
      productId: 10,
      restaurantId: 1,
      name: 'Plat',
      image: '',
      restaurantName: 'Restaurant',
      price: 1000,
      currencyCode: 'XAF',
      quantity: quantity,
      optionValueIds: options,
    );
CartQuote quote(double total, {bool manual = false}) => CartQuote(
      restaurantId: 1,
      currency: 'XAF',
      items: const [],
      subtotal: total - 100,
      deliveryFee: 100,
      discountTotal: 0,
      total: total,
      pricingVersion: 'test',
      requiresManualQuote: manual,
    );
const address = {
  'full': 'Rue test',
  'city_id': '1',
  'delivery_zone_area_id': '2'
};

void main() {
  late ControlledQuotes api;
  late CartService cart;
  setUp(() {
    api = ControlledQuotes();
    cart = CartService(quoteService: api);
    cart.addItem(item());
  });

  test('no network quote before address, invalid city is explained', () async {
    expect(await cart.refreshQuote(), isFalse);
    cart.selectDeliveryAddress({'full': 'Rue', 'city_id': 'invalid'});
    expect(await cart.refreshQuote(), isFalse);
    expect(api.requests, isEmpty);
    expect(cart.quoteErrorMessage, contains('ville'));
  });
  test('address and coordinates precede quote, mobile amounts are excluded',
      () async {
    final pending = cart.selectDeliveryAddress(
        {...address, 'latitude': -4, 'longitude': 15.2},
        paymentMethod: 'cash');
    final payload = api.requests.single.toJson();
    expect(payload['delivery_address']['city_id'], 1);
    expect(payload['delivery_address']['delivery_zone_area_id'], 2);
    expect(payload['delivery_address']['latitude'], -4);
    expect(payload.containsKey('total'), isFalse);
    expect(payload['items'][0].containsKey('price'), isFalse);
    api.responses.single.complete(quote(1100));
    expect(await pending, isTrue);
  });
  test(
      'quantity change recalculates and stale success cannot overwrite newest quote',
      () async {
    final a = cart.selectDeliveryAddress(address);
    cart.updateQuantity('10', 3);
    expect(api.requests.length, 2);
    expect(api.requests[0].items.single.quantity, 1);
    expect(api.requests[1].items.single.quantity, 3);
    api.responses[1].complete(quote(3100));
    await Future<void>.delayed(Duration.zero);
    api.responses[0].complete(quote(1100));
    expect(await a, isFalse);
    expect(cart.quote!.total, 3100);
    expect(cart.hasValidQuote, isTrue);
  });
  test('stale failure cannot clear newest quote', () async {
    final a = cart.selectDeliveryAddress(address);
    final b = cart.refreshQuote();
    api.responses[1].complete(quote(2100));
    await b;
    api.responses[0].completeError(
        const ApiException(statusCode: 422, message: 'Ancien échec'));
    expect(await a, isFalse);
    expect(cart.quote!.total, 2100);
    expect(cart.quoteErrorMessage, isNull);
  });
  test('address and zone change invalidate an in-flight quote', () async {
    final a = cart.selectDeliveryAddress(address);
    final b =
        cart.selectDeliveryAddress({...address, 'delivery_zone_area_id': '3'});
    expect(cart.hasValidQuote, isFalse);
    expect(api.requests[1].deliveryZoneAreaId, '3');
    api.responses[1].complete(quote(2500));
    await b;
    api.responses[0].complete(quote(1100));
    await a;
    expect(cart.quote!.total, 2500);
  });
  test('removing a variant recalculates the remaining lines', () async {
    cart.addItem(item(id: '10-2', options: [2]));
    final a = cart.selectDeliveryAddress(address);
    api.responses[0].complete(quote(2100));
    await a;
    cart.removeItem('10-2');
    expect(api.requests[1].items.length, 1);
    api.responses[1].complete(quote(1100));
    await Future<void>.delayed(Duration.zero);
    expect(cart.quote!.total, 1100);
  });
  test('clear invalidates pending requests and resets badge', () async {
    final a = cart.selectDeliveryAddress(address);
    cart.clear();
    api.responses[0].complete(quote(1100));
    expect(await a, isFalse);
    expect(cart.itemCount, 0);
    expect(cart.quote, isNull);
    expect(cart.deliveryAddress, isNull);
  });
  test('manual quote flag cannot become a valid zero-fee quote', () async {
    final a = cart.selectDeliveryAddress(address);
    api.responses[0].complete(quote(1000, manual: true));
    expect(await a, isFalse);
    expect(cart.hasValidQuote, isFalse);
    expect(cart.quoteErrorMessage, contains('confirmés avant la commande'));
    expect(cart.itemCount, 1);
    expect(cart.deliveryAddress, address);
  });
  test('delivery validation failure preserves address and cart', () async {
    final a = cart.selectDeliveryAddress(address);
    api.responses[0].completeError(
        const ApiException(statusCode: 422, message: 'Ville inactive'));
    expect(await a, isFalse);
    expect(cart.quoteErrorMessage, 'Ville inactive');
    expect(cart.itemCount, 1);
    expect(cart.deliveryAddress, address);
  });
  test('address selection automatically uses server totals, not local estimate',
      () async {
    final pending = cart.selectDeliveryAddress(address);
    expect(api.requests.length, 1);
    api.responses.single.complete(quote(7345));
    await pending;
    expect(cart.displaySubtotal, 7245);
    expect(cart.displayDeliveryFee, 100);
    expect(cart.displayTotal, 7345);
    expect(cart.estimatedSubtotal, 1000);
  });
  test('changing address and city automatically sends new request', () async {
    final first = cart.selectDeliveryAddress(address);
    final second = cart.selectDeliveryAddress(
        {...address, 'full': 'Autre adresse', 'city_id': '2'});
    expect(api.requests.last.deliveryCityId, '2');
    expect(api.requests.last.deliveryAddressLine, 'Autre adresse');
    api.responses[1].complete(quote(2500));
    await second;
    api.responses[0].complete(quote(1100));
    await first;
    expect(cart.displayTotal, 2500);
  });
  test('adding an option variant automatically requotes', () async {
    final first = cart.selectDeliveryAddress(address);
    api.responses[0].complete(quote(1100));
    await first;
    cart.addItem(item(id: 'variant', options: [4]));
    expect(api.requests.length, 2);
    expect(api.requests.last.items.last.optionValueIds, [4]);
    api.responses[1].complete(quote(3200));
    await Future<void>.delayed(Duration.zero);
    expect(cart.displayTotal, 3200);
  });
  test('promo change and removal invalidate previous financial response',
      () async {
    final first = cart.selectDeliveryAddress(address, paymentMethod: 'cash');
    api.responses[0].complete(quote(1100));
    await first;
    final promo = cart.refreshQuote(promoCode: 'PROMO');
    final removal = cart.refreshQuote(promoCode: '');
    expect(api.requests[1].promoCode, 'PROMO');
    expect(api.requests[2].promoCode, '');
    api.responses[2].complete(quote(1100));
    await removal;
    api.responses[1].complete(quote(900));
    await promo;
    expect(cart.displayTotal, 1100);
  });
  test('same product with different options remains two lines', () {
    cart.addItem(item(id: '10-2', quantity: 2, options: [2]));
    expect(cart.items.length, 2);
    expect(cart.itemCount, 3);
  });
}
