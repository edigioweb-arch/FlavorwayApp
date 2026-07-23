import 'package:flutter/material.dart';

class FlavorWayHome extends StatelessWidget {
  const FlavorWayHome({super.key});

  @override
  Widget build(BuildContext context) {
    const Color orangeChaud = Color(0xFFF36A2D);
    const Color violetProfond = Color(0xFF4B1F5C);
    const Color vertBackground = Color(0xFF8DAE42);
    const Color jauneHero = Color(0xFFFFC244);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildWebAppBar(context, vertBackground),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- SECTION HERO ---
            _buildHeroSection(jauneHero, violetProfond, orangeChaud),

            // --- SECTION RESTAURANTS ---
            _buildSectionContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meilleurs restaurants au Congo',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: violetProfond,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    spacing: 30,
                    runSpacing: 30,
                    children: [
                      _restaurantCard(
                        'McDonald\'s',
                        Icons.fastfood,
                        orangeChaud,
                      ),
                      _restaurantCard(
                        'Tacos de Lyon',
                        Icons.restaurant,
                        orangeChaud,
                      ),
                      _restaurantCard(
                        'KFC',
                        Icons.restaurant_menu,
                        orangeChaud,
                      ),
                      _restaurantCard(
                        'Burger King',
                        Icons.lunch_dining,
                        orangeChaud,
                      ),
                      _restaurantCard(
                        'Pizza Hut',
                        Icons.local_pizza,
                        orangeChaud,
                      ),
                      _restaurantCard('Starbucks', Icons.coffee, orangeChaud),
                    ],
                  ),
                ],
              ),
            ),

            // --- SECTION SERVICES ---
            Container(
              color: const Color(0xFFF8F9FA),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: _buildSectionContainer(
                child: Column(
                  children: [
                    const Text(
                      'Faites livrer tout ce que vous voulez',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: violetProfond,
                      ),
                    ),
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _serviceWebCard(
                          Icons.restaurant,
                          'Restaurants',
                          'Vos plats préférés en un clic',
                          violetProfond,
                        ),
                        _serviceWebCard(
                          Icons.speed,
                          'Livraison Rapide',
                          'En moins de 30 minutes',
                          violetProfond,
                        ),
                        _serviceWebCard(
                          Icons.shopping_basket,
                          'Courses',
                          'Supermarchés et épiceries',
                          violetProfond,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- SECTION FOOTER ---
            _buildFooter(violetProfond),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE STRUCTURE ---

  PreferredSizeWidget _buildWebAppBar(BuildContext context, Color primary) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      title: Row(
        children: [
          Image.asset('image/logo.jpeg', height: 50),
          const SizedBox(width: 20),
          _navLink('Restaurants'),
          _navLink('À propos'),
          _navLink('Devenir coursier'),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Se connecter',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(Color bg, Color textCol, Color btnCol) {
    return Container(
      width: double.infinity,
      height: 450,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(100)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'On vous livre plus\nque des repas',
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Où voulez-vous être livré ?",
                          border: InputBorder.none,
                          prefixIcon: const Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Icon(
                    Icons.delivery_dining,
                    size: 300,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: child,
      ),
    );
  }

  Widget _restaurantCard(String name, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, size: 50, color: color),
          ),
          const SizedBox(height: 15),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _serviceWebCard(
    IconData icon,
    String title,
    String desc,
    Color color,
  ) {
    return SizedBox(
      width: 320,
      child: Column(
        children: [
          Icon(icon, size: 60, color: color),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _navLink(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: TextButton(
        onPressed: () {},
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(Color bg) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          _buildSectionContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _footerColumn('FlavorWay', ['À propos', 'Carrières', 'Blog']),
                _footerColumn('Aide', ['FAQ', 'Contactez-nous', 'Sécurité']),
                _footerColumn('Légal', ['CGU', 'Confidentialité', 'Cookies']),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Suivez-nous',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _socialIcon(Icons.facebook),
                        const SizedBox(width: 15),
                        _socialIcon(Icons.camera_alt),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          const SizedBox(height: 20),
          const Text(
            '© 2024 FlavorWay Congo - Tous droits réservés',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _footerColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 20),
        ...links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(link, style: const TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
