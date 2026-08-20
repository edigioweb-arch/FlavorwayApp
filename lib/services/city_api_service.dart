import '../models/city_model.dart';
import 'api_client.dart';

class CityApiService {
  CityApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<CityModel>> fetchCities() async {
    final payload = await _client.getJson('/api/v1/cities');
    final rawData = (payload['data'] as List?) ?? const [];

    return rawData
        .whereType<Map>()
        .map((item) => CityModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}
