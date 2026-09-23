import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/reservation_model.dart';
import 'api_client.dart';
import 'notification_service.dart';

enum ReservationLoadState { idle, loading, success, error }

class ReservationService extends ChangeNotifier {
  ReservationService({
    ApiClient? apiClient,
    FirebaseAuth? auth,
  })  : _apiClient = apiClient ?? ApiClient(),
        _auth = auth ?? FirebaseAuth.instance;

  static final ReservationService instance = ReservationService();

  final ApiClient _apiClient;
  final FirebaseAuth _auth;

  List<ReservationModel> _reservations = const [];
  ReservationLoadState _state = ReservationLoadState.idle;
  String? _errorMessage;

  List<ReservationModel> get reservations => List.unmodifiable(_reservations);
  ReservationLoadState get state => _state;
  String? get errorMessage => _errorMessage;

  void _debugLog(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(message);
    }
  }

  Future<List<ReservationModel>> fetchReservations(
      {String? scope, String? status}) async {
    _state = ReservationLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.getJson(
        '/api/v1/reservations',
        queryParameters: {
          if (scope != null && scope.isNotEmpty) 'scope': scope,
          if (status != null && status.isNotEmpty) 'status': status,
        },
        headers: await _authHeaders(),
      );

      final data = (response['data'] as List?) ?? const [];
      _reservations = data
          .whereType<Map>()
          .map((item) =>
              ReservationModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
      _state = ReservationLoadState.success;
      notifyListeners();

      return reservations;
    } on ApiException catch (error) {
      _state = ReservationLoadState.error;
      _errorMessage = error.message;
      notifyListeners();
      rethrow;
    } catch (error) {
      _debugLog('Chargement réservations échoué: $error');
      _state = ReservationLoadState.error;
      _errorMessage = 'Impossible de charger les réservations.';
      notifyListeners();
      rethrow;
    }
  }

  Future<ReservationModel> createReservation({
    required int restaurantId,
    required String reservationDate,
    required String reservationTime,
    required int partySize,
    String? customerName,
    String? notes,
    String? specialRequests,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/reservations',
      body: {
        'restaurant_id': restaurantId,
        'reservation_date': reservationDate,
        'reservation_time': reservationTime,
        'party_size': partySize,
        if (customerName != null) 'customer_name': customerName.trim(),
        'notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
        'special_requests':
            (specialRequests == null || specialRequests.trim().isEmpty)
                ? null
                : specialRequests.trim(),
      },
      headers: await _authHeaders(),
    );

    final reservation = ReservationModel.fromJson(
      Map<String, dynamic>.from((response['data'] as Map?) ?? const {}),
    );

    _reservations = [reservation, ..._reservations];
    notifyListeners();
    NotificationService.instance
        .addReservationNotification(reservation.restaurantName);

    return reservation;
  }

  Future<ReservationModel?> fetchReservationDetail(
      String reservationNumber) async {
    final response = await _apiClient.getJson(
      '/api/v1/reservations/$reservationNumber',
      headers: await _authHeaders(),
    );

    final data = response['data'];
    if (data is! Map) {
      return null;
    }

    final reservation =
        ReservationModel.fromJson(Map<String, dynamic>.from(data));
    _upsert(reservation);
    notifyListeners();
    return reservation;
  }

  Future<ReservationModel> cancelReservation(
    ReservationModel reservation, {
    String? reason,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/reservations/${reservation.reservationNumber}/cancel',
      body: {
        'reason':
            (reason == null || reason.trim().isEmpty) ? null : reason.trim(),
      },
      headers: await _authHeaders(),
    );

    final updated = ReservationModel.fromJson(
      Map<String, dynamic>.from((response['data'] as Map?) ?? const {}),
    );

    _upsert(updated);
    notifyListeners();

    return updated;
  }

  void _upsert(ReservationModel reservation) {
    final index = _reservations.indexWhere(
      (item) => item.reservationNumber == reservation.reservationNumber,
    );

    if (index == -1) {
      _reservations = [reservation, ..._reservations];
      return;
    }

    final updated = [..._reservations];
    updated[index] = reservation;
    _reservations = updated;
  }

  Future<Map<String, String>> _authHeaders() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Utilisateur non connecté.',
      );
    }

    final token = await user.getIdToken(true);
    return <String, String>{
      'Authorization': 'Bearer $token',
    };
  }
}
