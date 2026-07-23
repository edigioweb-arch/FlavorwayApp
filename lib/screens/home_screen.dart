import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/cart_service.dart';
import '../services/restaurant_service.dart';
import '../services/notification_service.dart';
import 'favorites_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'messages_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedCategory = 0;
  int _selectedFilter = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  int _currentPromoIndex = 0;
  final PageController _promoController = PageController(viewportFraction: 1);
  Timer? _promoTimer;

  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color violetDark = Color(0xFF2A0D35);
  static const Color pageBg = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFF5F4F8);

  // Tu peux modifier tous les rayons ici.
  static const double buttonRadius = 90;
  static const double cardRadius = 12;
  static const double headerRadius = 12;

  // Tu peux modifier les images ici, sans toucher au reste du code.
  static const String offerImage1 = 'assets/images/offer.png';
  static const String offerImage2 = 'assets/images/offer.png';
  static const String offerImage3 = 'assets/images/offer.png';

  static const String cuisineAllImage =
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80';
  static const String cuisineCongoImage =
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80';
  static const String cuisineGrillImage =
      'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=500&q=80';
  static const String cuisineLoungeImage =
      'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=500&q=80';
  static const String cuisinePizzaImage =
      'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500&q=80';

  static const String restaurantImage1 =
      'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=900&q=80';
  static const String restaurantImage2 =
      'https://images.unsplash.com/photo-1517248135467-4c7ed9d42c77?w=900&q=80';
  static const String restaurantImage3 =
      'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=900&q=80';

  final List<Map<String, String>> promoCards = const [
    {
      'badge': 'Offres du week-end',
      'title': 'Réservez votre table',
      'discount': '30',
      'cta': 'Réserver',
      'image': offerImage1,
    },
    {
      'badge': 'Menu QR',
      'title': 'Consultez les menus',
      'discount': 'QR',
      'cta': 'Scanner',
      'image': offerImage2,
    },
    {
      'badge': 'Brazza sélection',
      'title': 'Top restaurants',
      'discount': '10',
      'cta': 'Explorer',
      'image': offerImage3,
    },
  ];

  final List<Map<String, String>> categories = const [
    {'name': 'Tous', 'image': cuisineAllImage},
    {'name': 'Congolais', 'image': cuisineCongoImage},
    {'name': 'Grillades', 'image': cuisineGrillImage},
    {'name': 'Lounge', 'image': cuisineLoungeImage},
    {'name': 'Pizzeria', 'image': cuisinePizzaImage},
  ];

  final List<String> filters = const [
    'Réservation',
    'Ouvert',
    'Menu QR',
    'Bien notés',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: pageBg,
        body: SafeArea(
          bottom: false,
          child: _buildCurrentPage(),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildRestaurantsPage();
      case 2:
        return const OrdersScreen();
      case 3:
        return const FavoritesScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildComingSoonPage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: violetFlavor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(buttonRadius),
              ),
              child: Icon(icon, color: violetFlavor, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: const Color(0xFF1B1B1B),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantsPage() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(),
              _buildSectionTitle('Tous les restaurants', showSeeAll: false),
              _buildCuisineCategories(),
              _buildSectionTitle('Filtres', showSeeAll: false),
              _buildFilters(),
              // _buildSearchSuggestions() removed here
            ],
          ),
        ),
        _buildRestaurantList(),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  Widget _buildMessagesPage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages',
              style: GoogleFonts.poppins(
                color: const Color(0xFF1B1B1B),
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discutez avec les restaurants, les livreurs et le support FlavorWay.',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            _messageTile(
              icon: Icons.restaurant_rounded,
              title: 'Chat restaurant',
              subtitle:
                  'Échangez avec un restaurant avant ou après une réservation.',
              badge: 'Bientôt',
            ),
            _messageTile(
              icon: Icons.delivery_dining_rounded,
              title: 'Chat livreur',
              subtitle: 'Suivez une livraison et contactez le livreur.',
              badge: 'Bientôt',
            ),
            _messageTile(
              icon: Icons.support_agent_rounded,
              title: 'Support client',
              subtitle: 'Besoin d’aide ? Contactez l’équipe FlavorWay.',
              badge: 'Support',
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: violetFlavor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: violetFlavor, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1B1B1B),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: orangeFlavor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
            child: Text(
              badge,
              style: GoogleFonts.poppins(
                color: orangeFlavor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(),
              _buildSectionTitle('Offres spéciales',
                  showSeeAll: true, onTap: () => _onItemTapped(1)),
              _buildPromoSlider(),
              _buildSectionTitle('Cuisines',
                  showSeeAll: true, onTap: () => _onItemTapped(1)),
              _buildCuisineCategories(),
              _buildSectionTitle('Recommandés',
                  showSeeAll: true, onTap: () => _onItemTapped(1)),
              _buildRecommendedRestaurants(),
              _buildSectionTitle('Restaurants populaires',
                  showSeeAll: true, onTap: () => _onItemTapped(1)),
              _buildFilters(),
              // _buildSearchSuggestions() removed here
            ],
          ),
        ),
        _buildRestaurantList(),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrer les restaurants',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: violetDark,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(filters.length, (index) {
                  final isSelected = _selectedFilter == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = index;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? violetFlavor : Colors.white,
                        borderRadius: BorderRadius.circular(buttonRadius),
                        border: Border.all(
                            color: isSelected
                                ? violetFlavor
                                : Colors.grey.shade300),
                      ),
                      child: Text(
                        filters[index],
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [violetDark, violetFlavor],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(headerRadius),
          bottomRight: Radius.circular(headerRadius),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: 42,
            child: Container(
              width: 210,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(120),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            right: 26,
            top: 72,
            child: Container(
              width: 150,
              height: 92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(90),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Votre position',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: orangeFlavor,
                              size: 19,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Brazzaville, Congo',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: orangeFlavor,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMessageButton(),
                      const SizedBox(width: 10),
                      _buildNotificationButton(),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(buttonRadius),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: violetFlavor,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              style: GoogleFonts.poppins(fontSize: 15),
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.trim();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Rechercher',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade500,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showFilterModal,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(buttonRadius),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: violetFlavor,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
              _buildSearchSuggestions(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MessagesScreen(),
        ),
      ),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        child: const Icon(
          Icons.chat_bubble_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        final unreadCount = notificationService.unreadCount;

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/notifications'),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: Colors.white,
                  size: 25,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 5,
                    top: 5,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      decoration: const BoxDecoration(
                        color: orangeFlavor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
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
  }

  Widget _buildPromoSlider() {
    return Column(
      children: [
        SizedBox(
          height: 184,
          child: PageView.builder(
            controller: _promoController,
            physics: const BouncingScrollPhysics(),
            itemCount: promoCards.length,
            onPageChanged: (index) {
              setState(() {
                _currentPromoIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final promo = promoCards[index];
              final imagePath = promo['image'] ?? offerImage1;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cardRadius),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        orangeFlavor,
                        Color(0xFFC6533F),
                        violetFlavor,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: violetFlavor.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(cardRadius),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -35,
                          top: -22,
                          bottom: -22,
                          child: Container(
                            width: 230,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Image.asset(
                              imagePath,
                              width: 190,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 170,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(cardRadius),
                                  ),
                                  child: const Icon(
                                    Icons.image_not_supported_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 205, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius:
                                      BorderRadius.circular(buttonRadius),
                                ),
                                child: Text(
                                  promo['badge'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                promo['title'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 19,
                                  height: 1.02,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    (promo['discount'] ?? '') == 'QR'
                                        ? 'Menu'
                                        : 'Jusqu’à',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.90),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    promo['discount'] ?? '',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 30,
                                      height: 0.92,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if ((promo['discount'] ?? '') != 'QR')
                                    Container(
                                      margin: const EdgeInsets.only(
                                        left: 3,
                                        bottom: 5,
                                      ),
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.20),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.42),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '%',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(buttonRadius),
                                ),
                                child: Text(
                                  promo['cta'] ?? '',
                                  style: GoogleFonts.poppins(
                                    color: violetFlavor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            promoCards.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: index == _currentPromoIndex ? 18 : 9,
              height: 9,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: index == _currentPromoIndex
                    ? violetFlavor
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(buttonRadius),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _startPromoAutoSlide();
  }

  void _startPromoAutoSlide() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_promoController.hasClients || promoCards.isEmpty) return;

      final nextIndex = (_currentPromoIndex + 1) % promoCards.length;
      _promoController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title,
      {bool showSeeAll = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B1B1B),
            ),
          ),
          if (showSeeAll)
            GestureDetector(
              onTap: onTap,
              child: Text(
                'Voir tout',
                style: GoogleFonts.poppins(
                  color: violetFlavor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCuisineCategories() {
    return SizedBox(
      height: 54,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final bool isSelected = index == _selectedCategory;
          final category = categories[index];
          final imageUrl = category['image'] ?? cuisineAllImage;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 116,
              margin: EdgeInsets.only(
                right: index == categories.length - 1 ? 24 : 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(buttonRadius),
                color: isSelected ? violetFlavor : Colors.white,
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? violetFlavor.withOpacity(0.48)
                        : Colors.black.withOpacity(0.38),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    category['name'] ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final bool isSelected = index == _selectedFilter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 9),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color:
                    isSelected ? violetFlavor.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(buttonRadius),
                border: Border.all(
                  color: isSelected ? violetFlavor : Colors.grey.shade300,
                ),
              ),
              child: Center(
                child: Text(
                  filters[index],
                  style: GoogleFonts.poppins(
                    color: isSelected ? violetFlavor : const Color(0xFF333333),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    if (_searchQuery.isEmpty) return const SizedBox.shrink();

    return Consumer<RestaurantService>(
      builder: (context, restaurantService, child) {
        final suggestions = _filteredRestaurants(
          restaurantService.approvedRestaurants,
        ).take(5).toList();

        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: suggestions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        color: Colors.grey.shade500,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Aucun résultat pour "\$_searchQuery"',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      child: Text(
                        'Résultats de recherche',
                        style: GoogleFonts.poppins(
                          color: violetFlavor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    ...suggestions.map(
                      (restaurant) => GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          Navigator.pushNamed(context, '/restaurant-detail');
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: softGrey,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 46,
                                  height: 46,
                                  child: _buildRestaurantImageCompact(
                                    restaurant.coverImage,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      restaurant.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF1B1B1B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      restaurant.type,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFB000),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    restaurant.rating,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF1B1B1B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  List<RestaurantData> _filteredRestaurants(List<RestaurantData> restaurants) {
    final categoryName = categories[_selectedCategory]['name'] ?? 'Tous';
    final query = _searchQuery.toLowerCase();

    return restaurants.where((restaurant) {
      final matchesSearch = query.isEmpty ||
          restaurant.name.toLowerCase().contains(query) ||
          restaurant.type.toLowerCase().contains(query) ||
          restaurant.address.toLowerCase().contains(query) ||
          restaurant.services.join(' ').toLowerCase().contains(query);

      final matchesCategory = categoryName == 'Tous' ||
          restaurant.type.toLowerCase().contains(categoryName.toLowerCase());

      final selectedFilterLabel = filters[_selectedFilter];
      bool matchesFilter = true;

      if (selectedFilterLabel == 'Réservation') {
        matchesFilter = restaurant.services.contains('Réservation');
      } else if (selectedFilterLabel == 'Ouvert') {
        matchesFilter = restaurant.isOpen;
      } else if (selectedFilterLabel == 'Menu QR') {
        matchesFilter = restaurant.services.contains('Menu QR');
      } else if (selectedFilterLabel == 'Bien notés') {
        final rating = double.tryParse(restaurant.rating) ?? 0;
        matchesFilter = rating >= 4.5;
      }

      return matchesSearch && matchesCategory && matchesFilter;
    }).toList(growable: false);
  }

  Widget _buildRecommendedRestaurants() {
    return Consumer<RestaurantService>(
      builder: (context, restaurantService, child) {
        final restaurants = restaurantService.recommendedRestaurants;

        if (restaurants.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 330,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];

              return GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/restaurant-detail',
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width - 48,
                  margin: EdgeInsets.only(
                    right: index == restaurants.length - 1 ? 0 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF0EEF2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.055),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: SizedBox(
                              height: 178,
                              width: double.infinity,
                              child: _buildRestaurantImage(
                                restaurant.coverImage,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.94),
                                borderRadius:
                                    BorderRadius.circular(buttonRadius),
                              ),
                              child: Text(
                                'Top recommandé',
                                style: GoogleFonts.poppins(
                                  color: orangeFlavor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.94),
                                borderRadius:
                                    BorderRadius.circular(buttonRadius),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFB000),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    restaurant.rating,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF1B1B1B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1B1B1B),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              restaurant.type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: restaurant.isOpen
                                        ? const Color(0xFFEAF8EE)
                                        : const Color(0xFFFFEEEE),
                                    borderRadius:
                                        BorderRadius.circular(buttonRadius),
                                  ),
                                  child: Text(
                                    restaurant.isOpen ? 'Ouvert' : 'Fermé',
                                    style: GoogleFonts.poppins(
                                      color: restaurant.isOpen
                                          ? const Color(0xFF229A53)
                                          : Colors.redAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _compactMeta(
                                    Icons.access_time_rounded,
                                    restaurant.preparationTime,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _compactMeta(
                                    Icons.location_on_rounded,
                                    restaurant.distance,
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
          ),
        );
      },
    );
  }

  Widget _buildRestaurantList() {
    return Consumer<RestaurantService>(
      builder: (context, restaurantService, child) {
        final restaurants = _filteredRestaurants(
          restaurantService.approvedRestaurants,
        );
        if (restaurants.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: softGrey,
                  borderRadius: BorderRadius.circular(cardRadius),
                ),
                child: Text(
                  'Aucun restaurant ne correspond à votre recherche.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _restaurantCard(restaurants[index]),
              childCount: restaurants.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRestaurantImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        height: 168,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageError(),
      );
    }
    return Image.network(
      imagePath,
      height: 168,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildImageError(),
    );
  }

  Widget _buildRestaurantImageCompact(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: 108,
        height: 116,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageErrorCompact(),
      );
    }

    return Image.network(
      imagePath,
      width: 108,
      height: 116,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildImageErrorCompact(),
    );
  }

  Widget _buildImageErrorCompact() {
    return Container(
      width: 108,
      height: 116,
      color: softGrey,
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: violetFlavor,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      height: 150,
      color: softGrey,
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: violetFlavor,
          size: 42,
        ),
      ),
    );
  }

  Widget _restaurantCard(RestaurantData restaurant) {
    final bool hasMenuQr = restaurant.services.contains('Menu QR');

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/restaurant-detail'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0EEF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.055),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: 168,
                    width: double.infinity,
                    child: _buildRestaurantImage(restaurant.coverImage),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(buttonRadius),
                    ),
                    child: Text(
                      restaurant.isOpen ? 'Ouvert' : 'Fermé',
                      style: GoogleFonts.poppins(
                        color: restaurant.isOpen
                            ? const Color(0xFF229A53)
                            : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Consumer<RestaurantService>(
                    builder: (context, service, _) {
                      final isFav = service.isFavorite(restaurant.id);
                      return GestureDetector(
                        onTap: () => service.toggleFavorite(restaurant.id),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.94),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFav ? Colors.redAccent : Colors.grey,
                            size: 23,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1B1B1B),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              restaurant.type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E8),
                          borderRadius: BorderRadius.circular(buttonRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFB000),
                              size: 15,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              restaurant.rating,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1B1B1B),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _compactMeta(
                        Icons.access_time_rounded,
                        restaurant.preparationTime,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _compactMeta(
                          Icons.location_on_rounded,
                          restaurant.distance,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      if (hasMenuQr)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            color: violetFlavor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(buttonRadius),
                          ),
                          child: Text(
                            'Menu QR',
                            style: GoogleFonts.poppins(
                              color: violetFlavor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: orangeFlavor,
                          borderRadius: BorderRadius.circular(buttonRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Voir',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
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
  }

  Widget _metaItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 16),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _compactMeta(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 15),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: SizedBox(
          height: 92,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 74,
                  padding: const EdgeInsets.fromLTRB(12, 13, 12, 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _bottomNavItem(
                        index: 0,
                        icon: Icons.home_rounded,
                        label: 'Accueil',
                      ),
                      _bottomNavItem(
                        index: 1,
                        icon: Icons.restaurant_rounded,
                        label: 'Resto',
                      ),
                      const Expanded(child: SizedBox()),
                      _bottomNavItem(
                        index: 3,
                        icon: Icons.favorite_rounded,
                        label: 'Favoris',
                      ),
                      _bottomNavItem(
                        index: 4,
                        icon: Icons.person_outline_rounded,
                        label: 'Profil',
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: () => _onItemTapped(2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedIndex == 2 ? violetFlavor : orangeFlavor,
                      border: Border.all(color: Colors.white, width: 7),
                      boxShadow: [
                        BoxShadow(
                          color: orangeFlavor.withOpacity(0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 7,
                child: Container(
                  width: 96,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(90),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? violetFlavor : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: isSelected ? violetFlavor : Colors.grey.shade500,
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.22, 0);
    path.quadraticBezierTo(
        0, size.height * 0.5, size.width * 0.22, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
