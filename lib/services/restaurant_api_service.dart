import '../models/restaurant_model.dart';
import 'api_client.dart';

class RestaurantApiService {
  RestaurantApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<RestaurantModel>> fetchRestaurants({
    String? cityId,
    String? search,
    String? cuisine,
  }) async {
    final payload = await _client.getJson(
      '/api/v1/restaurants',
      queryParameters: {
        if (cityId != null && cityId.isNotEmpty) 'city_id': cityId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (cuisine != null && cuisine.isNotEmpty) 'cuisine': cuisine,
      },
    );

    final rawData = (payload['data'] as List?) ?? const [];

    return rawData
        .whereType<Map>()
        .map(
          (item) => RestaurantModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Future<RestaurantModel> fetchRestaurantDetail(String restaurantId) async {
    final payload = await _client.getJson('/api/v1/restaurants/$restaurantId');
    final data = Map<String, dynamic>.from(payload['data'] as Map);

    return RestaurantModel.fromJson(data);
  }

  Future<RestaurantMenuPayload> fetchRestaurantMenu(String restaurantId) async {
    final payload =
        await _client.getJson('/api/v1/restaurants/$restaurantId/menu');
    final data = Map<String, dynamic>.from(payload['data'] as Map);

    final restaurant = RestaurantModel.fromJson(
      Map<String, dynamic>.from(data['restaurant'] as Map),
    );

    final rawProducts = (data['products'] as List?) ?? const [];
    final products = rawProducts
        .whereType<Map>()
        .map((item) =>
            RestaurantDishModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    final rawCategories = (data['categories'] as List?) ?? const [];
    final categories = rawCategories.whereType<Map>().map((item) {
      final category = Map<String, dynamic>.from(item);
      final categoryId = '${category['id']}';

      return RestaurantMenuCategoryModel(
        id: categoryId,
        name: (category['name'] ?? '').toString(),
        dishes: products
            .where((product) => product.categoryId == categoryId)
            .toList(growable: false),
      );
    }).toList(growable: false);

    return RestaurantMenuPayload(
      restaurant: restaurant.copyWith(menuCategories: categories),
      categories: categories,
      products: products,
    );
  }
}

class RestaurantMenuPayload {
  const RestaurantMenuPayload({
    required this.restaurant,
    required this.categories,
    required this.products,
  });

  final RestaurantModel restaurant;
  final List<RestaurantMenuCategoryModel> categories;
  final List<RestaurantDishModel> products;
}
