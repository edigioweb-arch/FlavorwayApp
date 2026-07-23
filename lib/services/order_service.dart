import 'package:flutter/foundation.dart';

import 'notification_service.dart';

class OrderModel {
  final String restaurantName;
  final String orderNumber;
  final String date;
  final double total;
  final String status;

  OrderModel({
    required this.restaurantName,
    required this.orderNumber,
    required this.date,
    required this.total,
    required this.status,
  });
}

class OrderService extends ChangeNotifier {
  static final OrderService instance = OrderService._();

  OrderService._();

  final List<OrderModel> _orders = [];

  List<OrderModel> get orders => List.unmodifiable(_orders);

  List<OrderModel> get activeOrders =>
      _orders.where((order) => order.status != 'Livrée').toList();

  List<OrderModel> get completedOrders =>
      _orders.where((order) => order.status == 'Livrée').toList();

  void addOrder({
    required String restaurantName,
    required String orderNumber,
    required String date,
    required double total,
    String status = 'En préparation',
  }) {
    _orders.insert(
      0,
      OrderModel(
        restaurantName: restaurantName,
        orderNumber: orderNumber,
        date: date,
        total: total,
        status: status,
      ),
    );

    notifyListeners();

    NotificationService.instance.addOrderNotification(orderNumber);
  }

  void markAsDelivered(OrderModel order) {
    final index = _orders.indexOf(order);

    if (index == -1) return;

    _orders[index] = OrderModel(
      restaurantName: order.restaurantName,
      orderNumber: order.orderNumber,
      date: order.date,
      total: order.total,
      status: 'Livrée',
    );

    notifyListeners();
  }

  void removeOrder(OrderModel order) {
    _orders.remove(order);
    notifyListeners();
  }

  void clear() {
    _orders.clear();
    notifyListeners();
  }
}
