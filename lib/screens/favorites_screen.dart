import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/restaurant_service.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);

  @override
  Widget build(BuildContext context) {
    final restaurantService = context.watch<RestaurantService>();
    final favoriteRestaurants = restaurantService.favoriteRestaurants;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              ),
              (route) => false,
            );
          },
        ),
        title: Text(
          'Mes Favoris',
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: favoriteRestaurants.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: favoriteRestaurants.length,
              itemBuilder: (context, index) {
                return _buildFavoriteCard(context, favoriteRestaurants[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            "Aucun favori pour l'instant",
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold, color: violetFlavor),
          ),
          const SizedBox(height: 10),
          const Text(
              "Enregistrez vos restaurants préférés pour\nles retrouver plus rapidement.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              ),
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: orangeFlavor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(90)),
            ),
            child: const Text("Découvrir des restaurants",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _favoriteImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _favoriteImageFallback(),
      );
    }

    return Image.network(
      imagePath,
      height: 160,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _favoriteImageFallback(),
    );
  }

  Widget _favoriteImageFallback() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: violetFlavor,
          size: 42,
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, RestaurantData restaurant) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/restaurant-detail',
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(25)),
                  child: _favoriteImage(restaurant.coverImage),
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: GestureDetector(
                    onTap: () {
                      Provider.of<RestaurantService>(context, listen: false)
                          .toggleFavorite(restaurant.id);

                      NotificationService.instance.addNotification(
                        title: 'Favori supprimé',
                        message: '${restaurant.name} a été retiré de vos favoris.',
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${restaurant.name} retiré des favoris'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.favorite, color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurant.name,
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(restaurant.rating,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 15),
                          const Icon(Icons.access_time,
                              color: Colors.grey, size: 18),
                          const SizedBox(width: 4),
                          Text(restaurant.preparationTime,
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/restaurant-detail'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: violetFlavor.withOpacity(0.1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(90)),
                    ),
                    child: const Text("Commander",
                        style: TextStyle(
                            color: violetFlavor, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
