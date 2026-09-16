import 'dart:math';
import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../services/api_client.dart';

class OrderPaymentAction extends StatefulWidget {
  const OrderPaymentAction(
      {super.key,
      required this.order,
      required this.onRefresh,
      this.paymentService});
  final OrderModel order;
  final Future<void> Function() onRefresh;
  final PaymentService? paymentService;
  @override
  State<OrderPaymentAction> createState() => _OrderPaymentActionState();
}

class _OrderPaymentActionState extends State<OrderPaymentAction> {
  final phone = TextEditingController();
  bool busy = false;
  String? key, message;
  @override
  void didUpdateWidget(covariant OrderPaymentAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A server-confirmed failure permits a new attempt. Network uncertainty
    // keeps the existing key so repeating the request cannot charge twice.
    if (oldWidget.order.orderNumber != widget.order.orderNumber ||
        (oldWidget.order.paymentStatus != 'failed' &&
            widget.order.paymentStatus == 'failed')) {
      key = null;
      message = null;
    }
  }

  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  Future<void> retry() async {
    if (busy ||
        !widget.order.canRetryPayment ||
        widget.order.paymentMethod == 'cash') {
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    key ??=
        'retry-${widget.order.orderId}-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
    try {
      final payment = await (widget.paymentService ?? PaymentService.instance)
          .initiatePayment(
        orderNumber: widget.order.orderNumber,
        paymentMethod: widget.order.paymentMethod,
        phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
        idempotencyKey: key,
      );
      if (!mounted) return;
      setState(() {
        message = payment.isFailed
            ? 'Le paiement a échoué. Votre commande reste accessible.'
            : payment.isPaid
                ? 'Paiement confirmé par le serveur.'
                : payment.status == 'reconciliation_required'
                    ? 'Paiement reçu, vérification financière nécessaire.'
                    : payment.status == 'refund_pending'
                        ? 'Remboursement en attente.'
                        : payment.status == 'refunded'
                            ? 'Remboursement confirmé par le serveur.'
                            : 'Demande enregistrée. Le paiement reste en attente de confirmation.';
        if (payment.isFailed) key = null;
      });
      await widget.onRefresh();
    } catch (error) {
      if (mounted) {
        setState(() => message = error is ApiException
            ? error.message
            : 'Paiement non confirmé. Réessayez ou actualisez la commande.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.order.canRetryPayment || widget.order.paymentMethod == 'cash') {
      return const SizedBox.shrink();
    }
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(children: [
          TextField(
              controller: phone,
              enabled: !busy && key == null,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Téléphone du paiement (si requis)')),
          if (message != null)
            Semantics(liveRegion: true, child: Text(message!)),
          ElevatedButton(
              onPressed: busy ? null : retry,
              child: Text(busy ? 'Vérification...' : 'Réessayer le paiement')),
        ]));
  }
}
