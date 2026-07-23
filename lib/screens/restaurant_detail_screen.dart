import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../models/cart_item.dart';
import '../services/restaurant_service.dart';
import '../services/reservation_service.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';
import 'chat_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color violetDark = Color(0xFF2A0D35);

  String selectedCategory = 'Petit déjeuner';
  int _selectedTabIndex = 0;
  final Set<String> _addedDishIds = <String>{};
  final Set<String> _favoriteDishIds = <String>{};
  final List<Map<String, String>> _reviews = [
    {
      'name': 'Cynthia K.',
      'rating': '5.0',
      'comment': 'Très bon restaurant, service rapide et plats bien présentés.',
    },
    {
      'name': 'Junior M.',
      'rating': '4.8',
      'comment': 'Le menu QR est pratique et le poulet mayo est excellent.',
    },
    {
      'name': 'Grâce N.',
      'rating': '5.0',
      'comment': 'Belle adresse à Brazzaville. Je recommande.',
    },
  ];

  double get _averageRating {
    if (_reviews.isEmpty) return 0;

    final total = _reviews.fold<double>(
      0,
      (sum, review) => sum + double.parse(review['rating'] ?? '0'),
    );

    return total / _reviews.length;
  }
  void _goBackSafely() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantService>(
      builder: (context, restaurantService, child) {
        final restaurant = restaurantService.joliCoin;

        return DefaultTabController(
          length: 4,
          child: Builder(
            builder: (context) {
              final tabController = DefaultTabController.of(context);
              tabController.addListener(() {
                if (!tabController.indexIsChanging &&
                    _selectedTabIndex != tabController.index) {
                  setState(() {
                    _selectedTabIndex = tabController.index;
                  });
                }
              });

              return Scaffold(
                backgroundColor: Colors.white,
                body: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: 300,
                        pinned: true,
                        elevation: 0,
                        backgroundColor: violetFlavor,
                        leading: IconButton(
                          icon: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(90),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: violetFlavor,
                              size: 20,
                            ),
                          ),
                          onPressed: _goBackSafely,
                        ),
                        actions: [
                          _buildCircleAction(
                            Icons.share_rounded,
                            () => _showShareOptions(restaurant),
                          ),
                          const SizedBox(width: 10),
                          Consumer<RestaurantService>(
                            builder: (context, service, _) {
                              final isFav = service.isFavorite(restaurant.id);
                              return _buildCircleAction(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                () {
                                  service.toggleFavorite(restaurant.id);

                                  final nowFavorite = !isFav;

                                  NotificationService.instance.addNotification(
                                    title: nowFavorite ? 'Favori ajouté' : 'Favori supprimé',
                                    message: nowFavorite
                                        ? '${restaurant.name} a été ajouté à vos favoris.'
                                        : '${restaurant.name} a été retiré de vos favoris.',
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        nowFavorite
                                            ? '${restaurant.name} ajouté aux favoris'
                                            : '${restaurant.name} retiré des favoris',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                color: isFav ? Colors.redAccent : violetFlavor,
                              );
                            },
                          ),
                          const SizedBox(width: 15),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                restaurant.coverImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: violetDark,
                                  child: const Icon(Icons.image,
                                      color: Colors.white),
                                ),
                              ),
                              Container(color: Colors.black.withOpacity(0.3)),
                              Positioned(
                                bottom: 30,
                                left: 0,
                                right: 0,
                                child:
                                    _buildMiniGallery(restaurant.galleryImages),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      restaurant.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: violetDark,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: restaurant.isOpen
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      restaurant.isOpen ? 'Ouvert' : 'Fermé',
                                      style: TextStyle(
                                        color: restaurant.isOpen
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(restaurant.rating,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 15),
                                  const Icon(Icons.location_on,
                                      color: orangeFlavor, size: 20),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(restaurant.address)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ouvert aujourd’hui • ${restaurant.openingHours}',
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            labelColor: orangeFlavor,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: orangeFlavor,
                            indicatorWeight: 3,
                            labelStyle: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            tabs: const [
                              Tab(text: 'Menu'),
                              Tab(text: 'Infos'),
                              Tab(text: 'Galerie'),
                              Tab(text: 'Avis'),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    children: [
                      _buildMenuTab(restaurant),
                      _buildInfosTab(restaurant),
                      _buildGalerieTab(restaurant.galleryImages),
                      _buildAvisTab(),
                    ],
                  ),
                ),
                bottomNavigationBar: _buildBottomActionButton(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCircleAction(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(90),
        ),
        child: Icon(icon, color: color ?? violetFlavor, size: 20),
      ),
    );
  }

  void _showShareOptions(RestaurantData restaurant) {
    final shareMessage =
        'Découvre ${restaurant.name} sur FlavorWay 🍽️\n${restaurant.type}\n${restaurant.address}\nNote : ${restaurant.rating}/5';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(90),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Partager ce restaurant',
                style: GoogleFonts.poppins(
                  color: violetDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choisissez une option de partage.',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              _shareOption(
                icon: Icons.chat_rounded,
                title: 'WhatsApp',
                subtitle: 'Copier le message pour l’envoyer sur WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _copyShareMessage(
                  shareMessage,
                  'Message WhatsApp copié',
                ),
              ),
              _shareOption(
                icon: Icons.facebook_rounded,
                title: 'Facebook',
                subtitle: 'Copier le message pour le publier sur Facebook',
                color: const Color(0xFF1877F2),
                onTap: () => _copyShareMessage(
                  shareMessage,
                  'Message Facebook copié',
                ),
              ),
              _shareOption(
                icon: Icons.link_rounded,
                title: 'Copier le lien',
                subtitle: 'Copier les informations du restaurant',
                color: orangeFlavor,
                onTap: () => _copyShareMessage(
                  shareMessage,
                  'Informations copiées',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: violetDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: violetFlavor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _copyShareMessage(String message, String confirmation) {
    Clipboard.setData(ClipboardData(text: message));
    if (Navigator.canPop(context)) {
      Navigator.maybePop(context);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(confirmation),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildMiniGallery(List<String> galleryItems) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: galleryItems.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showImagePreview(galleryItems[index]),
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                image: DecorationImage(
                  image: AssetImage(galleryItems[index]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuTab(RestaurantData restaurant) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showImagePreview(restaurant.menuImage),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                restaurant.menuImage,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 240,
                  alignment: Alignment.center,
                  color: Colors.grey.shade100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.image_not_supported_rounded,
                        color: violetFlavor,
                        size: 38,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image article.png introuvable',
                        style: GoogleFonts.poppins(
                          color: violetDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            'Menu complet',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold, color: violetDark),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: restaurant.menuCategories.length,
              itemBuilder: (context, index) {
                final category = restaurant.menuCategories[index].name;
                final bool isSelected = selectedCategory == category;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? orangeFlavor
                          : violetFlavor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(90),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : violetFlavor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          ...restaurant.menuCategories
              .where((section) => section.name == selectedCategory)
              .map((section) => _buildMenuSection(section))
              .toList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuSection(RestaurantMenuCategory section) {
    final items = section.dishes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Text(
            section.name,
            style: GoogleFonts.poppins(
              color: violetFlavor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ...items.map((item) => _buildDishItem(item)).toList(),
      ],
    );
  }

  void _addDishToCart(RestaurantDish dish, CartService cart,
      {int quantity = 1}) {
    if (dish.price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce plat est actuellement indisponible'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    for (int i = 0; i < quantity; i++) {
      cart.addItem(
        CartItem(
          id: 'jolicoin_${dish.id}_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: dish.name,
          image: dish.image ?? 'assets/images/restaurants/joli_coin/cover.png',
          restaurantName: context.read<RestaurantService>().joliCoin.name,
          price: dish.price,
        ),
      );
    }

    setState(() {
      _addedDishIds.add(dish.id);
    });

    NotificationService.instance.addNotification(
      title: 'Article ajouté',
      message: '$quantity x ${dish.name} ajouté au panier.',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $quantity x ${dish.name} ajouté au panier'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildDishItem(RestaurantDish dish) {
    final bool canAddToCart = dish.price > 0;

    return GestureDetector(
      onTap: () => _showDishDetail(dish),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                dish.image ?? 'assets/images/restaurants/joli_coin/cover.png',
                width: 82,
                height: 82,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 82,
                  height: 82,
                  color: Colors.grey.shade100,
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: violetFlavor,
                  ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: violetDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dish.description,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        dish.priceText,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          color: orangeFlavor,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Consumer<CartService>(
                        builder: (context, cart, child) {
                          final bool isAdded = cart.items.any(
                            (item) => item.name == dish.name,
                          );
                          return GestureDetector(
                            onTap: () => _addDishToCart(dish, cart),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isAdded
                                    ? Colors.green.withOpacity(0.12)
                                    : canAddToCart
                                        ? orangeFlavor.withOpacity(0.12)
                                        : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(90),
                              ),
                              child: Icon(
                                isAdded
                                    ? Icons.check_rounded
                                    : canAddToCart
                                        ? Icons.add_rounded
                                        : Icons.info_outline_rounded,
                                color: isAdded
                                    ? Colors.green
                                    : canAddToCart
                                        ? orangeFlavor
                                        : Colors.grey,
                                size: 21,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDishDetail(RestaurantDish dish) {
    int quantity = 1;
    final bool canAddToCart = dish.price > 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bool isDishFavorite = _favoriteDishIds.contains(dish.id);
            return Consumer<CartService>(
              builder: (context, cart, child) {
                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.92,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(32),
                              ),
                              child: Image.asset(
                                dish.image ??
                                    'assets/images/restaurants/joli_coin/cover.png',
                                width: double.infinity,
                                height: 260,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: double.infinity,
                                  height: 260,
                                  color: Colors.grey.shade100,
                                  child: const Icon(
                                    Icons.restaurant_rounded,
                                    color: violetFlavor,
                                    size: 46,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              left: 16,
                              child: _dishCircleButton(
                                icon: Icons.close_rounded,
                                onTap: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.maybePop(context);
                                  }
                                },
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: _dishCircleButton(
                                icon: isDishFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                onTap: () {
                                  setState(() {
                                    if (_favoriteDishIds.contains(dish.id)) {
                                      _favoriteDishIds.remove(dish.id);
                                    } else {
                                      _favoriteDishIds.add(dish.id);
                                    }
                                  });
                                  setModalState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _favoriteDishIds.contains(dish.id)
                                            ? '${dish.name} ajouté aux favoris'
                                            : '${dish.name} retiré des favoris',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      dish.name,
                                      style: GoogleFonts.poppins(
                                        color: violetDark,
                                        fontSize: 25,
                                        height: 1.12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: orangeFlavor.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(90),
                                    ),
                                    child: Text(
                                      dish.priceText,
                                      style: GoogleFonts.poppins(
                                        color: orangeFlavor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFB000),
                                    size: 19,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.8',
                                    style: GoogleFonts.poppins(
                                      color: violetDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Icon(
                                    Icons.schedule_rounded,
                                    color: Colors.grey.shade500,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '15-30 min',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                dish.description,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _dishOptionCard(
                                title: 'Choisir une taille',
                                subtitle: 'Option recommandée',
                                value: 'Standard',
                              ),
                              const SizedBox(height: 12),
                              _dishOptionCard(
                                title: 'Suppléments',
                                subtitle: 'Optionnel',
                                value: 'Aucun',
                              ),
                              const SizedBox(height: 26),
                              Row(
                                children: [
                                  Container(
                                    height: 54,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(90),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: quantity > 1
                                              ? () {
                                                  setModalState(() {
                                                    quantity--;
                                                  });
                                                }
                                              : null,
                                          icon:
                                              const Icon(Icons.remove_rounded),
                                          color: orangeFlavor,
                                        ),
                                        Text(
                                          '$quantity',
                                          style: GoogleFonts.poppins(
                                            color: violetDark,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setModalState(() {
                                              quantity++;
                                            });
                                          },
                                          icon: const Icon(Icons.add_rounded),
                                          color: orangeFlavor,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SizedBox(
                                      height: 54,
                                      child: ElevatedButton.icon(
                                        onPressed: canAddToCart
                                            ? () {
                                                _addDishToCart(
                                                  dish,
                                                  cart,
                                                  quantity: quantity,
                                                );
                                                Navigator.maybePop(context);
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.shopping_cart_rounded,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          canAddToCart
                                              ? 'Ajouter au panier'
                                              : 'Indisponible',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: orangeFlavor,
                                          disabledBackgroundColor:
                                              Colors.grey.shade300,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(90),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _dishCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(90),
        ),
        child: Icon(icon, color: color ?? violetFlavor, size: 22),
      ),
    );
  }

  Widget _dishOptionCard({
    required String title,
    required String subtitle,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: violetDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: orangeFlavor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(90),
                      ),
                      child: Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: orangeFlavor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: violetFlavor,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildInfosTab(RestaurantData restaurant) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _infoRow(Icons.restaurant, 'Restaurant', restaurant.name),
        _infoRow(Icons.category, 'Type', restaurant.type),
        _infoRow(Icons.location_on, 'Adresse', restaurant.address),
        _infoRow(Icons.access_time, 'Horaires', restaurant.openingHours),
        _infoRow(Icons.phone, 'Téléphone', restaurant.phone),
        const SizedBox(height: 20),
        Text(
          'Contact restaurant',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: violetDark,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: orangeFlavor.withOpacity(0.12),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: orangeFlavor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: GoogleFonts.poppins(
                        color: violetDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Restaurant',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _contactAction(
                icon: Icons.chat_bubble_rounded,
                tooltip: 'Chat client / restaurant / livreur',
                onTap: _showRestaurantMessageSheet,
              ),
              const SizedBox(width: 10),
              _contactAction(
                icon: Icons.call_rounded,
                tooltip: 'Appeler le restaurant',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Numéro du restaurant : ${restaurant.phone}'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Services',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: violetDark,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: restaurant.services
                .map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: violetFlavor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(90),
                      ),
                      child: Text(
                        service,
                        style: GoogleFonts.poppins(
                          color: violetFlavor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Localisation',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: violetDark,
          ),
        ),
        const SizedBox(height: 12),
        _buildRestaurantMapCard(restaurant),
      ],
    );
  }

  Widget _contactAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: violetFlavor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(90),
          ),
          child: Icon(
            icon,
            color: violetFlavor,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: orangeFlavor, size: 22),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRestaurantMapCard(RestaurantData restaurant) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CustomPaint(
                painter: _FakeMapPainter(),
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: orangeFlavor,
                  borderRadius: BorderRadius.circular(90),
                  boxShadow: [
                    BoxShadow(
                      color: orangeFlavor.withOpacity(0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.map_rounded,
                    color: violetFlavor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      restaurant.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: violetDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.open_in_new_rounded,
                    color: orangeFlavor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalerieTab(List<String> galleryItems) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: galleryItems.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showImagePreview(galleryItems[index]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              galleryItems[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.grey.shade200),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvisTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Text(
              _averageRating.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                color: violetDark,
                fontSize: 42,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (index) => const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB000),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Basé sur ${_reviews.length} avis',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 22),
        ..._reviews.map(
          (review) => _reviewCard(
            name: review['name']!,
            rating: review['rating']!,
            comment: review['comment']!,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _showRatingSheet,
            icon: const Icon(Icons.star_rounded, color: orangeFlavor),
            label: Text(
              'Noter ce restaurant',
              style: GoogleFonts.poppins(
                color: violetDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(90),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewCard({
    required String name,
    required String rating,
    required String comment,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: orangeFlavor.withOpacity(0.12),
                child: Text(
                  name.substring(0, 1),
                  style: GoogleFonts.poppins(
                    color: orangeFlavor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: violetDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFFB000), size: 18),
              const SizedBox(width: 3),
              Text(
                rating,
                style: GoogleFonts.poppins(
                  color: violetDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade700,
              height: 1.4,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingSheet() {
    final TextEditingController commentController = TextEditingController();
    double selectedRating = 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Votre note',
                        style: GoogleFonts.poppins(
                          color: violetDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedRating = (index + 1).toDouble();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              Icons.star_rounded,
                              color: (index < selectedRating)
                                  ? const Color(0xFFFFB000)
                                  : Colors.grey.shade300,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Partagez votre expérience...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final comment = commentController.text.trim();
                          if (selectedRating <= 0 || comment.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Veuillez donner une note et écrire un commentaire'),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _reviews.insert(0, {
                              'name': 'Vous',
                              'rating': selectedRating.toStringAsFixed(1),
                              'comment': comment,
                            });
                          });
                          Navigator.maybePop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Merci pour votre avis'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeFlavor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(90),
                          ),
                        ),
                        child: Text(
                          'Envoyer ma note',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReservationSheet() {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 20, minute: 0);
    int selectedPeople = 2;
    String selectedTable = 'Table standard';
    final TextEditingController phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String formattedDate =
                '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
            String formattedTime = selectedTime.format(context);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(90),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Réserver une table',
                        style: GoogleFonts.poppins(
                          color: violetDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choisissez votre date, votre heure et indiquez votre numéro.',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _reservationPickerRow(
                        icon: Icons.calendar_month_rounded,
                        label: 'Date',
                        value: formattedDate,
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 60),
                            ),
                          );

                          if (pickedDate != null) {
                            setModalState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                      ),
                      _reservationPickerRow(
                        icon: Icons.schedule_rounded,
                        label: 'Heure',
                        value: formattedTime,
                        onTap: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );

                          if (pickedTime != null) {
                            setModalState(() {
                              selectedTime = pickedTime;
                            });
                          }
                        },
                      ),
                      _reservationDropdown<int>(
                        icon: Icons.people_alt_rounded,
                        label: 'Personnes',
                        value: selectedPeople,
                        items: List.generate(10, (index) => index + 1),
                        itemLabel: (value) =>
                            '$value personne${value > 1 ? 's' : ''}',
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() {
                            selectedPeople = value;
                          });
                        },
                      ),
                      _reservationDropdown<String>(
                        icon: Icons.table_restaurant_rounded,
                        label: 'Table',
                        value: selectedTable,
                        items: const [
                          'Table standard',
                          'Table terrasse',
                          'Table calme',
                          'Table famille',
                        ],
                        itemLabel: (value) => value,
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() {
                            selectedTable = value;
                          });
                        },
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.phone_rounded,
                            color: orangeFlavor,
                          ),
                          labelText: 'Numéro de téléphone',
                          hintText: '+242 00 000 00 00',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: orangeFlavor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            final phone = phoneController.text.trim();

                            if (phone.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Veuillez renseigner votre numéro de téléphone'),
                                ),
                              );
                              return;
                            }

                            ReservationService.instance.addReservation(
                              restaurantName:
                                  context.read<RestaurantService>().joliCoin.name,
                              date: formattedDate,
                              time: formattedTime,
                              guests: selectedPeople,
                            );
                            NotificationService.instance.addNotification(
                              title: 'Réservation confirmée',
                              message:
                                  'Votre réservation chez ${context.read<RestaurantService>().joliCoin.name} a été enregistrée pour le $formattedDate à $formattedTime.',
                            );
                            Navigator.maybePop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Réservation ajoutée dans Mes réservations',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeFlavor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(90),
                            ),
                          ),
                          child: Text(
                            'Confirmer la réservation',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _reservationPickerRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: orangeFlavor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: violetDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: violetFlavor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _reservationDropdown<T>({
    required IconData icon,
    required String label,
    required T value,
    required List<T> items,
    required String Function(T value) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: orangeFlavor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox.shrink(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: violetFlavor,
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabel(item),
                      style: GoogleFonts.poppins(
                        color: violetDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _reservationRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: orangeFlavor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: violetDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _showRestaurantMessageSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatScreen(
          conversationId: 'restaurant_joli_coin',
        ),
      ),
    );
  }

  Widget _buildBottomActionButton() {
    String label;
    IconData icon;
    VoidCallback onPressed;

    if (_selectedTabIndex == 0) {
      label = 'Valider ma commande';
      icon = Icons.shopping_cart_checkout_rounded;
      onPressed = () => Navigator.pushNamed(context, '/checkout');
    } else if (_selectedTabIndex == 1) {
      label = 'Réserver une table';
      icon = Icons.event_available_rounded;
      onPressed = _showReservationSheet;
    } else if (_selectedTabIndex == 2) {
      label = 'Envoyer un message';
      icon = Icons.chat_bubble_rounded;
      onPressed = _showRestaurantMessageSheet;
    } else {
      label = 'Voir le menu';
      icon = Icons.restaurant_menu_rounded;
      onPressed = () {
        DefaultTabController.of(context).animateTo(0);
        setState(() {
          _selectedTabIndex = 0;
        });
      };
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 21),
          style: ElevatedButton.styleFrom(
            backgroundColor: orangeFlavor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(90)),
            elevation: 0,
          ),
          label: Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePreview(String imagePath) {
    final galleryImages =
        context.read<RestaurantService>().joliCoin.galleryImages;
    int currentIndex = galleryImages.indexOf(imagePath);

    if (currentIndex < 0) {
      currentIndex = 0;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentImage = galleryImages.isNotEmpty
                ? galleryImages[currentIndex]
                : imagePath;

            void goToPrevious() {
              if (galleryImages.isEmpty) return;
              setDialogState(() {
                currentIndex = currentIndex == 0
                    ? galleryImages.length - 1
                    : currentIndex - 1;
              });
            }

            void goToNext() {
              if (galleryImages.isEmpty) return;
              setDialogState(() {
                currentIndex = currentIndex == galleryImages.length - 1
                    ? 0
                    : currentIndex + 1;
              });
            }

            return Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      child: Image.asset(
                        currentImage,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.image_not_supported_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                  if (galleryImages.length > 1)
                    Positioned(
                      left: 18,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: goToPrevious,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(90),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                              ),
                            ),
                            child: const Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (galleryImages.length > 1)
                    Positioned(
                      right: 18,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: goToNext,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(90),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                              ),
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (galleryImages.length > 1)
                    Positioned(
                      bottom: 34,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(90),
                          ),
                          child: Text(
                            '${currentIndex + 1} / ${galleryImages.length}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FakeMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFEFF2EF);
    canvas.drawRect(Offset.zero & size, background);

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final secondaryRoadPaint = Paint()
      ..color = const Color(0xFFD9DED9)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(-20, size.height * 0.25)
      ..quadraticBezierTo(size.width * 0.30, size.height * 0.10,
          size.width * 0.65, size.height * 0.30)
      ..quadraticBezierTo(size.width * 0.90, size.height * 0.44,
          size.width + 20, size.height * 0.36);
    canvas.drawPath(path1, roadPaint);

    final path2 = Path()
      ..moveTo(size.width * 0.15, -20)
      ..quadraticBezierTo(size.width * 0.30, size.height * 0.35,
          size.width * 0.20, size.height + 20);
    canvas.drawPath(path2, secondaryRoadPaint);

    final path3 = Path()
      ..moveTo(size.width + 10, size.height * 0.78)
      ..quadraticBezierTo(
          size.width * 0.55, size.height * 0.62, -20, size.height * 0.82);
    canvas.drawPath(path3, secondaryRoadPaint);

    final blockPaint = Paint()..color = const Color(0xFFE1E7E1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.58, 70, 42),
        const Radius.circular(10),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.62, size.height * 0.12, 92, 48),
        const Radius.circular(12),
      ),
      blockPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
