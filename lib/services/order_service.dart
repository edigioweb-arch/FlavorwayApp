import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import 'api_client.dart';

class TimelineStep {
  const TimelineStep({
    required this.status,
    required this.timestamp,
    required this.updatedBy,
  });

  final String status;
  final DateTime timestamp;
  final String updatedBy;

  factory TimelineStep.fromJson(Map<String, dynamic> data) {
    return TimelineStep(
      status: (data['to_status'] ?? data['status'] ?? '').toString(),
      timestamp: DateTime.tryParse(
            (data['changed_at'] ?? data['timestamp'] ?? '').toString(),
          ) ??
          DateTime.now(),
      updatedBy: (data['source'] ?? data['updatedBy'] ?? 'system').toString(),
    );
  }
}

class OrderItemModel {
  const OrderItemModel({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.optionsTotal,
    required this.lineTotal,
    required this.options,
  });

  final String name;
  final int quantity;
  final double unitPrice;
  final double optionsTotal;
  final double lineTotal;
  final List<Map<String, dynamic>> options;

  factory OrderItemModel.fromJson(Map<String, dynamic> data) {
    final rawOptions = (data['options'] as List?) ?? const [];

    return OrderItemModel(
      name: (data['name'] ?? '').toString(),
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (data['unit_price'] as num?)?.toDouble() ?? 0,
      optionsTotal: (data['options_total'] as num?)?.toDouble() ?? 0,
      lineTotal: (data['line_total'] as num?)?.toDouble() ?? 0,
      options: rawOptions
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false),
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.orderId,
    required this.orderNumber,
    required this.restaurantName,
    required this.restaurantId,
    required this.items,
    required this.total,
    required this.subtotal,
    required this.deliveryFee,
    required this.discountTotal,
    required this.deliveryMode,
    required this.deliveryZoneName,
    required this.status,
    required this.paymentStatus,
    required this.timeline,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.note,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    this.courierName = '',
    this.courierPhone = '',
    this.courierVehicle = '',
  });

  final int orderId;
  final String orderNumber;
  final String restaurantName;
  final String restaurantId;
  final List<OrderItemModel> items;
  final double total;
  final double subtotal;
  final double deliveryFee;
  final double discountTotal;
  final String deliveryMode;
  final String deliveryZoneName;
  final String status;
  final String paymentStatus;
  final List<TimelineStep> timeline;
  final String deliveryAddress;
  final String paymentMethod;
  final String note;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String courierName;
  final String courierPhone;
  final String courierVehicle;

  factory OrderModel.fromJson(Map<String, dynamic> data) {
    final restaurant = Map<String, dynamic>.from(
      (data['restaurant'] as Map?) ?? const {},
    );
    final rawItems = (data['items'] as List?) ?? const [];
    final rawHistory = (data['status_history'] as List?) ?? const [];
    final address = Map<String, dynamic>.from(
      (data['delivery_address'] as Map?) ?? const {},
    );
    final deliveryZone = Map<String, dynamic>.from(
      (data['delivery_zone'] as Map?) ?? const {},
    );

    final timeline = rawHistory
        .whereType<Map>()
        .map((entry) => TimelineStep.fromJson(Map<String, dynamic>.from(entry)))
        .toList(growable: false);

    final createdAt = DateTime.tryParse(
          (data['placed_at'] ?? data['created_at'] ?? '').toString(),
        ) ??
        DateTime.now();

    return OrderModel(
      orderId: (data['id'] as num?)?.toInt() ?? 0,
      orderNumber: (data['order_number'] ?? '').toString(),
      restaurantName: (restaurant['name'] ?? 'Restaurant').toString(),
      restaurantId: (restaurant['id'] ?? '').toString(),
      items: rawItems
          .whereType<Map>()
          .map((item) => OrderItemModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      total: (data['total'] as num?)?.toDouble() ?? 0,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (data['delivery_fee'] as num?)?.toDouble() ?? 0,
      discountTotal: (data['discount_total'] as num?)?.toDouble() ?? 0,
      deliveryMode: (data['delivery_mode'] ?? '').toString(),
      deliveryZoneName: (deliveryZone['name'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      paymentStatus: (data['payment_status'] ?? '').toString(),
      timeline: timeline,
      deliveryAddress: [
        address['label'],
        address['address_line'],
        address['city'],
      ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' • '),
      paymentMethod: (data['payment_method'] ?? '').toString(),
      note: (data['notes'] ?? '').toString(),
      currency: (data['currency'] ?? 'XAF').toString(),
      createdAt: createdAt,
      updatedAt: timeline.isNotEmpty ? timeline.first.timestamp : createdAt,
      courierName: '',
      courierPhone: '',
      courierVehicle: '',
    );
  }

  bool get isActive =>
      status != 'delivered' &&
      status != 'cancelled' &&
      status != 'payment_failed';

  String get displayStatus {
    switch (status) {
      case 'pending_payment':
        return 'Paiement en attente';
      case 'confirmed':
        return 'Commande reçue';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prête';
      case 'picked_up':
        return 'Récupérée';
      case 'on_the_way':
        return 'En livraison';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      case 'payment_failed':
        return 'Paiement échoué';
      default:
        return status;
    }
  }

  TimelineStep get lastTimelineStep => timeline.isNotEmpty
      ? timeline.first
      : TimelineStep(
          status: displayStatus,
          timestamp: updatedAt,
          updatedBy: 'system',
        );

  bool get isTerminal => !isActive;
}

class OrderService extends ChangeNotifier {
  OrderService({
    ApiClient? apiClient,
    FirebaseAuth? auth,
  })  : _apiClient = apiClient ?? ApiClient(),
        _auth = auth ?? FirebaseAuth.instance;

  static final OrderService instance = OrderService();

  final ApiClient _apiClient;
  final FirebaseAuth _auth;

  Future<OrderModel> createOrder({
    required int restaurantId,
    required List<CartItem> items,
    required Map<String, dynamic> deliveryAddress,
    required String paymentMethod,
    required String idempotencyKey,
    String note = '',
    String? promoCode,
  }) async {
    final payload = <String, dynamic>{
      'restaurant_id': restaurantId,
      'items': items
          .map((item) => {
                'product_id': item.productId,
                'quantity': item.quantity,
                'option_value_ids': item.optionValueIds,
              })
          .toList(growable: false),
      'delivery_address': deliveryAddress,
      'payment_method': _normalizePaymentMethod(paymentMethod),
      'promo_code': promoCode,
      'notes': note.trim().isEmpty ? null : note.trim(),
      'idempotency_key': idempotencyKey,
    };

    final response = await _apiClient.postJson(
      '/api/v1/orders',
      body: payload,
      headers: await _authHeaders(),
    );

    notifyListeners();

    return OrderModel.fromJson(
      Map<String, dynamic>.from((response['data'] as Map?) ?? const {}),
    );
  }

  Future<List<OrderModel>> fetchOrders({String? scope, String? status}) async {
    final query = <String, String>{
      if (scope != null && scope.isNotEmpty) 'scope': scope,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final response = await _apiClient.getJson(
      '/api/v1/orders',
      queryParameters: query,
      headers: await _authHeaders(),
    );

    final data = (response['data'] as List?) ?? const [];

    return data
        .whereType<Map>()
        .map((item) => OrderModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<OrderModel?> fetchOrderDetail(String orderNumber) async {
    final response = await _apiClient.getJson(
      '/api/v1/orders/$orderNumber',
      headers: await _authHeaders(),
    );

    final data = response['data'];
    if (data is! Map) {
      return null;
    }

    return OrderModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<OrderModel> cancelOrder(String orderNumber) async {
    final response = await _apiClient.postJson(
      '/api/v1/orders/$orderNumber/cancel',
      headers: await _authHeaders(),
    );

    notifyListeners();

    return OrderModel.fromJson(
      Map<String, dynamic>.from((response['data'] as Map?) ?? const {}),
    );
  }

  Stream<OrderModel?> orderStream(String orderNumber) async* {
    final initial = await fetchOrderDetail(orderNumber);
    yield initial;

    if (initial == null || initial.isTerminal) {
      return;
    }

    while (true) {
      await Future<void>.delayed(const Duration(seconds: 8));
      final order = await fetchOrderDetail(orderNumber);
      yield order;

      if (order == null || order.isTerminal) {
        break;
      }
    }
  }

  Stream<List<OrderModel>> get activeOrdersStream async* {
    yield await fetchOrders(scope: 'active');
    yield* Stream.periodic(const Duration(seconds: 12)).asyncMap(
      (_) => fetchOrders(scope: 'active'),
    );
  }

  Stream<List<OrderModel>> get completedOrdersStream async* {
    yield await fetchOrders(scope: 'history');
    yield* Stream.periodic(const Duration(seconds: 15)).asyncMap(
      (_) => fetchOrders(scope: 'history'),
    );
  }

  Future<List<OrderModel>> fetchRestaurantOrders({String? status}) async {
    final response = await _apiClient.getJson(
      '/api/v1/restaurant/orders',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
      headers: await _authHeaders(),
    );

    final data = (response['data'] as List?) ?? const [];

    return data
        .whereType<Map>()
        .map((item) => OrderModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<OrderModel> transitionRestaurantOrder({
    required String orderNumber,
    required String action,
    String? reason,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/restaurant/orders/$orderNumber/$action',
      body: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      headers: await _authHeaders(),
    );

    notifyListeners();

    return OrderModel.fromJson(
      Map<String, dynamic>.from((response['data'] as Map?) ?? const {}),
    );
  }

  String generateIdempotencyKey() {
    final random = Random.secure();
    final buffer = StringBuffer(DateTime.now().microsecondsSinceEpoch);

    for (var index = 0; index < 10; index++) {
      buffer.write(random.nextInt(10));
    }

    return 'fw-$buffer';
  }

  Future<Map<String, String>> _authHeaders() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Utilisateur non connecté.',
      );
    }

    final token = await user.getIdToken(true);

    return <String, String>{
      'Authorization': 'Bearer $token',
    };
  }

  String _normalizePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'paiement à la livraison':
      case 'cash':
        return 'cash';
      case 'orange money':
        return 'orange_money';
      case 'mtn momo':
        return 'mtn_momo';
      case 'carte bancaire':
        return 'card';
      default:
        return method.toLowerCase().replaceAll(' ', '_');
    }
  }
}
