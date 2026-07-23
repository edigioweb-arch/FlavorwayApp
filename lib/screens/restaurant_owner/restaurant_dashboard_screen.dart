import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/restaurant_service.dart';

class RestaurantDashboardScreen extends StatelessWidget {
  const RestaurantDashboardScreen({super.key});

  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color violetDark = Color(0xFF24102D);
  static const Color background = Color(0xFFFAF8F6);
  static const Color cardBorder = Color(0xFFECE5DF);
  static const Color mutedText = Color(0xFF8A7F7A);
  static const Color green = Color(0xFF1F9D55);

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantService>(
      builder: (context, restaurantService, child) {
        final restaurant = restaurantService.joliCoin;

        return Scaffold(
          backgroundColor: background,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _topBar(context),
                        const SizedBox(height: 18),
                        _restaurantCard(restaurant),
                        const SizedBox(height: 20),
                        _quickStatsRow(),
                        const SizedBox(height: 24),
                        _sectionTitle('Gestion du restaurant'),
                        const SizedBox(height: 12),
                        _primaryActions(context),
                        const SizedBox(height: 24),
                        _sectionTitle('Activité'),
                        const SizedBox(height: 12),
                        _dailyList(context),
                        const SizedBox(height: 96),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _bottomBar(),
        );
      },
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        _circleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            }
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Espace restaurateur',
                style: GoogleFonts.poppins(
                  color: mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Joli Coin',
                style: GoogleFonts.poppins(
                  color: violetDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _circleButton(
          icon: Icons.notifications_none_rounded,
          hasDot: true,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _restaurantCard(dynamic restaurant) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _surface(radius: 26),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              restaurant.coverImage,
              width: 96,
              height: 106,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 96,
                height: 106,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: violetFlavor,
                  size: 34,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: violetDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _openBadge(restaurant.isOpen),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  restaurant.type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                _miniInfo(Icons.location_on_outlined, restaurant.address),
                const SizedBox(height: 6),
                _miniInfo(Icons.schedule_rounded, restaurant.openingHours),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Prévisualiser la fiche client',
                    style: GoogleFonts.poppins(
                      color: orangeFlavor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _openBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFEAF8EE) : const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(90),
      ),
      child: Text(
        isOpen ? 'Ouvert' : 'Fermé',
        style: GoogleFonts.poppins(
          color: isOpen ? green : Colors.redAccent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: mutedText, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickStatsRow() {
    return Row(
      children: [
        Expanded(child: _smallStatCard('12', 'Réservations')),
        const SizedBox(width: 10),
        Expanded(child: _smallStatCard('86', 'Visites')),
        const SizedBox(width: 10),
        Expanded(child: _smallStatCard('4.8', 'Note')),
      ],
    );
  }

  Widget _smallStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _surface(radius: 20),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              color: violetDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryActions(BuildContext context) {
    return Column(
      children: [
        _actionTile(
          icon: Icons.restaurant_menu_rounded,
          title: 'Menus et plats',
          subtitle: 'Ajouter, modifier ou retirer des plats',
          color: orangeFlavor,
          onTap: () => Navigator.pushNamed(context, '/edit-menu'),
        ),
        _actionTile(
          icon: Icons.storefront_rounded,
          title: 'Informations restaurant',
          subtitle: 'Adresse, téléphone, horaires et services',
          color: violetFlavor,
          onTap: () => Navigator.pushNamed(context, '/edit-restaurant'),
        ),
        _actionTile(
          icon: Icons.photo_library_rounded,
          title: 'Photos et galerie',
          subtitle: 'Couverture, menu image et galerie',
          color: const Color(0xFF2E9E64),
          onTap: () => Navigator.pushNamed(context, '/edit-gallery'),
        ),
        _actionTile(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Messages clients',
          subtitle: 'Lire et répondre aux demandes',
          color: const Color(0xFF3578D4),
          onTap: () => _soon(context, 'Messagerie client bientôt disponible'),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(14),
        decoration: _surface(radius: 22),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 23),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: mutedText,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyList(BuildContext context) {
    return Column(
      children: [
        _alertTile(
          icon: Icons.event_available_rounded,
          title: '3 réservations à confirmer',
          subtitle: 'Vérifiez les demandes en attente',
          onTap: () => _soon(context, 'Réservations bientôt disponibles'),
        ),
        _alertTile(
          icon: Icons.mark_chat_unread_rounded,
          title: '2 messages non lus',
          subtitle: 'Répondez aux clients rapidement',
          onTap: () => _soon(context, 'Messagerie bientôt disponible'),
        ),
        _alertTile(
          icon: Icons.delivery_dining_rounded,
          title: 'Livraisons',
          subtitle: 'Module bientôt disponible',
          onTap: () => _soon(context, 'Livraisons bientôt disponibles'),
        ),
      ],
    );
  }

  Widget _alertTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: orangeFlavor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: orangeFlavor.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: orangeFlavor, size: 23),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: violetDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(Icons.dashboard_rounded, 'Accueil', true),
          _navItem(Icons.restaurant_menu_rounded, 'Menus', false),
          _addButton(),
          _navItem(Icons.chat_bubble_outline_rounded, 'Messages', false),
          _navItem(Icons.person_outline_rounded, 'Profil', false),
        ],
      ),
    );
  }

  Widget _addButton() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: orangeFlavor,
        borderRadius: BorderRadius.circular(90),
        boxShadow: [
          BoxShadow(
            color: orangeFlavor.withOpacity(0.24),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: active ? orangeFlavor : mutedText,
          size: 22,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: active ? orangeFlavor : mutedText,
            fontSize: 10,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasDot = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: _surface(radius: 90),
            child: Icon(icon, color: violetDark, size: 20),
          ),
          if (hasDot)
            Positioned(
              right: 2,
              top: 1,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: orangeFlavor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: violetDark,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  BoxDecoration _surface({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.035),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }

  void _soon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
