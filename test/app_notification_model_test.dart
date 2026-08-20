import 'package:flavorapps/models/app_notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppNotificationModel parses Laravel payload', () {
    final notification = AppNotificationModel.fromJson({
      'id': 12,
      'type': 'reservation_confirmed',
      'title': 'Réservation confirmée',
      'body': 'Votre réservation est confirmée.',
      'data': {
        'reservation_number': 'RES-001',
        'route': 'reservation_detail',
      },
      'is_read': false,
      'created_at': '2026-08-17T12:00:00Z',
    });

    expect(notification.id, 12);
    expect(notification.type, 'reservation_confirmed');
    expect(notification.title, 'Réservation confirmée');
    expect(notification.body, 'Votre réservation est confirmée.');
    expect(notification.data['reservation_number'], 'RES-001');
    expect(notification.isRead, isFalse);
  });
}
