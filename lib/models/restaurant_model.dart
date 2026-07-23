class RestaurantDishModel {
  RestaurantDishModel({
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
  });

  final String id;

  String ownerId;
  String email;
  String status;
  String createdBy;

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

  List<RestaurantMenuCategoryModel> menuCategories;

  DateTime? createdAt;
  DateTime? updatedAt;

  bool isOpen;
}
