import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';
import 'product_detail_screen.dart';
import '../widgets/restaurant_gallery_lightbox.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color violetDark = Color(0xFF2A0D35);

  String? _restaurantId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_restaurantId != null) return;

    final routeArg = ModalRoute.of(context)?.settings.arguments;
    final service = context.read<RestaurantService>();
    _restaurantId =
        routeArg is String ? routeArg : service.currentRestaurant?.id;

    if (_restaurantId != null) {
      service.selectRestaurant(_restaurantId!);
      service.loadRestaurantDetail(_restaurantId!, forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantService>(
      builder: (context, restaurantService, child) {
        final restaurant = _restaurantId == null
            ? restaurantService.currentRestaurant
            : restaurantService.findRestaurantById(_restaurantId!);

        if (restaurantService.isLoading && restaurant == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (restaurant == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      restaurantService.errorMessage ??
                          'Ce restaurant est introuvable.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: violetDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_restaurantId != null) {
                          restaurantService.loadRestaurantDetail(
                            _restaurantId!,
                            forceRefresh: true,
                          );
                        }
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final categories = restaurant.menuCategories
            .where((category) => category.dishes.isNotEmpty)
            .toList(growable: false);

        return Scaffold(
          backgroundColor: const Color(0xFFF9F8FC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: violetDark),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Text(
              restaurant.name,
              style: GoogleFonts.poppins(
                color: violetDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => restaurantService.loadRestaurantDetail(
              restaurant.id,
              forceRefresh: true,
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _buildHeroCard(restaurant),
                const SizedBox(height: 18),
                if (restaurant.galleryImages.isNotEmpty) ...[
                  _buildSectionTitle('Galerie'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: restaurant.galleryImages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 128,
                            child: RestaurantGalleryThumbnail(
                              images: restaurant.galleryImages,
                              index: index,
                              child: _remoteOrAssetImage(
                                restaurant.galleryImages[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                _buildSectionTitle('Menu'),
                const SizedBox(height: 10),
                if (categories.isEmpty)
                  _buildEmptyCard(
                    'Aucun produit publié pour le moment.',
                  )
                else
                  ...categories.map(
                    (category) => _buildCategoryBlock(context, category),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(RestaurantData restaurant) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child:
                  _remoteOrAssetImage(restaurant.coverImage, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: violetDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: restaurant.isOpen
                            ? const Color(0xFFEAF8EF)
                            : const Color(0xFFFFEBEB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        restaurant.isOpen ? 'Ouvert' : 'Fermé',
                        style: GoogleFonts.poppins(
                          color: restaurant.isOpen
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  restaurant.type,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  restaurant.description,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade800,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _metaChip(Icons.location_on_outlined, restaurant.address),
                    _metaChip(Icons.schedule_outlined, restaurant.openingHours),
                    if (restaurant.rating != '--')
                      _metaChip(Icons.star_rounded, restaurant.rating),
                    if (restaurant.preparationTime.isNotEmpty)
                      _metaChip(
                        Icons.timer_outlined,
                        restaurant.preparationTime,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBlock(
    BuildContext context,
    RestaurantMenuCategoryModel category,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.name,
            style: GoogleFonts.poppins(
              color: violetDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...category.dishes.map((dish) => _buildDishCard(context, dish)),
        ],
      ),
    );
  }

  Widget _buildDishCard(BuildContext context, RestaurantDishModel dish) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(dish: dish),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAE6F2)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 78,
                height: 78,
                child: _remoteOrAssetImage(
                  dish.image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    style: GoogleFonts.poppins(
                      color: violetDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dish.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        dish.priceText,
                        style: GoogleFonts.poppins(
                          color: orangeFlavor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        dish.isAvailable ? 'Disponible' : 'Indisponible',
                        style: GoogleFonts.poppins(
                          color: dish.isAvailable
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: violetDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: violetDark,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildEmptyCard(String label) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE6F2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.grey.shade700,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: violetFlavor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: violetDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _remoteOrAssetImage(
    String? path, {
    BoxFit fit = BoxFit.cover,
  }) {
    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.restaurant_rounded, color: violetFlavor),
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade100,
          child: const Icon(Icons.restaurant_rounded, color: violetFlavor),
        ),
      );
    }

    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.restaurant_rounded, color: violetFlavor),
      ),
    );
  }
}
