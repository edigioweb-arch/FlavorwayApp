import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });
}

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._();

  NotificationService._();

  final List<AppNotification> _notifications = [];

  void addOrderNotification(String orderNumber) {
    addNotification(
      title: 'Commande',
      message: 'Votre commande n°$orderNumber a été enregistrée.',
    );
  }

  void addReservationNotification(String restaurant) {
    addNotification(
      title: 'Réservation',
      message: 'Votre réservation chez $restaurant est confirmée.',
    );
  }

  void addSupportNotification(String message) {
    addNotification(
      title: 'Support FlavorWay',
      message: message,
    );
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  void markAllAsRead() {
    for (final notification in _notifications) {
      notification.isRead = true;
    }
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((item) => item.id == id);

    if (index == -1) return;

    _notifications[index].isRead = true;
    notifyListeners();
  }

  void addNotification({
    required String title,
    required String message,
  }) {
    _notifications.insert(
      0,
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  void clear() {
    _notifications.clear();
    notifyListeners();
  }
}
