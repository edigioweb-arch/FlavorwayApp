class ProductOptionValueModel {
  ProductOptionValueModel({
    required this.id,
    required this.name,
    this.priceDelta,
    this.isAvailable = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final double? priceDelta;
  final bool isAvailable;
  final int sortOrder;

  factory ProductOptionValueModel.fromJson(Map<String, dynamic> json) {
    return ProductOptionValueModel(
      id: '${json['id']}',
      name: (json['name'] ?? '').toString(),
      priceDelta: (json['price_delta'] as num?)?.toDouble(),
      isAvailable: json['is_available'] != false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProductOptionModel {
  ProductOptionModel({
    required this.id,
    required this.name,
    required this.selectionType,
    this.isRequired = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.values = const [],
  });

  final String id;
  final String name;
  final String selectionType;
  final bool isRequired;
  final bool isActive;
  final int sortOrder;
  final List<ProductOptionValueModel> values;

  factory ProductOptionModel.fromJson(Map<String, dynamic> json) {
    final rawValues = (json['values'] as List?) ?? const [];

    return ProductOptionModel(
      id: '${json['id']}',
      name: (json['name'] ?? '').toString(),
      selectionType: (json['selection_type'] ?? 'single').toString(),
      isRequired: json['is_required'] == true,
      isActive: json['is_active'] != false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      values: rawValues
          .whereType<Map>()
          .map((value) =>
              ProductOptionValueModel.fromJson(Map<String, dynamic>.from(value)))
          .toList(growable: false),
    );
  }
}

class RestaurantDishModel {
  RestaurantDishModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.priceText,
    required this.price,
    required this.currencyCode,
    this.image,
    this.isAvailable = true,
    this.isFeatured = false,
    this.options = const [],
    this.categoryId,
    this.categoryName,
    this.menuId,
    this.menuName,
  });

  final String id;
  final String restaurantId;
  String name;
  String description;
  String priceText;
  double price;
  String currencyCode;
  String? image;
  bool isAvailable;
  bool isFeatured;
  List<ProductOptionModel> options;
  String? categoryId;
  String? categoryName;
  String? menuId;
  String? menuName;

  factory RestaurantDishModel.fromJson(Map<String, dynamic> json) {
    final salePrice = (json['sale_price'] as num?)?.toDouble();
    final basePrice = (json['base_price'] as num?)?.toDouble() ?? 0;
    final effectivePrice = salePrice ?? basePrice;
    final rawOptions = (json['options'] as List?) ?? const [];

    return RestaurantDishModel(
      id: '${json['id']}',
      restaurantId: '${json['restaurant_id'] ?? ''}',
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      priceText: RestaurantModel._formatPrice(
        effectivePrice,
        (json['currency_code'] ?? 'FCFA').toString(),
      ),
      price: effectivePrice,
      currencyCode: (json['currency_code'] ?? 'FCFA').toString(),
      image: json['image_url']?.toString(),
      isAvailable: json['is_available'] != false,
      isFeatured: json['is_featured'] == true,
      options: rawOptions
          .whereType<Map>()
          .map((option) =>
              ProductOptionModel.fromJson(Map<String, dynamic>.from(option)))
          .toList(growable: false),
      categoryId: json['category'] is Map
          ? '${(json['category'] as Map)['id']}'
          : json['category_id']?.toString(),
      categoryName: json['category'] is Map
          ? ((json['category'] as Map)['name'] ?? '').toString()
          : null,
      menuId: json['menu'] is Map
          ? '${(json['menu'] as Map)['id']}'
          : json['menu_id']?.toString(),
      menuName: json['menu'] is Map
          ? ((json['menu'] as Map)['name'] ?? '').toString()
          : null,
    );
  }
}

class RestaurantMenuCategoryModel {
  RestaurantMenuCategoryModel({
    required this.id,
    required this.name,
    required this.dishes,
  });

  final String id;
  String name;
  List<RestaurantDishModel> dishes;
}

class RestaurantModel {
  RestaurantModel({
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
    this.logoImage,
    this.isRecommended = false,
    this.isAvailable = true,
    this.cityId,
    this.cityName,
    this.latitude,
    this.longitude,
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
  String? logoImage;
  List<String> galleryImages;
  List<String> services;
  List<RestaurantMenuCategoryModel> menuCategories;
  bool isOpen;
  bool isRecommended;
  bool isAvailable;
  String? cityId;
  String? cityName;
  double? latitude;
  double? longitude;

  factory RestaurantModel.fromJson(
    Map<String, dynamic> json, {
    List<RestaurantMenuCategoryModel>? menuCategories,
  }) {
    final rawGallery = (json['gallery'] as List?) ??
        (json['gallery_images'] as List?) ??
        const [];
    final rawServices = (json['services'] as List?) ?? const [];

    return RestaurantModel(
      id: '${json['id']}',
      ownerId: json['owner_user_id']?.toString() ?? '',
      email: (json['email'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdBy: (json['created_by'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['cuisine_type'] ?? json['type'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      openingHours: (json['opening_hours'] ?? '').toString(),
      rating: json['rating'] == null ? '--' : '${json['rating']}',
      preparationTime: (json['preparation_time'] ?? '').toString(),
      distance: (json['distance_label'] ?? '').toString(),
      coverImage: (json['cover_url'] ?? '').toString(),
      menuImage: (json['menu_image_url'] ?? json['cover_url'] ?? '').toString(),
      logoImage: json['logo_url']?.toString(),
      galleryImages: rawGallery.map((item) => item.toString()).toList(),
      services: rawServices.map((item) => item.toString()).toList(),
      menuCategories: menuCategories ?? const [],
      isOpen: json['is_open'] == true,
      isRecommended: json['is_recommended'] == true,
      isAvailable: json['is_available'] != false,
      cityId: json['city_id']?.toString(),
      cityName: json['city']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  RestaurantModel copyWith({
    String? ownerId,
    String? email,
    String? status,
    String? createdBy,
    String? name,
    String? type,
    String? description,
    String? address,
    String? phone,
    String? openingHours,
    String? rating,
    String? preparationTime,
    String? distance,
    String? coverImage,
    String? menuImage,
    String? logoImage,
    List<String>? galleryImages,
    List<String>? services,
    List<RestaurantMenuCategoryModel>? menuCategories,
    bool? isOpen,
    bool? isRecommended,
    bool? isAvailable,
    String? cityId,
    String? cityName,
    double? latitude,
    double? longitude,
  }) {
    return RestaurantModel(
      id: id,
      ownerId: ownerId ?? this.ownerId,
      email: email ?? this.email,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      openingHours: openingHours ?? this.openingHours,
      rating: rating ?? this.rating,
      preparationTime: preparationTime ?? this.preparationTime,
      distance: distance ?? this.distance,
      coverImage: coverImage ?? this.coverImage,
      menuImage: menuImage ?? this.menuImage,
      logoImage: logoImage ?? this.logoImage,
      galleryImages: galleryImages ?? this.galleryImages,
      services: services ?? this.services,
      menuCategories: menuCategories ?? this.menuCategories,
      isOpen: isOpen ?? this.isOpen,
      isRecommended: isRecommended ?? this.isRecommended,
      isAvailable: isAvailable ?? this.isAvailable,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static String _formatPrice(double amount, String currencyCode) {
    final normalized =
        amount % 1 == 0 ? amount.toInt().toString() : amount.toStringAsFixed(2);
    return '$normalized $currencyCode';
  }
}
