import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/order_service.dart';

class RestaurantOrdersScreen extends StatefulWidget {
  const RestaurantOrdersScreen({super.key, this.orderService});
  final OrderService? orderService;

  @override
  State<RestaurantOrdersScreen> createState() => _RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState extends State<RestaurantOrdersScreen> {
  OrderService get _orderService =>
      widget.orderService ?? OrderService.instance;
  Timer? _polling;
  bool _acting = false;
  int _page = 1;
  int _requestVersion = 0;
  List<OrderModel> _orders = const [];
  String _filter = 'active';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _polling = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_acting && !_loading) _loadOrders(silent: true);
    });
  }

  @override
  void dispose() {
    _polling?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders({bool silent = false}) async {
    final version = ++_requestVersion;
    setState(() {
      if (!silent) _loading = true;
      _error = null;
    });

    try {
      final orders = await _orderService.fetchRestaurantOrders(
          status: _filter, page: _page);
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les commandes du restaurant.';
      });
    }
  }

  Future<void> _runAction(OrderModel order, String action,
      {String? reason}) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      if (action == 'cash-collected') {
        await _orderService.confirmRestaurantCash(order.orderNumber);
      } else {
        await _orderService.transitionRestaurantOrder(
          orderNumber: order.orderNumber,
          action: action,
          reason: reason,
        );
      }
      if (mounted) await _loadOrders();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Action refusée. Rechargez la commande avant de réessayer.')));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  List<_OrderAction> _actionsFor(OrderModel order) {
    if (order.canCollectCash)
      return [
        _OrderAction('Confirmer l’encaissement', 'cash-collected',
            const Color(0xFF2E8B57))
      ];
    switch (order.status) {
      case 'pending_payment':
        return [
          _OrderAction('Refuser', 'reject', Colors.redAccent, needsReason: true)
        ];
      case 'confirmed':
        return [
          _OrderAction('Démarrer', 'confirm', const Color(0xFF2E8B57)),
          _OrderAction('Refuser', 'reject', Colors.redAccent,
              needsReason: true),
        ];
      case 'preparing':
        return [_OrderAction('Prête', 'ready', const Color(0xFFF36A2D))];
      default:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        title: Text(
          'Commandes restaurant',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final option in const [
                  ('active', 'Actives'),
                  ('history', 'Historique'),
                  ('confirmed', 'Nouvelles'),
                  ('preparing', 'Préparation'),
                  ('ready', 'Prêtes'),
                  ('cancelled', 'Annulées'),
                ])
                  ChoiceChip(
                    label: Text(option.$2),
                    selected: _filter == option.$1,
                    onSelected: (_) {
                      setState(() {
                        _filter = option.$1;
                        _page = 1;
                      });
                      _loadOrders();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ))
            else if (_error != null)
              _errorState()
            else if (_orders.isEmpty)
              _emptyState()
            else
              ..._orders.map(_orderCard),
            if (!_loading &&
                _error == null &&
                (_page > 1 || _orders.length == 20))
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                TextButton(
                    onPressed: _page > 1
                        ? () {
                            _page--;
                            _loadOrders();
                          }
                        : null,
                    child: const Text('Précédent')),
                Text('Page $_page'),
                TextButton(
                    onPressed: _orders.length == 20
                        ? () {
                            _page++;
                            _loadOrders();
                          }
                        : null,
                    child: const Text('Suivant')),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _orderCard(OrderModel order) {
    final actions = _actionsFor(order);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE6F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              _statusChip(order.displayStatus),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${order.items.length} article(s) • ${order.total.toStringAsFixed(0)} ${order.currency}',
            style:
                GoogleFonts.inter(color: const Color(0xFF6F7390), fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            order.deliveryAddress.isEmpty
                ? 'Adresse indisponible'
                : order.deliveryAddress,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          ExpansionTile(title: const Text('Détail'), children: [
            for (final item in order.items)
              ListTile(
                  title: Text('${item.quantity} × ${item.name}'),
                  subtitle: Text(item.options
                      .map((option) =>
                          option['option_value'] ??
                          option['value_name'] ??
                          option['name'] ??
                          '')
                      .join(', '))),
            if (order.rejectionReason.isNotEmpty)
              ListTile(
                  title: Text('Motif du rejet : ${order.rejectionReason}')),
            if (order.note.isNotEmpty) ListTile(title: Text(order.note)),
            ListTile(title: Text(order.paymentLabel)),
            ListTile(
                title: Text(
                    'Livreur : ${order.courierName.isEmpty ? 'Non assigné' : order.courierName}')),
            for (final event in order.timeline)
              ListTile(
                  title: Text(event.status),
                  subtitle: Text(event.timestamp.toLocal().toString())),
            ListTile(
                title: Text(
                    'Frais de livraison : ${order.deliveryFee} ${order.currency}')),
            if (order.cashDue > 0)
              ListTile(
                  title: Text(
                      'Cash à encaisser : ${order.cashDue} ${order.currency} (total client, livraison incluse)')),
          ]),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions
                  .map(
                    (action) => ElevatedButton(
                      onPressed: _acting
                          ? null
                          : () async {
                              String? reason;
                              if (action.needsReason) {
                                reason = await _askReason();
                                if (reason == null || reason.trim().isEmpty)
                                  return;
                              }
                              await _runAction(order, action.action,
                                  reason: reason);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: action.color,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(action.label),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  Future<String?> _askReason() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Motif du refus'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Produit indisponible'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EDFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: const Color(0xFF6D37A1),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _emptyState() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFECE6F6)),
        ),
        child: Text(
          'Aucune commande pour ce filtre.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      );

  Widget _errorState() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF2D3D3)),
        ),
        child: Column(
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
                onPressed: _loadOrders, child: const Text('Réessayer')),
          ],
        ),
      );
}

class _OrderAction {
  const _OrderAction(this.label, this.action, this.color,
      {this.needsReason = false});

  final String label;
  final String action;
  final Color color;
  final bool needsReason;
}
