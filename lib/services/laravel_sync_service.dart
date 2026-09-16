import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';

class LaravelSyncException implements Exception {
  const LaravelSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LaravelSyncService {
  LaravelSyncService._();

  static final LaravelSyncService instance = LaravelSyncService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final http.Client _client = http.Client();
  final ApiClient _apiClient = ApiClient();

  String get apiBaseUrl => _apiClient.baseUrl;

  Future<Map<String, dynamic>> syncCurrentClient() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const LaravelSyncException(
        'Aucun utilisateur Firebase connecté pour la synchronisation.',
      );
    }

    final profileSnapshot =
        await _firestore.collection('users').doc(user.uid).get();
    final profile = profileSnapshot.data();

    if (!profileSnapshot.exists || profile == null) {
      throw const LaravelSyncException(
        'Profil client introuvable dans Firestore.',
      );
    }

    final normalizedRole = _normalizedString(profile['role'])?.toLowerCase();

    if (normalizedRole != 'client' && normalizedRole != 'customer') {
      throw const LaravelSyncException(
        'Ce compte connecté n’est pas un compte client.',
      );
    }

    final idToken = await user.getIdToken(true);

    if (idToken == null || idToken.isEmpty) {
      throw const LaravelSyncException(
        'Impossible de récupérer un token Firebase valide pour ce client.',
      );
    }
    final firstName = _normalizedString(profile['firstName']);
    final lastName = _normalizedString(profile['lastName']);
    final phone = _normalizedString(profile['phone']);

    return _postSync(
      idToken: idToken,
      payload: buildClientSyncPayload(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      ),
    );
  }

  Future<Map<String, dynamic>> syncCurrentRestaurantOwner() async {
    final user = _auth.currentUser;

    if (kDebugMode) {
      // ignore: avoid_print
      print('=== RESTAURANT SYNC DEBUG ===');
      // ignore: avoid_print
      print('Firebase user présent : ${user != null}');
      // ignore: avoid_print
      print('Firebase currentUser null: ${user == null}');
    }

    if (user == null) {
      throw const LaravelSyncException(
        'Aucun utilisateur Firebase connecté pour la synchronisation.',
      );
    }

    final profileSnapshot =
        await _firestore.collection('users').doc(user.uid).get();
    final profile = profileSnapshot.data();

    if (kDebugMode) {
      // ignore: avoid_print
      print('Firestore profile exists : ${profileSnapshot.exists}');
    }

    if (!profileSnapshot.exists || profile == null) {
      throw const LaravelSyncException(
        'Profil restaurateur introuvable dans Firestore.',
      );
    }

    final rawRole = _normalizedString(profile['role']);
    final normalizedRole = rawRole?.toLowerCase();
    final profileStatus = _normalizedString(profile['status'])?.toLowerCase();

    if (kDebugMode) {
      // ignore: avoid_print
      print('role Firestore: ${normalizedRole ?? 'inconnu'}');
      // ignore: avoid_print
      print('status Firestore: ${profileStatus ?? 'inconnu'}');
    }

    if (normalizedRole != 'restaurant' &&
        normalizedRole != 'restaurant_owner') {
      throw const LaravelSyncException(
        'Ce compte connecté n’est pas un compte restaurateur.',
      );
    }

    if (profileStatus == 'suspended' ||
        profileStatus == 'inactive' ||
        profileStatus == 'blocked' ||
        profileStatus == 'disabled') {
      throw const LaravelSyncException(
        'Ce compte restaurateur n’est pas autorisé à se synchroniser actuellement.',
      );
    }

    final idToken = await user.getIdToken(true);

    if (idToken == null || idToken.isEmpty) {
      throw const LaravelSyncException(
        'Impossible de récupérer un token Firebase valide pour ce restaurateur.',
      );
    }

    if (kDebugMode) {
      // ignore: avoid_print
      print('ID token récupéré: OUI');
      // ignore: avoid_print
      print('API URL: $apiBaseUrl');
      // ignore: avoid_print
      print('appel /api/v1/auth/sync démarré');
    }

    final firstName = _normalizedString(profile['firstName']);
    final lastName = _normalizedString(profile['lastName']);
    final phone = _normalizedString(profile['phone']);
    final restaurantName = _normalizedString(profile['restaurantName']);
    final cuisineType = _normalizedString(profile['cuisineType']);
    final address = _normalizedString(profile['address']);
    final city = _normalizedString(profile['city']);
    final country = _normalizedString(profile['country']);
    final profileDescription = _normalizedString(profile['description']);
    final openingHours = _normalizedString(profile['openingHours']);
    final restaurantEmail = _normalizedString(profile['email']) ?? user.email;
    final deliveryMode =
        (_normalizedString(profile['deliveryMode']) ?? 'flavorway')
            .toLowerCase();
    final restaurantDeliveryFee =
        _normalizedNumber(profile['restaurantDeliveryFee']);
    final requestedCourierCount = _normalizedInt(
      profile['requestedCourierCount'],
    );

    if (restaurantName == null || restaurantName.isEmpty) {
      throw const LaravelSyncException(
        'Le nom du restaurant est manquant dans le profil Firestore.',
      );
    }

    final descriptionParts = <String>[
      if (cuisineType != null && cuisineType.isNotEmpty) cuisineType,
      if (city != null && city.isNotEmpty) city,
      if (country != null && country.isNotEmpty) country,
      if (address != null && address.isNotEmpty) address,
    ];

    final resolvedAddress = [
      if (address != null && address.isNotEmpty) address,
      if (city != null && city.isNotEmpty) city,
      if (country != null && country.isNotEmpty) country,
    ].join(', ');

    final payload = <String, dynamic>{
      'role': 'restaurant',
      'first_name': firstName ?? '',
      'last_name': lastName ?? '',
      'phone': phone ?? '',
      'restaurant': <String, dynamic>{
        'name': restaurantName,
        'description': profileDescription ??
            (descriptionParts.isEmpty ? null : descriptionParts.join(' • ')),
        'phone': phone ?? '',
        'email': restaurantEmail ?? '',
        'cuisine_type': cuisineType ?? '',
        'address': resolvedAddress,
        'opening_hours': openingHours,
        'delivery_mode':
            deliveryMode == 'restaurant' ? 'restaurant' : 'flavorway',
        'restaurant_delivery_fee':
            deliveryMode == 'restaurant' ? restaurantDeliveryFee : null,
        'requested_courier_count':
            deliveryMode == 'restaurant' ? requestedCourierCount : null,
      },
    };

    return _postSync(idToken: idToken, payload: payload);
  }

  Future<Map<String, dynamic>> _postSync({
    required String idToken,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/v1/auth/sync'),
      headers: <String, String>{
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (kDebugMode) {
      // ignore: avoid_print
      print('HTTP status: ${response.statusCode}');
    }

    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    final success = response.statusCode == 200 || response.statusCode == 201;

    if (kDebugMode) {
      // ignore: avoid_print
      print('Sync success : $success');
      // ignore: avoid_print
      print('sync success: $success');
    }

    if (success) {
      return decoded;
    }

    switch (response.statusCode) {
      case 401:
        throw const LaravelSyncException(
          'Session Firebase invalide ou expirée. Reconnectez-vous.',
        );
      case 403:
        throw LaravelSyncException(
          _extractServerMessage(decoded) ??
              'Ce compte n’est pas autorisé à se synchroniser avec Laravel.',
        );
      case 422:
        throw LaravelSyncException(
          _extractServerMessage(decoded) ??
              'Les données envoyées à Laravel sont invalides.',
        );
      case 503:
        throw const LaravelSyncException(
          'Le service de synchronisation Laravel est indisponible pour le moment.',
        );
      default:
        throw LaravelSyncException(
          _extractServerMessage(decoded) ??
              'La synchronisation avec Laravel a échoué.',
        );
    }
  }

  static String? _normalizedString(dynamic value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static num? _normalizedNumber(dynamic value) {
    if (value is num) {
      return value;
    }

    if (value is String) {
      return num.tryParse(value.trim().replaceAll(',', '.'));
    }

    return null;
  }

  static int? _normalizedInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value.trim());
    }

    return null;
  }

  static String? _extractServerMessage(Map<String, dynamic> decoded) {
    final message = decoded['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    return null;
  }

  @visibleForTesting
  static Map<String, dynamic> buildClientSyncPayload({
    String? firstName,
    String? lastName,
    String? phone,
  }) {
    return <String, dynamic>{
      'role': 'customer',
      'first_name': firstName ?? '',
      'last_name': lastName ?? '',
      'phone': phone ?? '',
    };
  }
}
