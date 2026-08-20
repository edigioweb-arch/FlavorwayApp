class DeliveryZoneAreaModel {
  const DeliveryZoneAreaModel({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory DeliveryZoneAreaModel.fromJson(Map<String, dynamic> json) {
    return DeliveryZoneAreaModel(
      id: '${json['id']}',
      name: (json['name'] ?? '').toString(),
    );
  }
}

class DeliveryZoneModel {
  const DeliveryZoneModel({
    required this.id,
    required this.code,
    required this.name,
    required this.basePrice,
    required this.requiresManualQuote,
    required this.areas,
  });

  final String id;
  final String code;
  final String name;
  final double? basePrice;
  final bool requiresManualQuote;
  final List<DeliveryZoneAreaModel> areas;

  factory DeliveryZoneModel.fromJson(Map<String, dynamic> json) {
    final rawAreas = (json['areas'] as List?) ?? const [];

    return DeliveryZoneModel(
      id: '${json['id']}',
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      basePrice: (json['base_price'] as num?)?.toDouble(),
      requiresManualQuote: json['requires_manual_quote'] == true,
      areas: rawAreas
          .whereType<Map>()
          .map((item) => DeliveryZoneAreaModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }
}
