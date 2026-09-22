import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationNavigationService {
  NotificationNavigationService();

  static final NotificationNavigationService instance =
      NotificationNavigationService();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  Map<String, dynamic>? _pendingPayload;

  void showForegroundBanner(String title, String body,
      {Map<String, dynamic>? payload}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('$title\n$body', style: GoogleFonts.poppins()),
        action: payload == null
            ? null
            : SnackBarAction(
                label: 'Ouvrir', onPressed: () => handlePayload(payload)),
        duration: const Duration(seconds: 6),
      ));
  }

  // getInitialMessage can arrive before runApp. Keep it until the navigator
  // exists; no order is created or inferred from the notification.
  void flushPendingPayload() {
    final pending = _pendingPayload;
    if (pending == null || navigatorKey.currentState == null) return;
    _pendingPayload = null;
    handlePayload(pending);
  }

  void handlePayload(Map<String, dynamic> payload) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingPayload = Map<String, dynamic>.from(payload);
      WidgetsBinding.instance
          .addPostFrameCallback((_) => flushPendingPayload());
      return;
    }
    final type = (payload['type'] ?? '').toString();
    final route = payload['route'];
    final destination = payload['destination'];
    if (destination == 'courier') {
      final number = payload['order_number'];
      if (number is String && RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(number)) {
        navigator
            .pushNamed('/courier/order', arguments: {'order_number': number});
      } else {
        navigator.pushNamed('/courier/login');
      }
      return;
    }
    if (destination != null && destination != 'client') {
      navigator.pushNamed('/notifications');
      return;
    }
    if (route == 'order_detail' ||
        type.startsWith('order_') ||
        payload['entity_type'] == 'order') {
      final number = payload['order_number'];
      // The Laravel route binds order_number, never an invented/local ID.
      if (number is! String ||
          number.trim().isEmpty ||
          !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(number)) {
        navigator.pushNamed('/notifications');
        return;
      }
      navigator.pushNamed('/order-tracking', arguments: {
        'order_reference': number,
        'order_id': (payload['order_id'] ?? '').toString(),
        'order_number': number,
      });
      return;
    }
    if (route == 'reservation_detail' || type.startsWith('reservation_')) {
      navigator.pushNamed('/reservations');
      return;
    }
    if (type == 'message') {
      navigator.pushNamed('/messages');
      return;
    }
    navigator.pushNamed('/notifications');
  }
}
