import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

void main() => runApp(const FlavorWayApp());

class FlavorWayApp extends StatelessWidget {
  const FlavorWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FlavorWay',
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryColor: const Color(0xFF4B1F5C),
      ),
      home: const FlavorWayLandingPage(),
    );
  }
}

class FlavorWayLandingPage extends StatefulWidget {
  const FlavorWayLandingPage({super.key});

  @override
  State<FlavorWayLandingPage> createState() => _FlavorWayLandingPageState();
}

class _FlavorWayLandingPageState extends State<FlavorWayLandingPage> {
  // --- COULEURS OFFICIELLES FLAVORWAY ---
  final Color violetFlavor = const Color(0xFF4B1F5C);
  final Color orangeFlavor = const Color(0xFFF36A2D);
  final Color backgroundLight = const Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. NAVBAR RESPONSIVE
            _buildNavbar(),

            // 2. HERO SECTION (Orange avec barre de recherche)
            _buildHeroSection(),

            // 3. CATEGORIES FLOTTANTES
            _buildCategories(),

            const SizedBox(height: 50),

            // 4. SECTION RESTAURANTS ANIMÉE
            _buildRestaurantSection(),

            const SizedBox(height: 50),

            // 5. SECTION VILLES ANIMÉE
            _buildCitySection(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // --- NAVBAR RESPONSIVE ---
  Widget _buildNavbar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: orangeFlavor, size: 28),
                const SizedBox(width: 8),
                Text(
                  "FlavorWay",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: violetFlavor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                "Connexion",
                style: TextStyle(
                  color: violetFlavor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: violetFlavor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "S'INSCRIRE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HERO SECTION ---
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: orangeFlavor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(100),
          bottomRight: Radius.circular(100),
        ),
      ),
      child: Column(
        children: [
          FadeInDown(
            child: Text(
              "Le goût du Congo livré chez vous",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 30),
          FadeInUp(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 25),
                  Icon(Icons.search, color: orangeFlavor, size: 28),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Quelle est votre adresse de livraison ?",
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 25,
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: violetFlavor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 35,
                        vertical: 22,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: const Text(
                      "RECHERCHER",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CATEGORIES ---
  Widget _buildCategories() {
    return Transform.translate(
      offset: const Offset(0, -40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _categoryBubble("Restaurants", Icons.restaurant, orangeFlavor),
          _categoryBubble("Courses", Icons.shopping_cart, violetFlavor),
          _categoryBubble("Pharmacie", Icons.local_pharmacy, orangeFlavor),
          _categoryBubble("Colis", Icons.inventory_2, violetFlavor),
        ],
      ),
    );
  }

  Widget _categoryBubble(String name, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          BounceInDown(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 45),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: violetFlavor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION RESTAURANTS ANIMÉE ---
  Widget _buildRestaurantSection() {
    return Center(
      child: Column(
        children: [
          FadeInUp(
            child: Text(
              "Meilleurs restaurants au Congo",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: violetFlavor,
                letterSpacing: -1.2,
              ),
            ),
          ),
          const SizedBox(height: 50),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [orangeFlavor.withOpacity(0.1), backgroundLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: orangeFlavor.withOpacity(0.3)),
              ),
              child: Wrap(
                spacing: 40,
                runSpacing: 40,
                alignment: WrapAlignment.center,
                children: [
                  _restaurantItemAnim("McDonald's", 0),
                  _restaurantItemAnim("KFC", 200),
                  _restaurantItemAnim("Burger King", 400),
                  _restaurantItemAnim("Pizza Hut", 600),
                  _restaurantItemAnim("Starbucks", 800),
                  _restaurantItemAnim("Mami Wata", 1000),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _restaurantItemAnim(String name, int delay) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      delay: Duration(milliseconds: delay),
      child: GestureDetector(
        onTap: () {},
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Column(
            children: [
              Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      orangeFlavor.withOpacity(0.2),
                      violetFlavor.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: orangeFlavor.withOpacity(0.4),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 60,
                  color: orangeFlavor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [orangeFlavor, violetFlavor],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: violetFlavor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SECTION VILLES ANIMÉE ---
  Widget _buildCitySection() {
    return Center(
      child: Column(
        children: [
          FadeInUp(
            child: Text(
              "Nos villes desservies",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: violetFlavor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 50),
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    violetFlavor.withOpacity(0.1),
                    backgroundLight,
                    orangeFlavor.withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: violetFlavor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Wrap(
                spacing: 25,
                runSpacing: 25,
                alignment: WrapAlignment.center,
                children: [
                  _cityItemAnim("Brazzaville", 0),
                  _cityItemAnim("Pointe-Noire", 200),
                  _cityItemAnim("Dolisie", 400),
                  _cityItemAnim("Nkayi", 600),
                  _cityItemAnim("Oyo", 800),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cityItemAnim(String city, int delay) {
    return FadeInRight(
      duration: const Duration(milliseconds: 700),
      delay: Duration(milliseconds: delay),
      child: GestureDetector(
        onTap: () {},
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [backgroundLight, violetFlavor.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: orangeFlavor.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: violetFlavor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  city,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: violetFlavor,
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: orangeFlavor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
