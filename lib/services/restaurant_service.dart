import 'package:flutter/foundation.dart';

import '../models/restaurant_model.dart';
import 'restaurant_api_service.dart';

typedef RestaurantDish = RestaurantDishModel;
typedef RestaurantMenuCategory = RestaurantMenuCategoryModel;
typedef RestaurantData = RestaurantModel;

class RestaurantService extends ChangeNotifier {
  RestaurantService({RestaurantApiService? apiService})
      : _apiService = apiService ?? RestaurantApiService() {
    loadRestaurants();
  }

  final RestaurantApiService _apiService;

  List<RestaurantData> _restaurants = const [];
  final Set<String> _favoriteIds = <String>{};
  String? _selectedRestaurantId;
  bool _isLoading = false;
  String? _errorMessage;

  List<RestaurantData> get restaurants => List.unmodifiable(_restaurants);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLoadedData => _restaurants.isNotEmpty;

  List<RestaurantData> get favoriteRestaurants => _restaurants
      .where((restaurant) => _favoriteIds.contains(restaurant.id))
      .toList(growable: false);

  bool isFavorite(String id) => _favoriteIds.contains(id);

  List<RestaurantData> get approvedRestaurants => _restaurants
      .where((restaurant) => restaurant.status == 'active')
      .toList(growable: false);

  List<RestaurantData> get pendingRestaurants => _restaurants
      .where((restaurant) => restaurant.status == 'pending')
      .toList(growable: false);

  List<RestaurantData> get adminRestaurants => List.unmodifiable(_restaurants);

  List<RestaurantData> get recommendedRestaurants => _restaurants
      .where((restaurant) => restaurant.isRecommended)
      .toList(growable: false);

  RestaurantData? get currentRestaurant {
    if (_selectedRestaurantId != null) {
      for (final restaurant in _restaurants) {
        if (restaurant.id == _selectedRestaurantId) {
          return restaurant;
        }
      }
    }

    return _restaurants.isEmpty ? null : _restaurants.first;
  }

  RestaurantData get joliCoin =>
      currentRestaurant ??
      RestaurantData(
        id: 'unavailable',
        ownerId: '',
        email: '',
        status: '',
        createdBy: '',
        name: 'Chargement…',
        type: '',
        description: '',
        address: '',
        phone: '',
        openingHours: '',
        rating: '--',
        preparationTime: '',
        distance: '',
        coverImage: '',
        menuImage: '',
        galleryImages: const [],
        services: const [],
        menuCategories: const [],
        isOpen: false,
      );

  Future<void> loadRestaurants({
    bool forceRefresh = false,
    String? cityId,
    String? search,
    String? cuisine,
  }) async {
    if (_isLoading && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final restaurants = await _apiService.fetchRestaurants(
        cityId: cityId,
        search: search,
        cuisine: cuisine,
      );

      _restaurants = restaurants;
      _selectedRestaurantId ??=
          restaurants.isNotEmpty ? restaurants.first.id : null;

      if (_selectedRestaurantId != null) {
        await loadRestaurantDetail(_selectedRestaurantId!, forceRefresh: true);
      }
    } catch (error) {
      _errorMessage = 'Impossible de charger les restaurants.';
      if (kDebugMode) {
        debugPrint('RestaurantService.loadRestaurants error: $error');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<RestaurantData?> loadRestaurantDetail(
    String restaurantId, {
    bool forceRefresh = false,
  }) async {
    final existing = findRestaurantById(restaurantId);

    if (!forceRefresh &&
        existing != null &&
        existing.menuCategories.isNotEmpty &&
        existing.description.isNotEmpty) {
      _selectedRestaurantId = restaurantId;
      notifyListeners();
      return existing;
    }

    try {
      final detail = await _apiService.fetchRestaurantDetail(restaurantId);
      final menuPayload = await _apiService.fetchRestaurantMenu(restaurantId);
      final merged = detail.copyWith(
        menuCategories: menuPayload.categories,
        galleryImages: detail.galleryImages.isNotEmpty
            ? detail.galleryImages
            : menuPayload.restaurant.galleryImages,
        services: detail.services.isNotEmpty
            ? detail.services
            : menuPayload.restaurant.services,
        coverImage: detail.coverImage.isNotEmpty
            ? detail.coverImage
            : menuPayload.restaurant.coverImage,
        menuImage: detail.menuImage.isNotEmpty
            ? detail.menuImage
            : menuPayload.restaurant.menuImage,
        logoImage: detail.logoImage ?? menuPayload.restaurant.logoImage,
      );

      _selectedRestaurantId = restaurantId;
      _upsertRestaurant(merged);
      notifyListeners();
      return merged;
    } catch (error) {
      _errorMessage = 'Impossible de charger ce restaurant.';
      if (kDebugMode) {
        debugPrint('RestaurantService.loadRestaurantDetail error: $error');
      }
      notifyListeners();
      return existing;
    }
  }

  void selectRestaurant(String restaurantId) {
    _selectedRestaurantId = restaurantId;
    notifyListeners();
    loadRestaurantDetail(restaurantId);
  }

  RestaurantData? findRestaurantById(String id) {
    for (final restaurant in _restaurants) {
      if (restaurant.id == id) {
        return restaurant;
      }
    }
    return null;
  }

  RestaurantData getRestaurantById(String id) {
    return findRestaurantById(id) ?? joliCoin;
  }

  List<RestaurantData> getRestaurantsByOwner(String ownerId) {
    return _restaurants
        .where((restaurant) => restaurant.ownerId == ownerId)
        .toList(growable: false);
  }

  void toggleFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
  }

  void updateRestaurantInfo({
    required String restaurantId,
    String? name,
    String? type,
    String? description,
    String? address,
    String? phone,
    String? openingHours,
    String? preparationTime,
    String? distance,
    bool? isOpen,
  }) {
    final restaurant = findRestaurantById(restaurantId);
    if (restaurant == null) return;

    _upsertRestaurant(
      restaurant.copyWith(
        name: name,
        type: type,
        description: description,
        address: address,
        phone: phone,
        openingHours: openingHours,
        preparationTime: preparationTime,
        distance: distance,
        isOpen: isOpen,
      ),
    );
    notifyListeners();
  }

  void updateCoverImage({
    required String restaurantId,
    required String imagePath,
  }) {
    final restaurant = findRestaurantById(restaurantId);
    if (restaurant == null) return;

    _upsertRestaurant(restaurant.copyWith(coverImage: imagePath));
    notifyListeners();
  }

  void updateMenuImage({
    required String restaurantId,
    required String imagePath,
  }) {
    final restaurant = findRestaurantById(restaurantId);
    if (restaurant == null) return;

    _upsertRestaurant(restaurant.copyWith(menuImage: imagePath));
    notifyListeners();
  }

  void addGalleryImage({
    required String restaurantId,
    required String imagePath,
  }) {
    final restaurant = findRestaurantById(restaurantId);
    if (restaurant == null) return;

    final gallery = List<String>.from(restaurant.galleryImages)..add(imagePath);
    _upsertRestaurant(restaurant.copyWith(galleryImages: gallery));
    notifyListeners();
  }

  void removeGalleryImage({
    required String restaurantId,
    required String imagePath,
  }) {
    final restaurant = findRestaurantById(restaurantId);
    if (restaurant == null) return;

    final gallery = List<String>.from(restaurant.galleryImages)
      ..remove(imagePath);
    _upsertRestaurant(restaurant.copyWith(galleryImages: gallery));
    notifyListeners();
  }

  void toggleService({
    required String restaurantId,
    required String service,
  }) {
    final restaurant = findRestaurantById(restaurantId);
    if (restaurant == null) return;

    final services = List<String>.from(restaurant.services);
    if (services.contains(service)) {
      services.remove(service);
    } else {
      services.add(service);
    }

    _upsertRestaurant(restaurant.copyWith(services: services));
    notifyListeners();
  }

  void addDish({
    required String restaurantId,
    required String categoryId,
    RestaurantDish? dish,
    String? name,
    String? description,
    String? priceText,
    double? price,
  }) {
    final restaurant = findRestaurantById(restaurantId);
    if (restaurant == null) return;

    final resolvedDish = dish ??
        RestaurantDish(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          restaurantId: restaurantId,
          name: name ?? 'Nouveau plat',
          description: description ?? '',
          priceText: priceText ?? '${(price ?? 0).toStringAsFixed(0)} FCFA',
          price: price ?? 0,
          currencyCode: 'XAF',
        );

    final categories = restaurant.menuCategories.map((category) {
      if (category.id != categoryId) return category;
      return RestaurantMenuCategory(
        id: category.id,
        name: category.name,
        dishes: [...category.dishes, resolvedDish],
      );
    }).toList(growable: false);

    _upsertRestaurant(restaurant.copyWith(menuCategories: categories));
    notifyListeners();
  }

  void updateDish({
    required String restaurantId,
    required String categoryId,
    RestaurantDish? dish,
    String? dishId,
    String? name,
    String? description,
    String? priceText,
    double? price,
  }) {
    final restaurant = findRestaurantById(restaurantId);
    if (restaurant == null) return;

    final resolvedDish = dish ??
        RestaurantDish(
          id: dishId ?? DateTime.now().microsecondsSinceEpoch.toString(),
          restaurantId: restaurantId,
          name: name ?? 'Plat',
          description: description ?? '',
          priceText: priceText ?? '${(price ?? 0).toStringAsFixed(0)} FCFA',
          price: price ?? 0,
          currencyCode: 'XAF',
        );

    final categories = restaurant.menuCategories.map((category) {
      if (category.id != categoryId) return category;
      return RestaurantMenuCategory(
        id: category.id,
        name: category.name,
        dishes: category.dishes.map((existingDish) {
          return existingDish.id == resolvedDish.id ? resolvedDish : existingDish;
        }).toList(growable: false),
      );
    }).toList(growable: false);

    _upsertRestaurant(restaurant.copyWith(menuCategories: categories));
    notifyListeners();
  }

  void approveRestaurant(String restaurantId) {
    final restaurant = findRestaurantById(restaurantId);
    if (restaurant == null) return;

    _upsertRestaurant(
      restaurant.copyWith(status: 'active', isAvailable: true),
    );
    notifyListeners();
  }

  void removeDish({
    required String restaurantId,
    required String categoryId,
    required String dishId,
  }) {
    final restaurant = findRestaurantById(restaurantId);
    if (restaurant == null) return;

    final categories = restaurant.menuCategories.map((category) {
      if (category.id != categoryId) return category;
      return RestaurantMenuCategory(
        id: category.id,
        name: category.name,
        dishes: category.dishes
            .where((dish) => dish.id != dishId)
            .toList(growable: false),
      );
    }).toList(growable: false);

    _upsertRestaurant(restaurant.copyWith(menuCategories: categories));
    notifyListeners();
  }

  void _upsertRestaurant(RestaurantData restaurant) {
    final index = _restaurants.indexWhere((item) => item.id == restaurant.id);
    if (index >= 0) {
      _restaurants[index] = restaurant;
    } else {
      _restaurants = [..._restaurants, restaurant];
    }
  }
}
