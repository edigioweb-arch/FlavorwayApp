class RestaurantSubscriptionPlanModel {
  const RestaurantSubscriptionPlanModel({
    required this.id,
    required this.code,
    required this.name,
    required this.price,
    required this.currency,
    required this.billingPeriod,
  });

  final int id;
  final String code;
  final String name;
  final double price;
  final String currency;
  final String billingPeriod;

  factory RestaurantSubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return RestaurantSubscriptionPlanModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? json['currency_code'] ?? 'XAF').toString(),
      billingPeriod: (json['billing_period'] ?? 'monthly').toString(),
    );
  }
}

class RestaurantSubscriptionModel {
  const RestaurantSubscriptionModel({
    required this.id,
    required this.status,
    required this.plan,
    required this.features,
    this.startsAt,
    this.endsAt,
    this.renewsAt,
    this.autoRenew = false,
  });

  final int id;
  final String status;
  final RestaurantSubscriptionPlanModel? plan;
  final Map<String, bool> features;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? renewsAt;
  final bool autoRenew;

  bool get isPremium => plan?.code == 'premium' && status == 'active';

  factory RestaurantSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final rawFeatures = Map<String, dynamic>.from(
      (json['features'] as Map?) ?? const {},
    );

    return RestaurantSubscriptionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '').toString(),
      plan: json['plan'] is Map
          ? RestaurantSubscriptionPlanModel.fromJson(
              Map<String, dynamic>.from(json['plan'] as Map),
            )
          : null,
      features: rawFeatures.map(
        (key, value) => MapEntry(key, value == true),
      ),
      startsAt: DateTime.tryParse((json['starts_at'] ?? '').toString()),
      endsAt: DateTime.tryParse((json['ends_at'] ?? '').toString()),
      renewsAt: DateTime.tryParse((json['renews_at'] ?? '').toString()),
      autoRenew: json['auto_renew'] == true,
    );
  }
}
