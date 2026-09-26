import 'support_tickets_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../widgets/order_payment_action.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({
    super.key,
    required this.orderReference,
    this.orderService,
    this.paymentService,
  });

  final String orderReference;
  final OrderService? orderService;
  final PaymentService? paymentService;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);

  OrderService get _orderService =>
      widget.orderService ?? OrderService.instance;

  OrderModel? _order;
  Timer? _pollingTimer;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder(initial: true);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrder({bool initial = false}) async {
    if (widget.orderReference.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Référence de commande manquante.';
      });
      return;
    }

    if (initial) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _refreshing = true;
        _error = null;
      });
    }

    try {
      final order = await _orderService.fetchOrderDetail(widget.orderReference);

      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
        _refreshing = false;
        _error = order == null ? 'Commande introuvable.' : null;
      });

      _restartPollingIfNeeded();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = 'Impossible de charger le suivi de commande.';
      });
    }
  }

  void _restartPollingIfNeeded() {
    _pollingTimer?.cancel();

    if (_order == null ||
        (_order!.isTerminal &&
            !_order!.canRetryPayment &&
            !(_order!.paymentMethod == 'cash' &&
                _order!.status == 'delivered' &&
                const ['unpaid', 'pending', 'failed']
                    .contains(_order!.paymentStatus)))) {
      return;
    }

    _pollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _loadOrder();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FB),
      appBar: AppBar(
        actions: [
          IconButton(
              tooltip: 'Ouvrir un ticket',
              icon: const Icon(Icons.support_agent),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SupportTicketsScreen(
                          orderReference: widget.orderReference))))
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Suivi de commande',
          style: GoogleFonts.inter(
            color: const Color(0xFF252853),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: () => _loadOrder(),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_refreshing)
                        const LinearProgressIndicator(minHeight: 3),
                      _buildSummaryCard(_order!),
                      OrderPaymentAction(
                          order: _order!,
                          paymentService: widget.paymentService,
                          onRefresh: () => _loadOrder()),
                      const SizedBox(height: 16),
                      _buildTotalsCard(_order!),
                      const SizedBox(height: 16),
                      _buildItemsCard(_order!),
                      const SizedBox(height: 16),
                      _buildTimelineCard(_order!),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Erreur inconnue.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => _loadOrder(initial: true),
              style: ElevatedButton.styleFrom(backgroundColor: violetFlavor),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(OrderModel order) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF252853),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusChip(order.displayStatus, _statusColor(order.status)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.restaurantName,
            style: GoogleFonts.inter(
              color: const Color(0xFF4D5072),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            runSpacing: 8,
            spacing: 12,
            children: [
              _meta('Paiement', order.paymentLabel),
              _meta(
                  'Livraison',
                  order.deliveryMode == 'restaurant'
                      ? 'Restaurant'
                      : (order.deliveryZoneName.isNotEmpty
                          ? order.deliveryZoneName
                          : 'FlavorWay')),
              _meta('Adresse',
                  order.deliveryAddress.isEmpty ? '-' : order.deliveryAddress),
              _meta('Date', _formatDate(order.createdAt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(OrderModel order) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Montants',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _amountRow('Sous-total', order.subtotal, order.currency),
          _amountRow('Frais de livraison', order.deliveryFee, order.currency),
          if (order.discountTotal > 0)
            _amountRow('Réduction', -order.discountTotal, order.currency),
          const Divider(height: 20),
          _amountRow('Total', order.total, order.currency, emphasize: true),
        ],
      ),
    );
  }

  Widget _buildItemsCard(OrderModel order) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produits',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.only(bottom: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF0EBF8))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity} × ${item.name}',
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${item.lineTotal.toStringAsFixed(0)} ${order.currency}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    if (item.options.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ...item.options.map((option) => Text(
                            '${option['option_name']}: ${option['option_value']}',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6F7390),
                              fontSize: 12,
                            ),
                          )),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(OrderModel order) {
    final visibleTimeline = order.timeline
        .where((step) => step.updatedBy != 'assignment')
        .toList(growable: false);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historique',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (visibleTimeline.isEmpty)
            Text(
              'Aucun historique disponible pour cette commande.',
              style: GoogleFonts.inter(
                  color: const Color(0xFF6F7390), fontSize: 13),
            )
          else
            ...visibleTimeline.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(step.status),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _humanStatus(step.status),
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatDate(step.timestamp)} • ${step.updatedBy}',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF6F7390),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
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

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _meta(String label, String value) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF6F7390),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.inter(
              color: const Color(0xFF252853),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double value, String currency,
      {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF4D5072),
                fontSize: emphasize ? 14 : 13,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(0)} $currency',
            style: GoogleFonts.inter(
              color: emphasize ? violetFlavor : const Color(0xFF252853),
              fontSize: emphasize ? 15 : 13,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
      case 'payment_failed':
        return Colors.red;
      case 'preparing':
      case 'ready':
      case 'picked_up':
      case 'on_the_way':
        return orangeFlavor;
      default:
        return violetFlavor;
    }
  }

  String _humanStatus(String status) {
    switch (status) {
      case 'pending_payment':
        return 'Paiement en attente';
      case 'confirmed':
        return 'Commande confirmée';
      case 'preparing':
        return 'Préparation en cours';
      case 'ready':
        return 'Commande prête';
      case 'picked_up':
        return 'Commande récupérée';
      case 'on_the_way':
        return 'Commande en livraison';
      case 'delivered':
        return 'Commande livrée';
      case 'cancelled':
        return 'Commande annulée';
      case 'payment_failed':
        return 'Paiement échoué';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}
