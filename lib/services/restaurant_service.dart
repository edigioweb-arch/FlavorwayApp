import 'package:flutter/foundation.dart';

class RestaurantDish {
  RestaurantDish({
    required this.id,
    required this.name,
    required this.description,
    required this.priceText,
    required this.price,
    this.image,
  });

  final String id;
  String name;
  String description;
  String priceText;
  double price;
  String? image;
}

class RestaurantMenuCategory {
  RestaurantMenuCategory({
    required this.id,
    required this.name,
    required this.dishes,
  });

  final String id;
  String name;
  List<RestaurantDish> dishes;
}

class RestaurantData {
  RestaurantData({
    required this.id,
    required this.ownerId,
    required this.email,
    required this.status,
    required this.createdBy,
    required this.name,
    required this.type,
    required this.description,
    required this.address,
    required this.phone,
    required this.openingHours,
    required this.rating,
    required this.preparationTime,
    required this.distance,
    required this.coverImage,
    required this.menuImage,
    required this.galleryImages,
    required this.services,
    required this.menuCategories,
    required this.isOpen,
    required this.isRecommended,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String ownerId;
  String email;
  String status;
  String createdBy;
  DateTime createdAt;
  DateTime updatedAt;
  String name;
  String type;
  String description;
  String address;
  String phone;
  String openingHours;
  String rating;
  String preparationTime;
  String distance;
  String coverImage;
  String menuImage;
  List<String> galleryImages;
  List<String> services;
  List<RestaurantMenuCategory> menuCategories;
  bool isOpen;
  bool isRecommended;
}

class RestaurantService extends ChangeNotifier {
  RestaurantService() {
    _restaurants = [_buildJoliCoin()];
  }

  late List<RestaurantData> _restaurants;
  final Set<String> _favoriteIds = {};

  List<RestaurantData> get restaurants => List.unmodifiable(_restaurants);

  List<RestaurantData> get favoriteRestaurants => _restaurants
      .where((r) => _favoriteIds.contains(r.id))
      .toList(growable: false);

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void toggleFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
  }

  List<RestaurantData> get approvedRestaurants => _restaurants
      .where(
          (restaurant) => restaurant.status == 'approved' && restaurant.isOpen)
      .toList(growable: false);

  List<RestaurantData> get pendingRestaurants => _restaurants
      .where((restaurant) => restaurant.status == 'pending')
      .toList(growable: false);

  List<RestaurantData> get adminRestaurants => List.unmodifiable(_restaurants);

  List<RestaurantData> get recommendedRestaurants =>
      _restaurants.where((restaurant) {
        final rating = double.tryParse(restaurant.rating) ?? 0;
        return restaurant.status == 'approved' &&
            (restaurant.isRecommended || rating >= 5.0);
      }).toList(growable: false);

  List<RestaurantData> getRestaurantsByOwner(String ownerId) {
    return _restaurants
        .where((restaurant) => restaurant.ownerId == ownerId)
        .toList(growable: false);
  }

  RestaurantData get joliCoin => _restaurants.firstWhere(
        (restaurant) => restaurant.id == 'joli_coin',
        orElse: () => _restaurants.first,
      );

  RestaurantData getRestaurantById(String id) {
    return _restaurants.firstWhere(
      (restaurant) => restaurant.id == id,
      orElse: () => _restaurants.first,
    );
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
    final restaurant = getRestaurantById(restaurantId);

    if (name != null) restaurant.name = name;
    if (type != null) restaurant.type = type;
    if (description != null) restaurant.description = description;
    if (address != null) restaurant.address = address;
    if (phone != null) restaurant.phone = phone;
    if (openingHours != null) restaurant.openingHours = openingHours;
    if (preparationTime != null) restaurant.preparationTime = preparationTime;
    if (distance != null) restaurant.distance = distance;
    if (isOpen != null) restaurant.isOpen = isOpen;
    restaurant.updatedAt = DateTime.now();
    notifyListeners();
  }

  void updateCoverImage({
    required String restaurantId,
    required String imagePath,
  }) {
    final restaurant = getRestaurantById(restaurantId);
    restaurant.coverImage = imagePath;
    restaurant.updatedAt = DateTime.now();
    notifyListeners();
  }

  void updateMenuImage({
    required String restaurantId,
    required String imagePath,
  }) {
    final restaurant = getRestaurantById(restaurantId);
    restaurant.menuImage = imagePath;
    restaurant.updatedAt = DateTime.now();
    notifyListeners();
  }

  void addGalleryImage({
    required String restaurantId,
    required String imagePath,
  }) {
    final restaurant = getRestaurantById(restaurantId);
    restaurant.galleryImages.add(imagePath);
    restaurant.updatedAt = DateTime.now();
    notifyListeners();
  }

  void removeGalleryImage({
    required String restaurantId,
    required String imagePath,
  }) {
    final restaurant = getRestaurantById(restaurantId);
    restaurant.galleryImages.remove(imagePath);
    restaurant.updatedAt = DateTime.now();
    notifyListeners();
  }

  void toggleService({
    required String restaurantId,
    required String service,
  }) {
    final restaurant = getRestaurantById(restaurantId);

    if (restaurant.services.contains(service)) {
      restaurant.services.remove(service);
    } else {
      restaurant.services.add(service);
    }
    restaurant.updatedAt = DateTime.now();
    notifyListeners();
  }

  void addMenuCategory({
    required String restaurantId,
    required String categoryName,
  }) {
    final restaurant = getRestaurantById(restaurantId);
    final id =
        categoryName.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');

    restaurant.menuCategories.add(
      RestaurantMenuCategory(
        id: '${id}_${DateTime.now().millisecondsSinceEpoch}',
        name: categoryName,
        dishes: [],
      ),
    );
    restaurant.updatedAt = DateTime.now();
    notifyListeners();
  }

  void addDish({
    required String restaurantId,
    required String categoryId,
    required String name,
    required String description,
    required String priceText,
    required double price,
    String? image,
  }) {
    final restaurant = getRestaurantById(restaurantId);
    final category = restaurant.menuCategories.firstWhere(
      (item) => item.id == categoryId,
      orElse: () => restaurant.menuCategories.first,
    );

    category.dishes.add(
      RestaurantDish(
        id: '${categoryId}_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        priceText: priceText,
        price: price,
        image: image,
      ),
    );
    restaurant.updatedAt = DateTime.now();
    notifyListeners();
  }

  void updateDish({
    required String restaurantId,
    required String categoryId,
    required String dishId,
    String? name,
    String? description,
    String? priceText,
    double? price,
    String? image,
  }) {
    final restaurant = getRestaurantById(restaurantId);
    final category = restaurant.menuCategories.firstWhere(
      (item) => item.id == categoryId,
      orElse: () => restaurant.menuCategories.first,
    );
    final dish = category.dishes.firstWhere(
      (item) => item.id == dishId,
      orElse: () => category.dishes.first,
    );

    if (name != null) dish.name = name;
    if (description != null) dish.description = description;
    if (priceText != null) dish.priceText = priceText;
    if (price != null) dish.price = price;
    if (image != null) dish.image = image;
    restaurant.updatedAt = DateTime.now();
    notifyListeners();
  }

  void removeDish({
    required String restaurantId,
    required String categoryId,
    required String dishId,
  }) {
    final restaurant = getRestaurantById(restaurantId);
    final category = restaurant.menuCategories.firstWhere(
      (item) => item.id == categoryId,
      orElse: () => restaurant.menuCategories.first,
    );

    category.dishes.removeWhere((dish) => dish.id == dishId);
    restaurant.updatedAt = DateTime.now();
    notifyListeners();
  }

  void approveRestaurant(String restaurantId) {
    final restaurant = getRestaurantById(restaurantId);
    restaurant.status = 'approved';
    restaurant.updatedAt = DateTime.now();
    notifyListeners();
  }

  void rejectRestaurant(String restaurantId) {
    final restaurant = getRestaurantById(restaurantId);
    restaurant.status = 'rejected';
    restaurant.updatedAt = DateTime.now();
    notifyListeners();
  }

  void suspendRestaurant(String restaurantId) {
    final restaurant = getRestaurantById(restaurantId);
    restaurant.status = 'suspended';
    restaurant.updatedAt = DateTime.now();
    notifyListeners();
  }

  void toggleRecommendedRestaurant(String restaurantId) {
    final restaurant = getRestaurantById(restaurantId);
    restaurant.isRecommended = !restaurant.isRecommended;
    restaurant.updatedAt = DateTime.now();
    notifyListeners();
  }

  void addRestaurant({
    required String ownerId,
    required String email,
    required String name,
    required String type,
    required String description,
    required String address,
    required String phone,
    required String openingHours,
    required String createdBy,
  }) {
    final normalizedName = name
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll("'", '');

    _restaurants.add(
      RestaurantData(
        id: '${normalizedName}_${DateTime.now().millisecondsSinceEpoch}',
        ownerId: ownerId,
        email: email,
        status: createdBy == 'admin' ? 'approved' : 'pending',
        createdBy: createdBy,
        name: name,
        type: type,
        description: description,
        address: address,
        phone: phone,
        openingHours: openingHours,
        rating: 'Nouveau',
        preparationTime: '20-35 min',
        distance: address,
        coverImage: 'assets/images/offer.png',
        menuImage: 'assets/images/offer.png',
        galleryImages: [],
        services: [
          'Sur place',
          'À emporter',
        ],
        menuCategories: [],
        isOpen: true,
        isRecommended: false,
      ),
    );

    notifyListeners();
  }

  RestaurantData _buildJoliCoin() {
    return RestaurantData(
      id: 'joli_coin',
      ownerId: 'owner_joli_coin',
      email: 'admin@jolicoin.com',
      status: 'approved',
      createdBy: 'admin',
      name: 'Joli Coin',
      type: 'Restaurant • BBQ • Fast-food',
      description:
          'Une adresse conviviale à Brazzaville pour déguster grillades, fast-food, plats maison et planches à partager.',
      address: 'Brazzaville, Congo',
      phone: '+242 00 000 00 00',
      openingHours: '10h - 23h',
      rating: '4.8',
      preparationTime: '15-30 min',
      distance: 'Brazzaville',
      coverImage: 'assets/images/restaurants/joli_coin/cover.png',
      menuImage: 'assets/images/restaurants/joli_coin/article.jpeg',
      galleryImages: [
        'assets/images/restaurants/joli_coin/cover.png',
        'assets/images/restaurants/joli_coin/gallery_1.png',
        'assets/images/restaurants/joli_coin/gallery_2.png',
        'assets/images/restaurants/joli_coin/article.jpeg',
      ],
      services: [
        'Réservation',
        'Menu QR',
        'Sur place',
        'À emporter',
        'Livraison',
      ],
      isOpen: true,
      isRecommended: true,
      menuCategories: [
        RestaurantMenuCategory(
          id: 'petit_dejeuner',
          name: 'Petit déjeuner',
          dishes: [
            RestaurantDish(
              id: 'oeuf_jambon',
              name: 'Oeuf au Jambon',
              description: 'Petit déjeuner Joli Coin',
              priceText: '2000F',
              price: 2000,
            ),
            RestaurantDish(
              id: 'oeuf_macedoine',
              name: 'Oeuf à la macédoine',
              description: 'Petit déjeuner Joli Coin',
              priceText: '2000F',
              price: 2000,
            ),
          ],
        ),
        RestaurantMenuCategory(
          id: 'fast_food',
          name: 'Fast-food',
          dishes: [
            RestaurantDish(
              id: 'pain_viande_hachee',
              name: 'Pain viande hachée',
              description: 'Pain garni à la viande hachée',
              priceText: '2000F',
              price: 2000,
            ),
            RestaurantDish(
              id: 'chawarma_viande',
              name: 'Chawarma viande',
              description: 'Chawarma à la viande',
              priceText: '3000F',
              price: 3000,
            ),
            RestaurantDish(
              id: 'chawarma_poulet',
              name: 'Chawarma poulet',
              description: 'Chawarma au poulet',
              priceText: '3000F',
              price: 3000,
            ),
            RestaurantDish(
              id: 'hamburger_royale',
              name: 'Hamburger Royale',
              description: 'Burger maison',
              priceText: '3000F',
              price: 3000,
            ),
          ],
        ),
        RestaurantMenuCategory(
          id: 'legumes',
          name: 'Légumes',
          dishes: [
            RestaurantDish(
              id: 'saka_saka',
              name: 'Saka-Saka',
              description: 'Plat de légumes traditionnel',
              priceText: '1500F',
              price: 1500,
            ),
            RestaurantDish(
              id: 'legumes_verte',
              name: 'Légumes verte',
              description: 'Légumes verts',
              priceText: '1000F',
              price: 1000,
            ),
          ],
        ),
        RestaurantMenuCategory(
          id: 'bbq',
          name: 'BBQ',
          dishes: [
            RestaurantDish(
              id: 'cuisse_poulet',
              name: 'Cuisse de poulet',
              description: 'Cuisse de poulet grillée',
              priceText: '1500 / 2000F',
              price: 1500,
            ),
            RestaurantDish(
              id: 'aile_poulet',
              name: 'Aile de poulet',
              description: 'Aile de poulet grillée',
              priceText: '1000F',
              price: 1000,
            ),
            RestaurantDish(
              id: 'brochette_viande',
              name: 'Brochette de viande',
              description: 'Brochette grillée',
              priceText: '1000F',
              price: 1000,
            ),
            RestaurantDish(
              id: 'cotes_braisees',
              name: 'Côtes braisées',
              description: 'Côtes marinées et braisées',
              priceText: '3000F',
              price: 3000,
            ),
            RestaurantDish(
              id: 'poisson_braise',
              name: 'Poisson braisé',
              description: 'Poisson braisé selon format',
              priceText: '4000 / 5000 / 6000F',
              price: 4000,
            ),
          ],
        ),
        RestaurantMenuCategory(
          id: 'repas',
          name: 'Repas',
          dishes: [
            RestaurantDish(
              id: 'poulet_mayo',
              name: 'Poulet Mayo',
              description: 'La spécialité incontournable du coin',
              priceText: '4000F',
              price: 4000,
            ),
            RestaurantDish(
              id: 'poulet_braise',
              name: 'Poulet braisé',
              description: 'Poulet braisé accompagné selon disponibilité',
              priceText: '4000F',
              price: 4000,
            ),
            RestaurantDish(
              id: 'riz_poulet',
              name: 'Riz au poulet',
              description: 'Riz parfumé accompagné de poulet',
              priceText: '3500F',
              price: 3500,
            ),
          ],
        ),
      ],
    );
  }
}
