import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class FlavorWayHome extends StatelessWidget {
  const FlavorWayHome({super.key});

  @override
  Widget build(BuildContext context) {
    const Color orangeChaud = Color(0xFFF36A2D);
    const Color violetProfond = Color(0xFF4B1F5C);
    const Color vertGlovo = Color(0xFF00A082);
    const Color jauneHero = Color(0xFFFFC244);
    const Color grisFond = Color(0xFFF8F9FA);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 900;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildResponsiveAppBar(context, vertGlovo, isMobile),
          drawer: isMobile ? _buildDrawer(context) : null,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroSection(jauneHero, violetProfond, isMobile),
                _buildSection(
                  title: 'Meilleurs restaurants et plus',
                  isMobile: isMobile,
                  child: Wrap(
                    spacing: 30,
                    runSpacing: 30,
                    alignment: WrapAlignment.center,
                    children: [
                      _circularCard('McDonald\'s', Icons.fastfood, orangeChaud),
                      _circularCard(
                        'Tacos de Lyon',
                        Icons.restaurant,
                        orangeChaud,
                      ),
                      _circularCard('KFC', Icons.restaurant_menu, orangeChaud),
                      _circularCard(
                        'Burger King',
                        Icons.lunch_dining,
                        orangeChaud,
                      ),
                      _circularCard(
                        'Pizza Hut',
                        Icons.local_pizza,
                        orangeChaud,
                      ),
                      _circularCard('Starbucks', Icons.coffee, orangeChaud),
                    ],
                  ),
                ),
                Container(
                  color: grisFond,
                  width: double.infinity,
                  child: _buildSection(
                    title: 'Faites livrer tout ce que vous voulez',
                    isMobile: isMobile,
                    child: Flex(
                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _serviceDetailCard(
                          Icons.restaurant,
                          'Restaurants',
                          'Vos plats préférés en un clic',
                          violetProfond,
                        ),
                        if (isMobile) const SizedBox(height: 40),
                        _serviceDetailCard(
                          Icons.delivery_dining,
                          'Livraison rapide',
                          'Notre rapidité est notre fierté',
                          violetProfond,
                        ),
                        if (isMobile) const SizedBox(height: 40),
                        _serviceDetailCard(
                          Icons.shopping_basket,
                          'Courses et bien plus',
                          'Supermarchés, pharmacies, etc.',
                          violetProfond,
                        ),
                      ],
                    ),
                  ),
                ),
                _buildTagsSection('Meilleures villes', [
                  'Casablanca',
                  'Rabat',
                  'Marrakech',
                  'Tanger',
                  'Agadir',
                  'Fès',
                ], isMobile),
                _buildTagsSection('Catégories populaires', [
                  'Pizza',
                  'Fleurs',
                  'Livres',
                  'Asiatique',
                  'Marocain',
                  'Petit-déjeuner',
                ], isMobile),
                _buildSection(
                  title: 'Opportunités',
                  isMobile: isMobile,
                  child: Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _opportunityCard(
                        'Devenir coursier',
                        Icons.pedal_bike,
                        vertGlovo,
                      ),
                      if (isMobile) const SizedBox(height: 30),
                      _opportunityCard(
                        'Devenir partenaire',
                        Icons.storefront,
                        vertGlovo,
                      ),
                      if (isMobile) const SizedBox(height: 30),
                      _opportunityCard('Emploi', Icons.work_outline, vertGlovo),
                    ],
                  ),
                ),
                _buildFooter(violetProfond, isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildResponsiveAppBar(
    BuildContext context,
    Color primary,
    bool isMobile,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      iconTheme: const IconThemeData(color: Colors.black),
      title: Row(
        children: [
          Image.asset('../image/logo.jpeg', height: 45),
          if (!isMobile) ...[
            const SizedBox(width: 30),
            _navLink('Restaurants'),
            _navLink('À propos'),
          ],
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25),
            ),
            child: const Text(
              'Connexion',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) => Drawer(
    child: ListView(
      children: [
        const DrawerHeader(
          child: Center(
            child: Text(
              'FlavorWay',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        ListTile(title: const Text('Restaurants'), onTap: () {}),
        ListTile(title: const Text('À propos'), onTap: () {}),
        ListTile(title: const Text('Devenir coursier'), onTap: () {}),
      ],
    ),
  );

  Widget _buildHeroSection(Color bg, Color textCol, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 60 : 100,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(0)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              FadeInDown(
                child: Text(
                  'On vous livre plus\nque des repas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 36 : 56,
                    fontWeight: FontWeight.w900,
                    color: textCol,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              FadeInUp(child: _buildHeroSearch(isMobile)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSearch(bool isMobile) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Où voulez-vous être livré ?",
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.location_on, color: Colors.redAccent),
                border: InputBorder.none,
              ),
            ),
          ),
          if (!isMobile)
            BounceInRight(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text("Utiliser ma position"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  side: const BorderSide(color: Colors.black12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    required bool isMobile,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 60,
        horizontal: isMobile ? 20 : 40,
      ),
      child: Column(
        children: [
          FadeInUp(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4B1F5C),
              ),
            ),
          ),
          const SizedBox(height: 50),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _circularCard(String name, IconData icon, Color color) {
    return BounceInUp(
      child: Column(
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 12),
          Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _serviceDetailCard(
    IconData icon,
    String title,
    String desc,
    Color color,
  ) {
    return BounceInUp(
      child: SizedBox(
        width: 280,
        child: Column(
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(String title, List<String> tags, bool isMobile) {
    return _buildSection(
      title: title,
      isMobile: isMobile,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: tags
            .map(
              (tag) => BounceInUp(
                child: ActionChip(
                  label: Text(tag, style: GoogleFonts.poppins()),
                  onPressed: () {},
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _opportunityCard(String title, IconData icon, Color color) {
    return BounceInUp(
      child: Column(
        children: [
          Icon(icon, size: 50, color: color),
          const SizedBox(height: 15),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: StadiumBorder(),
            ),
            child: const Text(
              'Inscription',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color bg, bool isMobile) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          if (!isMobile)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _footerCol('Opportunités', [
                  'Emploi',
                  'Partenaires',
                  'Coursiers',
                ]),
                _footerCol('Liens utiles', ['À propos', 'FAQ', 'Blog']),
                _footerCol('Suivez-nous', ['Instagram', 'Twitter', 'Facebook']),
              ],
            ),
          const Divider(color: Colors.white10, height: 60),
          const Text(
            '© 2024 FlavorWay - Fait avec ❤️ pour le Congo',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _footerCol(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 20),
        ...links.map(
          (l) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(l, style: const TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  Widget _navLink(String title) => TextButton(
    onPressed: () {},
    child: Text(
      title,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
