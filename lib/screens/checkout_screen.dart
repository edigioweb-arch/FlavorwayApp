import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'addresses_screen.dart';
import 'payment_methods_screen.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';
import '../services/payment_method_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);

  String selectedPaymentMethod = 'Paiement à la livraison';
  Map<String, dynamic>? _selectedAddress;
  final TextEditingController _noteController = TextEditingController();
  bool _submitting = false;
  String? _lastQuotedFingerprint;
  String? _pendingIdempotencyKey;

  @override
  void initState() {
    super.initState();
    selectedPaymentMethod = PaymentMethodService.instance.selectedMethod.name;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureQuote();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _openAddressBook() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressesScreen(),
      ),
    );

    if (result is! Map) return;

    final full = (result['full'] as String?)?.trim();
    if (full == null || full.isEmpty) return;

    setState(() {
      _selectedAddress = Map<String, dynamic>.from(result);
    });

    await _refreshQuote();
  }

  Future<void> _openPaymentMethods() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentMethodsScreen(),
      ),
    );

    if (result is String && result.trim().isNotEmpty) {
      setState(() {
        selectedPaymentMethod = result.trim();
      });
    } else {
      setState(() {
        selectedPaymentMethod = PaymentMethodService.instance.selectedMethod.name;
      });
    }

    await _refreshQuote();
  }

  void _ensureQuote() {
    final cart = context.read<CartService>();
    if (cart.items.isEmpty) {
      _lastQuotedFingerprint = null;
      return;
    }

    if (_lastQuotedFingerprint == cart.cartFingerprint &&
        cart.quoteStatus != CartQuoteStatus.quoteError) {
      return;
    }

    _lastQuotedFingerprint = cart.cartFingerprint;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _refreshQuote();
    });
  }

  Future<void> _refreshQuote() async {
    final cart = context.read<CartService>();
    final address = _selectedAddress;

    await cart.refreshQuote(
      deliveryCityId: address?['city_id']?.toString(),
      deliveryZoneAreaId: address?['delivery_zone_area_id']?.toString(),
      deliveryZoneAreaName: address?['delivery_zone_area_name']?.toString(),
      deliveryAddressLine: address?['full']?.toString(),
      deliveryLatitude: address?['latitude'] as double?,
      deliveryLongitude: address?['longitude'] as double?,
      paymentMethod: selectedPaymentMethod,
    );

    _lastQuotedFingerprint = cart.cartFingerprint;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (route) => false);
            }
          },
        ),
        title: Text(
          'Paiement',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<CartService>(
        builder: (context, cart, child) {
          return Column(
            children: [
              if (cart.quoteErrorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF4C7C3)),
                  ),
                  child: Text(
                    cart.quoteErrorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF7A2430),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _summaryRow(
                      'Articles (${cart.items.length})',
                      '${cart.displaySubtotal.toStringAsFixed(0)} ${cart.displayCurrency}',
                    ),
                    const Divider(),
                    _summaryRow(
                      'Livraison',
                      '${cart.displayDeliveryFee.toStringAsFixed(0)} ${cart.displayCurrency}',
                    ),
                    if (cart.displayDiscount > 0) ...[
                      const Divider(),
                      _summaryRow(
                        'Réduction',
                        '-${cart.displayDiscount.toStringAsFixed(0)} ${cart.displayCurrency}',
                      ),
                    ],
                    const Divider(),
                    _summaryRow(
                      'TOTAL',
                      '${cart.displayTotal.toStringAsFixed(0)} ${cart.displayCurrency}',
                      isTotal: true,
                    ),
                    if (cart.quoteStatus == CartQuoteStatus.loadingQuote) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(minHeight: 4),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Articles commandés'),
                      _buildCartItems(cart),
                      const SizedBox(height: 12),
                      _buildSectionTitle('Adresse de livraison'),
                      _buildAddressSelector(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Mode de paiement'),
                      _buildPaymentSelector(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Note pour le restaurant'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Ex: Sans oignon s\'il vous plaît',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildOrderButton(context, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 24),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildAddressSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedAddress == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Sélectionnez une adresse avec ville et quartier pour calculer correctement la livraison.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined),
              title: Text(
                (_selectedAddress?['name'] ?? _selectedAddress?['label'] ?? 'Adresse').toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                [
                  (_selectedAddress?['full'] ?? '').toString(),
                  (_selectedAddress?['city_name'] ?? '').toString(),
                  (_selectedAddress?['delivery_zone_area_name'] ?? '').toString(),
                ].where((value) => value.trim().isNotEmpty).join(' • '),
              ),
            ),
          const Divider(height: 1),
          TextButton.icon(
            onPressed: _openAddressBook,
            icon: const Icon(Icons.add, size: 18),
            label: Text('Ajouter une adresse',
                style: TextStyle(color: orangeFlavor)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _openPaymentMethods,
              icon: const Icon(Icons.wallet_outlined, size: 18),
              label: const Text('Gérer'),
            ),
          ),
          ...[
            ('Airtel Money', null, Colors.redAccent, 'Paiement instantané'),
            ('MTN MoMo', 'assets/images/mtnmomo.png', Colors.green, 'Paiement instantané'),
            ('Carte bancaire', null, Colors.blue, 'Visa, Mastercard'),
            ('Paiement à la livraison', null, Colors.green, null),
          ].map(
            (entry) => RadioListTile<String>(
              title: Row(
                children: [
                  if (entry.$2 != null)
                    Image.asset(
                      entry.$2!,
                      height: 24,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.payment,
                        color: entry.$3,
                      ),
                    )
                  else
                    Icon(
                      entry.$1 == 'Carte bancaire'
                          ? Icons.credit_card
                          : Icons.money,
                      color: entry.$3,
                    ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.$1,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (entry.$4 != null)
                        Text(
                          entry.$4!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),
              value: entry.$1,
              groupValue: selectedPaymentMethod,
              onChanged: (value) async {
                setState(() => selectedPaymentMethod = value!);
                await _refreshQuote();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderButton(BuildContext context, CartService cart) {
    final canSubmit = cart.hasValidQuote &&
        cart.quoteStatus != CartQuoteStatus.loadingQuote &&
        !_submitting;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: orangeFlavor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(90),
          ),
          elevation: 0,
        ),
        onPressed: !canSubmit
            ? null
            : () async {
                setState(() => _submitting = true);
                dynamic createdOrder;
                try {
                  final quote = cart.quote!;
                  final address = _selectedAddress;
                  if (address == null) {
                    throw Exception('Adresse de livraison introuvable.');
                  }

                  _pendingIdempotencyKey ??=
                      OrderService.instance.generateIdempotencyKey();

                  final order = await OrderService.instance.createOrder(
                    restaurantId: cart.restaurantId ?? quote.restaurantId,
                    items: cart.items,
                    deliveryAddress: <String, dynamic>{
                      'label': (address['name'] ?? address['label'] ?? 'Adresse').toString(),
                      'address_line': (address['full'] ?? '').toString(),
                      'city': (address['city_name'] ?? '').toString(),
                      'city_id': int.tryParse((address['city_id'] ?? '').toString()),
                      'delivery_zone_area_id': int.tryParse((address['delivery_zone_area_id'] ?? '').toString()),
                      'delivery_zone_area_name': (address['delivery_zone_area_name'] ?? '').toString(),
                      'latitude': address['latitude'],
                      'longitude': address['longitude'],
                    },
                    paymentMethod: selectedPaymentMethod,
                    idempotencyKey: _pendingIdempotencyKey!,
                    note: _noteController.text.trim(),
                  );

                  NotificationService.instance.addNotification(
                    title: 'Commande créée',
                    message:
                        'Votre commande ${order.orderNumber} est enregistrée.',
                  );
                  createdOrder = order;

                  if (selectedPaymentMethod != 'Paiement à la livraison') {
                    await PaymentService.instance.initiatePayment(
                      orderNumber: order.orderNumber,
                      paymentMethod: selectedPaymentMethod,
                      phone: null,
                      idempotencyKey: _pendingIdempotencyKey,
                    );
                  } else {
                    await PaymentService.instance.initiatePayment(
                      orderNumber: order.orderNumber,
                      paymentMethod: 'cash',
                      idempotencyKey: _pendingIdempotencyKey,
                    );
                  }

                  cart.clear();
                  _pendingIdempotencyKey = null;
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(
                    context,
                    '/order-success',
                    arguments: order.orderNumber,
                  );
                } catch (e) {
                  if (createdOrder != null) {
                    cart.clear();
                    _pendingIdempotencyKey = null;
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Commande créée, mais le paiement n’a pas pu être initié. Réessayez depuis le suivi.',
                        ),
                      ),
                    );
                    Navigator.pushReplacementNamed(
                      context,
                      '/order-tracking',
                      arguments: createdOrder.orderNumber,
                    );
                    return;
                  }
                  final message = e.toString().replaceFirst('Exception: ', '');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur : $message')),
                  );
                } finally {
                  if (mounted) {
                    setState(() => _submitting = false);
                  }
                }
              },
        child: _submitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                cart.hasValidQuote
                    ? 'Passer la commande • ${cart.displayTotal.toStringAsFixed(0)} ${cart.displayCurrency}'
                    : 'Montant à vérifier',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? violetFlavor : Colors.black87,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? orangeFlavor : Colors.black87,
          ),
        ),
      ],
    );
  }
}

Widget _buildCartItems(CartService cart) {
  const Color orangeFlavor = Color(0xFFF36A2D);
  if (cart.items.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: Text('Aucun article dans le panier'),
      ),
    );
  }

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      children: cart.items.map((item) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: orangeFlavor.withOpacity(0.12),
            child: const Icon(
              Icons.restaurant_menu,
              color: orangeFlavor,
            ),
          ),
          title: Text(
            item.name,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Quantité : ${item.quantity}',
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.totalPrice.toStringAsFixed(0)} ${item.currencyCode}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.options.isNotEmpty)
                Text(
                  item.options.values.join(' • '),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        );
      }).toList(growable: false),
    ),
  );
}
