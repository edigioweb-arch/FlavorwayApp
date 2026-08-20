import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/restaurant_subscription_model.dart';
import 'api_client.dart';

class RestaurantSubscriptionService extends ChangeNotifier {
  RestaurantSubscriptionService({
    ApiClient? apiClient,
    FirebaseAuth? auth,
  })  : _apiClient = apiClient ?? ApiClient(),
        _auth = auth ?? FirebaseAuth.instance;

  final ApiClient _apiClient;
  final FirebaseAuth _auth;

  RestaurantSubscriptionModel? _subscription;
  bool _isLoading = false;
  String? _errorMessage;

  RestaurantSubscriptionModel? get subscription => _subscription;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCurrentSubscription({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      _subscription = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await user.getIdToken(true);
      final response = await _apiClient.getJson(
        '/api/v1/restaurant/subscription',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = response['data'];
      _subscription = data is Map<String, dynamic>
          ? RestaurantSubscriptionModel.fromJson(data)
          : (data is Map
              ? RestaurantSubscriptionModel.fromJson(
                  Map<String, dynamic>.from(data),
                )
              : null);
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _subscription = null;
    } catch (_) {
      _errorMessage = 'Impossible de charger votre abonnement restaurant.';
      _subscription = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
