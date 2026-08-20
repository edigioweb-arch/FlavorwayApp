import 'package:flavorapps/services/laravel_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('client sync payload only contains allowed client fields', () {
    final payload = LaravelSyncService.buildClientSyncPayload(
      firstName: 'Cynthia',
      lastName: 'Kaussa',
      phone: '+242060000000',
    );

    expect(payload, {
      'role': 'customer',
      'first_name': 'Cynthia',
      'last_name': 'Kaussa',
      'phone': '+242060000000',
    });
    expect(payload.containsKey('panel_role'), isFalse);
    expect(payload.containsKey('status'), isFalse);
    expect(payload.containsKey('firebase_uid'), isFalse);
    expect(payload.containsKey('user_id'), isFalse);
    expect(payload.containsKey('email'), isFalse);
  });

  test('client sync payload keeps customer role even with empty values', () {
    final payload = LaravelSyncService.buildClientSyncPayload();

    expect(payload['role'], 'customer');
    expect(payload['first_name'], '');
    expect(payload['last_name'], '');
    expect(payload['phone'], '');
  });
}
