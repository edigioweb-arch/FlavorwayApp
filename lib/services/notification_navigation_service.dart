import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationNavigationService {
  NotificationNavigationService._();

  static final NotificationNavigationService instance =
      NotificationNavigationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void showForegroundBanner(String title, String body) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$title\n$body',
            style: GoogleFonts.poppins(),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  void handlePayload(Map<String, dynamic> payload) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final type = (payload['type'] ?? '').toString();
    final route = (payload['route'] ?? '').toString();
    final entityType = (payload['entity_type'] ?? '').toString();
    final entityId = (payload['entity_id'] ?? '').toString();
    final orderId = (payload['order_id'] ?? '').toString();
    final orderNumber = (payload['order_number'] ?? '').toString();

    if (route == 'order_detail' || type.startsWith('order_') || entityType == 'order') {
      final orderReference = orderNumber.isNotEmpty ? orderNumber : orderId;
      navigator.pushNamed(
        '/order-tracking',
        arguments: {
          'order_reference': orderReference,
          'order_id': entityId.isNotEmpty ? entityId : orderId,
          'order_number': orderNumber,
        },
      );
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
