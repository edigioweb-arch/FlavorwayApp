import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/restaurant_subscription_model.dart';
import '../../services/restaurant_service.dart';
import '../../services/restaurant_subscription_service.dart';

class RestaurantDashboardScreen extends StatelessWidget {
  const RestaurantDashboardScreen({super.key});

  static const Color primary = Color(0xFF6B2CF5);
  static const Color primaryDark = Color(0xFF1F1736);
  static const Color background = Color(0xFFFFFCFA);
  static const Color border = Color(0xFFF0E8F4);
  static const Color muted = Color(0xFF8E889C);
  static const Color orange = Color(0xFFFF6B1A);
  static const Color green = Color(0xFF33BB6C);

  @override
  Widget build(BuildContext context) {
    return Consumer2<RestaurantService, RestaurantSubscriptionService>(
      builder: (context, restaurantService, subscriptionService, child) {
        final restaurant = restaurantService.joliCoin;
        final subscription = subscriptionService.subscription;

        if (!subscriptionService.isLoading &&
            subscriptionService.subscription == null &&
            subscriptionService.errorMessage == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context
                  .read<RestaurantSubscriptionService>()
                  .loadCurrentSubscription();
            }
          });
        }

        return Scaffold(
          backgroundColor: background,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final horizontal = width >= 420 ? 28.0 : 20.0;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          14,
                          horizontal,
                          120,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context, restaurant, width),
                            const SizedBox(height: 22),
                            _buildRestaurantCard(restaurant, width),
                            const SizedBox(height: 28),
                            _buildSectionTitle(
                              'Aperçu du jour',
                              trailing: _buildDateChip(),
                            ),
                            const SizedBox(height: 16),
                            _buildStatsGrid(width),
                            const SizedBox(height: 28),
                            _buildSectionTitle('Gestion rapide'),
                            const SizedBox(height: 16),
                            _buildQuickActions(context, width),
                            const SizedBox(height: 18),
                            _buildPremiumCard(subscription, subscriptionService),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          bottomNavigationBar: _buildBottomBar(),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, dynamic restaurant, double width) {
    final avatarSize = width >= 420 ? 60.0 : 56.0;

    return Row(
      children: [
        _circleShell(
          size: 56,
          child: const Icon(Icons.menu_rounded, color: primaryDark, size: 32),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Espace restaurateur',
                style: GoogleFonts.poppins(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: primaryDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: primaryDark,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _circleShell(
              size: 54,
              child: const Icon(
                Icons.notifications_none_rounded,
                color: primaryDark,
                size: 28,
              ),
            ),
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: orange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '3',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Container(
          width: avatarSize,
          height: avatarSize,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: orange, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              restaurant.coverImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFF5EEE6),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: primaryDark,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: primaryDark,
          size: 22,
        ),
      ],
    );
  }

  Widget _buildRestaurantCard(dynamic restaurant, double width) {
    final compact = width < 390;
    final imageWidth = width >= 420 ? 132.0 : (compact ? 104.0 : 112.0);
    final imageHeight = width >= 420 ? 176.0 : (compact ? 144.0 : 152.0);

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: _surface(radius: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset(
                  restaurant.coverImage,
                  width: imageWidth,
                  height: imageHeight,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: imageWidth,
                    height: imageHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2ECE8),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 42,
                      color: primaryDark,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -6,
                top: 12,
                child: _circleShell(
                  size: compact ? 40 : 44,
                  child: const Icon(
                    Icons.edit_outlined,
                    color: primaryDark,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      restaurant.name,
                      style: GoogleFonts.poppins(
                        color: primaryDark,
                        fontSize: compact ? 20 : 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _statusChip(restaurant.isOpen),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Restaurant • BBQ • Fast-food',
                  style: GoogleFonts.poppins(
                    color: muted,
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: compact ? 14 : 18),
                _infoLine(
                  Icons.location_on_outlined,
                  'Brazzaville, Congo',
                ),
                SizedBox(height: compact ? 10 : 12),
                _infoLine(Icons.schedule_rounded, '10h – 23h'),
                SizedBox(height: compact ? 14 : 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6EEFF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.remove_red_eye_outlined,
                        color: primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Voir la fiche client',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: primary,
                            fontSize: compact ? 13 : 14,
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
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: primaryDark,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) const SizedBox(width: 10),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildDateChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _surface(radius: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            color: primaryDark,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            "Aujourd'hui",
            style: GoogleFonts.poppins(
              color: primaryDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryDark,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(double width) {
    final stats = [
      (
        icon: Icons.calendar_today_outlined,
        color: const Color(0xFFA04EFF),
        value: '12',
        label: 'Réservations',
        sublabel: null,
      ),
      (
        icon: Icons.shopping_bag_outlined,
        color: orange,
        value: '86',
        label: 'Visites',
        sublabel: null,
      ),
      (
        icon: Icons.restaurant_menu_outlined,
        color: const Color(0xFF42C777),
        value: '48',
        label: 'Commandes',
        sublabel: null,
      ),
      (
        icon: Icons.star_border_rounded,
        color: const Color(0xFFFFC330),
        value: '4.8',
        label: 'Note moyenne',
        sublabel: '(124 avis)',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .82,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _statCard(
          icon: stat.icon,
          color: stat.color,
          value: stat.value,
          label: stat.label,
          sublabel: stat.sublabel,
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    String? sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: _surface(radius: 22),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: primaryDark,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (sublabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                sublabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: muted,
                  fontSize: 11.5,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const Spacer(),
          _sparkline(color),
        ],
      ),
    );
  }

  Widget _sparkline(Color color) {
    return SizedBox(
      height: 24,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(color),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, double width) {
    final items = [
      (
        icon: Icons.restaurant_menu_outlined,
        color: primary,
        title: 'Menus & plats',
        subtitle: 'Gérez vos menus, plats\net options',
        route: '/edit-menu',
      ),
      (
        icon: Icons.assignment_outlined,
        color: orange,
        title: 'Commandes',
        subtitle: 'Suivez et gérez les\ncommandes',
        route: null,
      ),
      (
        icon: Icons.storefront_outlined,
        color: const Color(0xFF37C978),
        title: 'Informations',
        subtitle: 'Horaires, adresse,\nservices et plus',
        route: '/edit-restaurant',
      ),
      (
        icon: Icons.image_outlined,
        color: const Color(0xFF3B82F6),
        title: 'Photos & galerie',
        subtitle: 'Gérez vos photos\net votre galerie',
        route: '/edit-gallery',
      ),
      (
        icon: Icons.discount_outlined,
        color: const Color(0xFFE91E63),
        title: 'Promotions',
        subtitle: 'Créez et gérez\ndes promotions',
        route: null,
      ),
      (
        icon: Icons.chat_bubble_outline_rounded,
        color: const Color(0xFF23B8B5),
        title: 'Messages clients',
        subtitle: 'Répondez à vos\nclients',
        route: null,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _actionCard(
          icon: item.icon,
          color: item.color,
          title: item.title,
          subtitle: item.subtitle,
          onTap: () {
            if (item.route != null) {
              Navigator.pushNamed(context, item.route!);
            }
          },
        );
      },
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _surface(radius: 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: primaryDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: muted,
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: muted,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard(
    RestaurantSubscriptionModel? subscription,
    RestaurantSubscriptionService subscriptionService,
  ) {
    final isPremium = subscription?.isPremium == true;
    final title = isPremium ? 'Premium actif ✨' : 'Passez à Premium ✨';
    final description = isPremium
        ? 'Plan ${subscription?.plan?.name ?? 'Premium'} actif'
            '${subscription?.endsAt != null ? '\nExpire le ${_formatDate(subscription!.endsAt!)}' : ''}'
        : 'Débloquez plus de fonctionnalités\net boostez votre visibilité';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: _surface(radius: 22),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6D8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFD7A42D),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: primaryDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    color: muted,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: orange, width: 1.3),
            ),
            child: subscriptionService.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isPremium ? 'Gérer' : 'Découvrir',
                    style: GoogleFonts.poppins(
                      color: orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Widget _buildBottomBar() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Container(
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _bottomItem(Icons.grid_view_rounded, 'Accueil', true),
            _bottomItem(Icons.assignment_outlined, 'Commandes', false),
            _centerAddButton(),
            _bottomItem(Icons.chat_bubble_outline_rounded, 'Messages', false),
            _bottomItem(Icons.person_outline_rounded, 'Profil', false),
          ],
        ),
      ),
    );
  }

  Widget _bottomItem(IconData icon, String label, bool active) {
    return SizedBox(
      width: 58,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: active ? primary : muted,
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: active ? primary : muted,
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          active
              ? Container(
                  width: 34,
                  height: 3,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                )
              : const SizedBox(height: 3),
        ],
      ),
    );
  }

  Widget _centerAddButton() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB34AFF), primary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
    );
  }

  Widget _statusChip(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8EE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isOpen ? 'Ouvert' : 'Fermé',
            style: GoogleFonts.poppins(
              color: green,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 24),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: muted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleShell({
    required double size,
    required Widget child,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  BoxDecoration _surface({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.035),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final points = <Offset>[
      Offset(0, size.height * .82),
      Offset(size.width * .10, size.height * .58),
      Offset(size.width * .20, size.height * .67),
      Offset(size.width * .30, size.height * .46),
      Offset(size.width * .40, size.height * .71),
      Offset(size.width * .52, size.height * .56),
      Offset(size.width * .63, size.height * .65),
      Offset(size.width * .75, size.height * .40),
      Offset(size.width * .87, size.height * .60),
      Offset(size.width, size.height * .28),
    ];

    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
