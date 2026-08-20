import 'package:flavorapps/models/reservation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReservationModel parses Laravel payload correctly', () {
    final model = ReservationModel.fromJson({
      'id': 1,
      'reservation_number': 'RES-20260817-000123',
      'status': 'confirmed',
      'reservation_date': '2026-08-20',
      'reservation_time': '20:00',
      'notes': 'Anniversaire',
      'special_requests': null,
      'created_at': '2026-08-17T12:00:00Z',
      'customer': {
        'name': 'Client Test',
        'phone': '+242060000000',
        'email': 'client@test.local',
      },
      'restaurant': {
        'id': 3,
        'name': 'Joli Coin',
        'address': 'Brazzaville',
        'phone': '+242060000001',
      },
      'party_size': 4,
      'status_history': [
        {
          'to_status': 'confirmed',
          'source': 'restaurant',
          'changed_at': '2026-08-17T12:05:00Z',
        }
      ],
    });

    expect(model.reservationNumber, 'RES-20260817-000123');
    expect(model.restaurantName, 'Joli Coin');
    expect(model.partySize, 4);
    expect(model.displayStatus, 'Confirmée');
    expect(model.timeline.length, 1);
  });
}
