import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

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

  int _quoteVersion = 0;
  Map<String, dynamic>? _deliveryAddress;
  String? _paymentMethod;
  String? _promoCode;
  Map<String, dynamic>? get deliveryAddress =>
      _deliveryAddress == null ? null : Map.unmodifiable(_deliveryAddress!);

  CartQuote? _quote;
  CartQuoteStatus _quoteStatus = CartQuoteStatus.idle;
  String? _quoteErrorMessage;
  String? _quotedFingerprint;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (count, item) => count + item.quantity);
  CartQuote? get quote => _quote;
  CartQuoteStatus get quoteStatus => _quoteStatus;
  String? get quoteErrorMessage => _quoteErrorMessage;
  bool get hasValidQuote =>
      _quote != null &&
      _quoteStatus == CartQuoteStatus.quoteReady &&
      _quotedFingerprint == cartFingerprint;

  double get estimatedSubtotal =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get displaySubtotal =>
      hasValidQuote ? _quote!.subtotal : estimatedSubtotal;
  double get displayDeliveryFee => hasValidQuote ? _quote!.deliveryFee : 0;
  double get displayDiscount => hasValidQuote ? _quote!.discountTotal : 0;
  double get displayTotal => hasValidQuote ? _quote!.total : estimatedSubtotal;

  String get displayCurrency => _quote?.currency ?? 'XAF';

  String get cartFingerprint => _items
      .map(
          (item) => '${item.restaurantId}-${item.fingerprint}-${item.quantity}')
      .toList(growable: false)
      .join('|');

  CartQuoteLineItem? quotedLine(CartItem item) {
    if (!hasValidQuote) return null;
    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index < 0 || index >= _quote!.items.length) return null;
    return _quote!.items[index];
  }

  int? get restaurantId => _items.isEmpty ? null : _items.first.restaurantId;

  void addItem(CartItem item) {
    if (_items.isNotEmpty && _items.first.restaurantId != item.restaurantId) {
      throw StateError(
        'Votre panier contient déjà des articles d’un autre restaurant.',
      );
    }

    final existingIndex = _items.indexWhere(
      (existing) =>
          existing.productId == item.productId &&
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
    if (_deliveryAddress != null && _items.isNotEmpty) {
      unawaited(refreshQuote());
    }
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _invalidateQuote();
    notifyListeners();
    if (_deliveryAddress != null && _items.isNotEmpty) {
      unawaited(refreshQuote());
    }
  }

  void updateQuantity(String id, int newQuantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0 && newQuantity > 0) {
      _items[index].quantity = newQuantity;
      _invalidateQuote();
      notifyListeners();
      if (_deliveryAddress != null) unawaited(refreshQuote());
    } else if (newQuantity <= 0) {
      removeItem(id);
    }
  }

  void clear() {
    _items.clear();
    _deliveryAddress = null;
    _paymentMethod = null;
    _promoCode = null;
    _invalidateQuote();
    notifyListeners();
  }

  Future<bool> selectDeliveryAddress(Map<String, dynamic> address,
      {String? paymentMethod}) {
    _deliveryAddress = Map.of(address);
    _invalidateQuote();
    return refreshQuote(paymentMethod: paymentMethod);
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
    final version = ++_quoteVersion;
    if (deliveryAddressLine != null || deliveryCityId != null) {
      _deliveryAddress = {
        'full': deliveryAddressLine,
        'city_id': deliveryCityId,
        'delivery_zone_area_id': deliveryZoneAreaId,
        'delivery_zone_area_name': deliveryZoneAreaName,
        'latitude': deliveryLatitude,
        'longitude': deliveryLongitude,
      };
    }
    _paymentMethod = paymentMethod ?? _paymentMethod;
    _promoCode = promoCode ?? _promoCode;
    if (_items.isEmpty || restaurantId == null) {
      _quote = null;
      _quoteStatus = CartQuoteStatus.idle;
      _quoteErrorMessage = null;
      _quotedFingerprint = null;
      notifyListeners();
      return false;
    }

    final address = _deliveryAddress;
    final cityId = int.tryParse(address?['city_id']?.toString() ?? '');
    if (address == null ||
        (address['full']?.toString().trim() ?? '').isEmpty ||
        cityId == null ||
        cityId <= 0) {
      _quote = null;
      _quotedFingerprint = null;
      _quoteStatus = CartQuoteStatus.quoteError;
      _quoteErrorMessage =
          'Sélectionnez une adresse et une ville valides avant de calculer la livraison.';
      notifyListeners();
      return false;
    }
    final fingerprint = cartFingerprint;
    _quote = null;
    _quoteStatus = CartQuoteStatus.loadingQuote;
    _quoteErrorMessage = null;
    notifyListeners();

    try {
      final payload = CheckoutQuotePayload(
        restaurantId: restaurantId!,
        items: items
            .map((item) => item.copyWith(
                optionValueIds: List.of(item.optionValueIds),
                options: Map.of(item.options)))
            .toList(),
        deliveryCityId: address['city_id']?.toString(),
        deliveryZoneAreaId: address['delivery_zone_area_id']?.toString(),
        deliveryZoneAreaName: address['delivery_zone_area_name']?.toString(),
        deliveryAddressLine: address['full']?.toString(),
        deliveryLatitude: (address['latitude'] as num?)?.toDouble(),
        deliveryLongitude: (address['longitude'] as num?)?.toDouble(),
        paymentMethod: _paymentMethod,
        promoCode: _promoCode,
      );

      final result = await _quoteService.fetchQuote(payload);
      if (version != _quoteVersion || fingerprint != cartFingerprint) {
        return false;
      }
      if (result.requiresManualQuote) {
        throw const ApiException(
            statusCode: 422,
            message:
                'Les frais de livraison pour cette zone doivent être confirmés avant la commande.');
      }
      _quote = result;
      _quotedFingerprint = fingerprint;
      _quoteStatus = CartQuoteStatus.quoteReady;
      _quoteErrorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      if (version != _quoteVersion || fingerprint != cartFingerprint) {
        return false;
      }
      _quote = null;
      _quotedFingerprint = null;
      _quoteStatus = CartQuoteStatus.quoteError;
      _quoteErrorMessage = _normalizeError(error);
      notifyListeners();
      return false;
    }
  }

  void _invalidateQuote() {
    _quoteVersion++;
    _quote = null;
    _quoteStatus = CartQuoteStatus.idle;
    _quoteErrorMessage = null;
    _quotedFingerprint = null;
  }

  String _normalizeError(Object error) {
    if (error is ApiException &&
        (error.message.toLowerCase().contains('devis manuel') ||
            error.message.contains('requires_manual_quote'))) {
      return 'Les frais de livraison pour cette zone doivent être confirmés avant la commande.';
    }
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
