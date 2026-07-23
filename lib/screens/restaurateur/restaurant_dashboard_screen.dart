import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color orangeFlavor = Color(0xFFF36A2D);
const Color violetFlavor = Color(0xFF4B1F5C);
const Color softBg = Color(0xFFF8F4FA);
const Color violetDark = Color(0xFF2A0D35);

class RestaurantDashboardScreen extends StatelessWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                decoration: const BoxDecoration(
                  color: violetFlavor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(90),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: orangeFlavor,
                            borderRadius: BorderRadius.circular(90),
                          ),
                          child: Text(
                            'Ouvert',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Tableau de bord',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Joli Coin Restaurant',
                      style: GoogleFonts.poppins(
                        color: orangeFlavor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gérez vos menus, commandes, horaires, photos et échanges clients.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '15 500 FCFA',
                            'Revenus aujourd’hui',
                            Icons.trending_up_rounded,
                            orangeFlavor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '28',
                            'Commandes',
                            Icons.receipt_long_rounded,
                            violetFlavor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '124',
                            'Clients',
                            Icons.people_alt_rounded,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '4.7',
                            'Note moyenne',
                            Icons.star_rounded,
                            Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Gestion du restaurant',
                      style: GoogleFonts.poppins(
                        color: violetDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.02,
                      children: [
                        _buildActionCard(
                          'Menus',
                          'Modifier plats & prix',
                          Icons.restaurant_menu_rounded,
                          orangeFlavor,
                          () {},
                        ),
                        _buildActionCard(
                          'Horaires',
                          'Ouverture restaurant',
                          Icons.access_time_rounded,
                          Colors.green,
                          () {},
                        ),
                        _buildActionCard(
                          'Photos',
                          'Galerie & cover',
                          Icons.photo_library_rounded,
                          Colors.purple,
                          () {},
                        ),
                        _buildActionCard(
                          'Commandes',
                          'Suivi des commandes',
                          Icons.delivery_dining_rounded,
                          Colors.blue,
                          () {},
                        ),
                        _buildActionCard(
                          'Messages',
                          'Discussion clients',
                          Icons.chat_bubble_rounded,
                          Colors.teal,
                          () {},
                        ),
                        _buildActionCard(
                          'Support',
                          'Service client FlavorWay',
                          Icons.support_agent_rounded,
                          violetFlavor,
                          () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Activité récente',
                      style: GoogleFonts.poppins(
                        color: violetDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _activityCard(
                      'Nouvelle commande reçue',
                      'Table 4 • Poulet Mayo • il y a 2 min',
                      Icons.receipt_long_rounded,
                    ),
                    _activityCard(
                      'Nouveau message client',
                      'Question sur la livraison • il y a 10 min',
                      Icons.chat_rounded,
                    ),
                    _activityCard(
                      'Réservation confirmée',
                      '2 personnes • 20h30',
                      Icons.event_available_rounded,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String title,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(90),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 18),
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
            title,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(90),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: violetDark,
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
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityCard(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: orangeFlavor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(90),
            ),
            child: Icon(icon, color: orangeFlavor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: violetDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
