import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/city_model.dart';
import 'city_api_service.dart';

class CityService extends ChangeNotifier {
  CityService({CityApiService? apiService})
      : _apiService = apiService ?? CityApiService() {
    initialize();
  }

  static const _selectedCityKey = 'selected_city_id';

  final CityApiService _apiService;

  List<CityModel> _cities = const [];
  CityModel? _selectedCity;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  List<CityModel> get cities => List.unmodifiable(_cities);
  CityModel? get selectedCity => _selectedCity;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get hasCities => _cities.isNotEmpty;

  Future<void> initialize() async {
    if (_isInitialized || _isLoading) {
      return;
    }

    await fetchCities();
  }

  Future<void> fetchCities({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final persistedId = prefs.getString(_selectedCityKey);
      final cities = await _apiService.fetchCities();

      _cities = cities;
      _selectedCity = cities.cast<CityModel?>().firstWhere(
            (city) => city?.id == persistedId,
            orElse: () => null,
          );

      _selectedCity ??= cities.isNotEmpty ? cities.first : null;

      if (_selectedCity == null) {
        await prefs.remove(_selectedCityKey);
      } else {
        await prefs.setString(_selectedCityKey, _selectedCity!.id);
      }

      _isInitialized = true;
    } catch (error) {
      _errorMessage = 'Impossible de charger les villes disponibles.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectCity(CityModel city) async {
    _selectedCity = city;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedCityKey, city.id);
    notifyListeners();
  }

  Future<void> clearSelection() async {
    _selectedCity = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedCityKey);
    notifyListeners();
  }
}
