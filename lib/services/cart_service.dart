import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/cart_quote.dart';
import 'checkout_quote_service.dart';

enum CartQuoteStatus {
  idle,
  loadingQuote,
  quoteReady,
  quoteError,
}

class CartService extends ChangeNotifier {
  CartService({CheckoutQuoteService? quoteService})
      : _quoteService = quoteService ?? CheckoutQuoteService();

  final CheckoutQuoteService _quoteService;
  final List<CartItem> _items = [];

  CartQuote? _quote;
  CartQuoteStatus _quoteStatus = CartQuoteStatus.idle;
  String? _quoteErrorMessage;
  String? _quotedFingerprint;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  CartQuote? get quote => _quote;
  CartQuoteStatus get quoteStatus => _quoteStatus;
  String? get quoteErrorMessage => _quoteErrorMessage;
  bool get hasValidQuote =>
      _quote != null &&
      _quoteStatus == CartQuoteStatus.quoteReady &&
      _quotedFingerprint == cartFingerprint;

  double get estimatedSubtotal =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get displaySubtotal => hasValidQuote ? _quote!.subtotal : estimatedSubtotal;
  double get displayDeliveryFee => hasValidQuote ? _quote!.deliveryFee : 0;
  double get displayDiscount => hasValidQuote ? _quote!.discountTotal : 0;
  double get displayTotal =>
      hasValidQuote ? _quote!.total : estimatedSubtotal;

  String get displayCurrency => _quote?.currency ?? 'XAF';

  String get cartFingerprint => _items
      .map((item) => '${item.restaurantId}-${item.fingerprint}-${item.quantity}')
      .toList(growable: false)
      .join('|');

  int? get restaurantId => _items.isEmpty ? null : _items.first.restaurantId;

  void addItem(CartItem item) {
    if (_items.isNotEmpty && _items.first.restaurantId != item.restaurantId) {
      throw StateError(
        'Votre panier contient déjà des articles d’un autre restaurant.',
      );
    }

    final existingIndex = _items.indexWhere(
      (existing) => existing.productId == item.productId &&
          listEquals(existing.optionValueIds, item.optionValueIds),
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
      _items[existingIndex].price = item.price;
    } else {
      _items.add(item);
    }

    _invalidateQuote();
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _invalidateQuote();
    notifyListeners();
  }

  void updateQuantity(String id, int newQuantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0 && newQuantity > 0) {
      _items[index].quantity = newQuantity;
      _invalidateQuote();
      notifyListeners();
    } else if (newQuantity <= 0) {
      removeItem(id);
    }
  }

  void clear() {
    _items.clear();
    _invalidateQuote();
    notifyListeners();
  }

  Future<bool> refreshQuote({
    String? deliveryCityId,
    String? deliveryZoneAreaId,
    String? deliveryZoneAreaName,
    String? deliveryAddressLine,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? paymentMethod,
    String? promoCode,
  }) async {
    if (_items.isEmpty || restaurantId == null) {
      _quote = null;
      _quoteStatus = CartQuoteStatus.idle;
      _quoteErrorMessage = null;
      _quotedFingerprint = null;
      notifyListeners();
      return false;
    }

    _quoteStatus = CartQuoteStatus.loadingQuote;
    _quoteErrorMessage = null;
    notifyListeners();

    try {
      final payload = CheckoutQuotePayload(
        restaurantId: restaurantId!,
        items: items,
        deliveryCityId: deliveryCityId,
        deliveryZoneAreaId: deliveryZoneAreaId,
        deliveryZoneAreaName: deliveryZoneAreaName,
        deliveryAddressLine: deliveryAddressLine,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        paymentMethod: paymentMethod,
        promoCode: promoCode,
      );

      final result = await _quoteService.fetchQuote(payload);
      _quote = result;
      _quotedFingerprint = cartFingerprint;
      _quoteStatus = CartQuoteStatus.quoteReady;
      _quoteErrorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _quote = null;
      _quotedFingerprint = null;
      _quoteStatus = CartQuoteStatus.quoteError;
      _quoteErrorMessage = _normalizeError(error);
      notifyListeners();
      return false;
    }
  }

  void _invalidateQuote() {
    _quote = null;
    _quoteStatus = CartQuoteStatus.idle;
    _quoteErrorMessage = null;
    _quotedFingerprint = null;
  }

  String _normalizeError(Object error) {
    final message = error.toString();

    if (message.startsWith('ApiException')) {
      final separator = message.indexOf(':');
      if (separator != -1 && separator + 1 < message.length) {
        return message.substring(separator + 1).trim();
      }
    }

    return 'Impossible de vérifier le montant de votre commande. Réessayez.';
  }
}
