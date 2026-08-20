import '../models/delivery_zone_model.dart';
import 'api_client.dart';

class DeliveryZoneApiService {
  DeliveryZoneApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<DeliveryZoneModel>> fetchZonesForCity(String cityId) async {
    final payload = await _client.getJson('/api/v1/cities/$cityId/delivery-zones');
    final rawData = (payload['data'] as List?) ?? const [];

    return rawData
        .whereType<Map>()
        .map((item) => DeliveryZoneModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}
