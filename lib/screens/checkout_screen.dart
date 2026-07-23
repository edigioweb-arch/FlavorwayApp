import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);

  String selectedPaymentMethod = 'Orange Money';
  String selectedAddress = 'Maison - Akwa, Douala';

  final List<Map<String, String>> addresses = [
    {'name': 'Maison', 'full': 'Akwa, Douala - 20 min'},
    {'name': 'Bureau', 'full': 'Bonanjo, Douala - 15 min'},
    {'name': 'Chez maman', 'full': 'New Bell, Douala - 30 min'},
  ];

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
              // Récapitulatif commande
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Articles (${cart.items.length})',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        Text(
                          '${cart.items.fold<double>(0.0, (sum, item) => sum + item.totalPrice).toStringAsFixed(0)} CFA',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Livraison'),
                        Text(
                          '2 000 CFA',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: violetFlavor,
                          ),
                        ),
                        Text(
                          '${cart.totalAmount.toStringAsFixed(0)} CFA',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: orangeFlavor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Articles commandés
                      _buildSectionTitle('Articles commandés'),
                      _buildCartItems(cart),

                      const SizedBox(height: 12),

                      // Adresse livraison
                      _buildSectionTitle('Adresse de livraison'),
                      _buildAddressSelector(),

                      const SizedBox(height: 24),

                      // Mode de paiement
                      _buildSectionTitle('Mode de paiement'),
                      _buildPaymentSelector(),

                      const SizedBox(height: 24),

                      // Note pour le restaurant
                      _buildSectionTitle('Note pour le restaurant'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
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

              // Bouton commande
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
          ...addresses.map((addr) => RadioListTile<String>(
                title: Text(addr['name']!,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(addr['full']!),
                value: addr['name']!,
                groupValue: selectedAddress,
                onChanged: (value) => setState(() => selectedAddress = value!),
              )),
          const Divider(height: 1),
          TextButton.icon(
            onPressed: () {},
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
          RadioListTile<String>(
            title: Row(
              children: [
                Image.asset('assets/images/orange_money.png',
                    height: 24,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.phone_android, color: orangeFlavor)),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Orange Money',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Paiement instantané',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            value: 'Orange Money',
            groupValue: selectedPaymentMethod,
            onChanged: (value) =>
                setState(() => selectedPaymentMethod = value!),
          ),
          RadioListTile<String>(
            title: Row(
              children: [
                Image.asset('assets/images/mtn_momo.png',
                    height: 24,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.phone_android, color: Colors.green)),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MTN MoMo',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Paiement instantané',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            value: 'MTN MoMo',
            groupValue: selectedPaymentMethod,
            onChanged: (value) =>
                setState(() => selectedPaymentMethod = value!),
          ),
          RadioListTile<String>(
            title: Row(
              children: [
                const Icon(Icons.credit_card, color: Colors.blue),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Carte bancaire',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Visa, Mastercard',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            value: 'Carte bancaire',
            groupValue: selectedPaymentMethod,
            onChanged: (value) =>
                setState(() => selectedPaymentMethod = value!),
          ),
          RadioListTile<String>(
            title: Row(
              children: [
                const Icon(Icons.money, color: Colors.green),
                const SizedBox(width: 12),
                const Text('Paiement à la livraison',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            value: 'Paiement à la livraison',
            groupValue: selectedPaymentMethod,
            onChanged: (value) =>
                setState(() => selectedPaymentMethod = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderButton(BuildContext context, CartService cart) {
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
        onPressed: () {
          final orderNumber =
              '#FLW-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

          final restaurantName = cart.items.isNotEmpty
              ? cart.items.first.restaurantName
              : 'Restaurant';

          OrderService.instance.addOrder(
            restaurantName: restaurantName,
            orderNumber: orderNumber,
            date: DateTime.now().toString().substring(0, 16),
            total: cart.totalAmount,
            status: 'Livrée',
          );
          NotificationService.instance.addNotification(
            title: 'Commande créée',
            message:
                'Votre commande $orderNumber est en préparation.',
          );

          cart.clear();
          Navigator.pushReplacementNamed(context, '/order-success');
        },
        child: Text(
          'Passer la commande • ${cart.totalAmount.toStringAsFixed(0)} CFA',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
                '${item.totalPrice.toStringAsFixed(0)} CFA',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      cart.removeItem(item.id);
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.remove, size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.quantity}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      cart.addItem(item);
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: orangeFlavor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: orangeFlavor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      cart.removeItem(item.id);
                    },
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}
