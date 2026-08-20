import 'package:flavorapps/models/restaurant_subscription_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RestaurantSubscriptionModel parses premium subscription', () {
    final model = RestaurantSubscriptionModel.fromJson({
      'id': 1,
      'status': 'active',
      'starts_at': '2026-08-01T00:00:00Z',
      'ends_at': '2026-09-01T00:00:00Z',
      'plan': {
        'id': 2,
        'code': 'premium',
        'name': 'Premium',
        'price': 60000,
        'currency': 'XAF',
        'billing_period': 'monthly',
      },
      'features': {
        'advanced_analytics': true,
        'priority_ranking': true,
      },
    });

    expect(model.plan?.code, 'premium');
    expect(model.isPremium, isTrue);
    expect(model.features['advanced_analytics'], isTrue);
  });

  test('RestaurantSubscriptionModel parses standard subscription', () {
    final model = RestaurantSubscriptionModel.fromJson({
      'id': 2,
      'status': 'active',
      'plan': {
        'id': 1,
        'code': 'standard',
        'name': 'Standard',
        'price': 35000,
        'currency': 'XAF',
        'billing_period': 'monthly',
      },
      'features': {
        'advanced_analytics': false,
      },
    });

    expect(model.plan?.code, 'standard');
    expect(model.isPremium, isFalse);
  });

  test('RestaurantSubscriptionModel parses expired subscription', () {
    final model = RestaurantSubscriptionModel.fromJson({
      'id': 3,
      'status': 'expired',
      'plan': {
        'id': 2,
        'code': 'premium',
        'name': 'Premium',
        'price': 60000,
        'currency': 'XAF',
        'billing_period': 'monthly',
      },
      'features': {
        'advanced_analytics': false,
      },
    });

    expect(model.status, 'expired');
    expect(model.isPremium, isFalse);
  });
}
