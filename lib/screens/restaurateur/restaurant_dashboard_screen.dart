import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/restaurant_workspace_service.dart';
import '../../services/user_auth_service.dart';
import 'restaurant_orders_screen.dart';
import 'restaurant_reservations_screen.dart';

class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key, this.workspace});
  final RestaurantWorkspaceService? workspace;

  @override
  State<RestaurantDashboardScreen> createState() =>
      _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  RestaurantWorkspaceService get _workspace =>
      widget.workspace ?? RestaurantWorkspaceService.instance;
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _subscription;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _workspace.fetchProfile();
      final data = profile['status'] == 'active'
          ? await _workspace.fetchDashboard()
          : <String, dynamic>{'restaurant': profile};
      final subscription = profile['status'] == 'active'
          ? await _workspace.fetchSubscription()
          : null;
      if (!mounted) return;
      setState(() {
        _dashboard = data;
        _subscription = subscription;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger le dashboard restaurateur.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = Map<String, dynamic>.from(
        (_dashboard?['restaurant'] as Map?) ?? const {});
    final stats =
        Map<String, dynamic>.from((_dashboard?['stats'] as Map?) ?? const {});
    final subscription = _subscription;
    final plan = subscription?['plan'] as Map?;
    final recentOrders = ((_dashboard?['recent_orders'] as List?) ?? const [])
        .whereType<Map>()
        .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        actions: [
          IconButton(
              tooltip: 'Déconnexion',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await UserAuthService.instance.signOut();
                if (context.mounted)
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (_) => false);
              })
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          restaurant['name']?.toString() ?? 'Espace restaurant',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _panel(
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                        onPressed: _load, child: const Text('Réessayer')),
                  ],
                ),
              )
            else if (restaurant['status'] != 'active')
              _panel(
                  child: Text(
                      'Restaurant ${restaurant['status'] ?? 'en attente'}. Les outils de gestion seront accessibles après activation.'))
            else ...[
              _panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant['name']?.toString() ?? 'Restaurant',
                            style: GoogleFonts.inter(
                                fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                        ),
                        _statusChip(
                            restaurant['is_open'] == true ? 'Ouvert' : 'Fermé'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        restaurant['cuisine_type'],
                        restaurant['city'],
                        restaurant['opening_hours'],
                      ]
                          .whereType<String>()
                          .where((value) => value.trim().isNotEmpty)
                          .join(' • '),
                      style: GoogleFonts.inter(color: const Color(0xFF6F7390)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subscription == null
                          ? 'Aucun abonnement associé'
                          : 'Abonnement : ${plan?['name'] ?? 'Plan indisponible'} • ${subscription['status']}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _panel(
                  child: Column(children: [
                for (final entry in const [
                  ('Menus & plats', '/edit-menu'),
                  ('Informations restaurant', '/edit-restaurant'),
                  ('Photos & galerie', '/edit-gallery')
                ])
                  ListTile(
                      title: Text(entry.$1),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.pushNamed(context, entry.$2);
                        if (mounted) _load();
                      }),
                ListTile(
                    title: const Text('Commandes'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RestaurantOrdersScreen()))),
                ListTile(
                    title: const Text('Réservations'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RestaurantReservationsScreen(
                                workspace: _workspace)))),
                const ListTile(
                    title: Text('Messages, avis et promotions'),
                    subtitle: Text('Modules de gestion non disponibles')),
              ])),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _statCard(
                      'Commandes du jour', '${stats['orders_today'] ?? 0}'),
                  _statCard(
                      'Commandes actives', '${stats['orders_pending'] ?? 0}'),
                  _statCard(
                      'Réservations', '${stats['reservations_total'] ?? 0}'),
                  _statCard('Note moyenne',
                      stats['average_rating']?.toString() ?? 'Non disponible'),
                  _statCard('Nombre d’avis',
                      stats['reviews_count']?.toString() ?? 'Non disponible'),
                  _statCard('CA encaissé du jour',
                      '${((stats['revenue_today'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} XAF'),
                ],
              ),
              const SizedBox(height: 14),
              _panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Commandes récentes',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    if (recentOrders.isEmpty)
                      Text(
                        'Aucune commande réelle disponible pour le moment.',
                        style:
                            GoogleFonts.inter(color: const Color(0xFF6F7390)),
                      )
                    else
                      ...recentOrders.map((order) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (order['order_number'] ?? '').toString(),
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  '${((order['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} ${(order['currency'] ?? 'XAF')}',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE6F6)),
      ),
      child: child,
    );
  }

  Widget _statCard(String label, String value) {
    return SizedBox(
      width: 160,
      child: _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: const Color(0xFF6F7390), fontSize: 12)),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label) {
    final open = label.toLowerCase() == 'ouvert';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (open ? Colors.green : Colors.red).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: open ? Colors.green : Colors.red,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
