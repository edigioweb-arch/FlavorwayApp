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

  static const Map<String, dynamic> _joliCoinWebMedia = <String, dynamic>{
    'cover_path': 'images/restaurants/joli_coin/cover.png',
    'menu_image_path': 'images/restaurants/joli_coin/article.jpeg',
    'gallery_paths': <String>[
      'images/restaurants/joli_coin/cover.png',
      'images/restaurants/joli_coin/gallery_1.png',
      'images/restaurants/joli_coin/gallery_2.png',
      'images/restaurants/joli_coin/article.jpeg',
    ],
    'opening_hours': '10h - 23h',
    'description':
        'Une adresse conviviale à Brazzaville pour déguster grillades, fast-food, plats maison et planches à partager.',
    'client_facing_type': 'Restaurant • BBQ • Fast-food',
    'client_rating': '4.8',
    'preparation_time': '15-30 min',
    'distance_label': 'Brazzaville',
    'services': <String>[
      'Réservation',
      'Menu QR',
      'Sur place',
      'À emporter',
      'Livraison',
    ],
    'menu_categories': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'petit_dejeuner',
        'name': 'Petit déjeuner',
        'dishes': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'oeuf_jambon',
            'name': 'Oeuf au Jambon',
            'description': 'Petit déjeuner Joli Coin',
            'price_text': '2000F',
            'price': 2000,
            'image': null,
          },
          <String, dynamic>{
            'id': 'oeuf_macedoine',
            'name': 'Oeuf à la macédoine',
            'description': 'Petit déjeuner Joli Coin',
            'price_text': '2000F',
            'price': 2000,
            'image': null,
          },
        ],
      },
      <String, dynamic>{
        'id': 'fast_food',
        'name': 'Fast-food',
        'dishes': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'pain_viande_hachee',
            'name': 'Pain viande hachée',
            'description': 'Pain garni à la viande hachée',
            'price_text': '2000F',
            'price': 2000,
            'image': null,
          },
          <String, dynamic>{
            'id': 'chawarma_viande',
            'name': 'Chawarma viande',
            'description': 'Chawarma à la viande',
            'price_text': '3000F',
            'price': 3000,
            'image': null,
          },
          <String, dynamic>{
            'id': 'chawarma_poulet',
            'name': 'Chawarma poulet',
            'description': 'Chawarma au poulet',
            'price_text': '3000F',
            'price': 3000,
            'image': null,
          },
          <String, dynamic>{
            'id': 'hamburger_royale',
            'name': 'Hamburger Royale',
            'description': 'Burger maison',
            'price_text': '3000F',
            'price': 3000,
            'image': null,
          },
        ],
      },
      <String, dynamic>{
        'id': 'legumes',
        'name': 'Légumes',
        'dishes': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'saka_saka',
            'name': 'Saka-Saka',
            'description': 'Plat de légumes traditionnel',
            'price_text': '1500F',
            'price': 1500,
            'image': null,
          },
          <String, dynamic>{
            'id': 'legumes_verte',
            'name': 'Légumes verte',
            'description': 'Légumes verts',
            'price_text': '1000F',
            'price': 1000,
            'image': null,
          },
        ],
      },
      <String, dynamic>{
        'id': 'bbq',
        'name': 'BBQ',
        'dishes': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'cuisse_poulet',
            'name': 'Cuisse de poulet',
            'description': 'Cuisse de poulet grillée',
            'price_text': '1500 / 2000F',
            'price': 1500,
            'image': null,
          },
          <String, dynamic>{
            'id': 'aile_poulet',
            'name': 'Aile de poulet',
            'description': 'Aile de poulet grillée',
            'price_text': '1000F',
            'price': 1000,
            'image': null,
          },
          <String, dynamic>{
            'id': 'brochette_viande',
            'name': 'Brochette de viande',
            'description': 'Brochette grillée',
            'price_text': '1000F',
            'price': 1000,
            'image': null,
          },
          <String, dynamic>{
            'id': 'cotes_braisees',
            'name': 'Côtes braisées',
            'description': 'Côtes marinées et braisées',
            'price_text': '3000F',
            'price': 3000,
            'image': null,
          },
          <String, dynamic>{
            'id': 'poisson_braise',
            'name': 'Poisson braisé',
            'description': 'Poisson braisé selon format',
            'price_text': '4000 / 5000 / 6000F',
            'price': 4000,
            'image': null,
          },
        ],
      },
      <String, dynamic>{
        'id': 'repas',
        'name': 'Repas',
        'dishes': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'poulet_mayo',
            'name': 'Poulet Mayo',
            'description': 'La spécialité incontournable du coin',
            'price_text': '4000F',
            'price': 4000,
            'image': null,
          },
          <String, dynamic>{
            'id': 'poulet_braise',
            'name': 'Poulet braisé',
            'description': 'Poulet braisé accompagné selon disponibilité',
            'price_text': '4000F',
            'price': 4000,
            'image': null,
          },
          <String, dynamic>{
            'id': 'riz_poulet',
            'name': 'Riz au poulet',
            'description': 'Riz parfumé accompagné de poulet',
            'price_text': '3500F',
            'price': 3500,
            'image': null,
          },
        ],
      },
    ],
    'is_open': true,
    'is_recommended': true,
  };

  String get apiBaseUrl => _apiClient.baseUrl;

  Future<Map<String, dynamic>> syncCurrentClient() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const LaravelSyncException(
        'Aucun utilisateur Firebase connecté pour la synchronisation.',
      );
    }

    final profileSnapshot = await _firestore.collection('users').doc(user.uid).get();
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
        (_normalizedString(profile['deliveryMode']) ?? 'flavorway').toLowerCase();
    final restaurantDeliveryFee = _normalizedNumber(profile['restaurantDeliveryFee']);
    final mediaPayload = _restaurantMediaPayload(restaurantName);

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
        'description':
            profileDescription ??
            mediaPayload['description'] as String? ??
            (descriptionParts.isEmpty ? null : descriptionParts.join(' • ')),
        'phone': phone ?? '',
        'email': restaurantEmail ?? '',
        'cuisine_type': cuisineType ?? '',
        'address': resolvedAddress,
        'opening_hours':
            openingHours ??
            _normalizedString(mediaPayload['opening_hours']),
        'client_facing_type':
            _normalizedString(mediaPayload['client_facing_type']),
        'client_rating': _normalizedString(mediaPayload['client_rating']),
        'preparation_time':
            _normalizedString(mediaPayload['preparation_time']),
        'delivery_mode': deliveryMode == 'restaurant' ? 'restaurant' : 'flavorway',
        'restaurant_delivery_fee':
            deliveryMode == 'restaurant' ? restaurantDeliveryFee : null,
        'distance_label': _normalizedString(mediaPayload['distance_label']),
        'services': mediaPayload['services'] ?? <String>[],
        'menu_categories': mediaPayload['menu_categories'] ?? <Map<String, dynamic>>[],
        'cover_path': _normalizedString(mediaPayload['cover_path']),
        'menu_image_path': _normalizedString(mediaPayload['menu_image_path']),
        'gallery_paths': mediaPayload['gallery_paths'] ?? <String>[],
        'is_open': mediaPayload['is_open'] ?? true,
        'is_recommended': mediaPayload['is_recommended'] ?? false,
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

  static String? _extractServerMessage(Map<String, dynamic> decoded) {
    final message = decoded['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    return null;
  }

  static Map<String, dynamic> _restaurantMediaPayload(String? restaurantName) {
    if (restaurantName == null) {
      return const <String, dynamic>{};
    }

    final normalized = restaurantName.trim().toLowerCase();

    if (kDebugMode && normalized == 'joli coin') {
      return _joliCoinWebMedia;
    }

    return const <String, dynamic>{};
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
