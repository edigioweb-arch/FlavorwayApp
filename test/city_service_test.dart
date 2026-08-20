import 'package:flavorapps/models/city_model.dart';
import 'package:flavorapps/services/city_api_service.dart';
import 'package:flavorapps/services/city_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCityApiService extends CityApiService {
  _FakeCityApiService({required this.cities, this.error});

  final List<CityModel> cities;
  final Object? error;

  @override
  Future<List<CityModel>> fetchCities() async {
    if (error != null) {
      throw error!;
    }

    return cities;
  }
}

void main() {
  const brazzaville = CityModel(
    id: '1',
    name: 'Brazzaville',
    countryId: '1',
    countryName: 'Congo',
    countryIsoCode: 'CG',
    isActive: true,
    isVisibleInApp: true,
    launchStatus: 'launched',
  );

  const kinshasa = CityModel(
    id: '2',
    name: 'Kinshasa',
    countryId: '2',
    countryName: 'RDC',
    countryIsoCode: 'CD',
    isActive: false,
    isVisibleInApp: true,
    launchStatus: 'not_launched',
  );

  test('CityService fetches cities and selects first city by default', () async {
    SharedPreferences.setMockInitialValues({});
    final service = CityService(
      apiService: _FakeCityApiService(cities: const [brazzaville, kinshasa]),
    );

    await Future<void>.delayed(Duration.zero);
    await service.fetchCities(forceRefresh: true);

    expect(service.cities.length, 2);
    expect(service.selectedCity?.id, '1');
  });

  test('CityService keeps persisted selected city when still available', () async {
    SharedPreferences.setMockInitialValues({'selected_city_id': '2'});
    final service = CityService(
      apiService: _FakeCityApiService(cities: const [brazzaville, kinshasa]),
    );

    await Future<void>.delayed(Duration.zero);
    await service.fetchCities(forceRefresh: true);

    expect(service.selectedCity?.id, '2');
  });

  test('CityService falls back when persisted city becomes unavailable', () async {
    SharedPreferences.setMockInitialValues({'selected_city_id': '9'});
    final service = CityService(
      apiService: _FakeCityApiService(cities: const [brazzaville]),
    );

    await Future<void>.delayed(Duration.zero);
    await service.fetchCities(forceRefresh: true);

    expect(service.selectedCity?.id, '1');
  });

  test('CityService exposes API error state', () async {
    SharedPreferences.setMockInitialValues({});
    final service = CityService(
      apiService: _FakeCityApiService(
        cities: const [],
        error: Exception('API down'),
      ),
    );

    await Future<void>.delayed(Duration.zero);
    await service.fetchCities(forceRefresh: true);

    expect(service.errorMessage, isNotNull);
    expect(service.cities, isEmpty);
  });
}
