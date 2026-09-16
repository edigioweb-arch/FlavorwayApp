import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
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
          'Mon Panier',
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Consumer<CartService>(
        builder: (context, cart, child) {
          if (cart.itemCount == 0) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              if (cart.quoteStatus == CartQuoteStatus.quoteError &&
                  cart.quoteErrorMessage != null)
                _buildQuoteError(cart),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await cart.refreshQuote();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _buildCartItem(item, cart);
                    },
                  ),
                ),
              ),
              _buildCheckoutBar(context, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuoteError(CartService cart) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF4C7C3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cart.quoteErrorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF7A2430),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
                color: orangeFlavor.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.shopping_basket_outlined,
                size: 80, color: orangeFlavor),
          ),
          const SizedBox(height: 24),
          Text('Votre panier est vide',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: violetFlavor)),
          const SizedBox(height: 8),
          const Text('Il semblerait que vous n\'ayez rien ajouté.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          SizedBox(
            width: 220,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: orangeFlavor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(90)),
                elevation: 0,
              ),
              child: Text('Découvrir le menu',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartService cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _buildImage(item.image),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(item.name,
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    GestureDetector(
                      onTap: () => cart.removeItem(item.id),
                      child: const Icon(Icons.cancel,
                          color: Colors.grey, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  cart.quotedLine(item) != null
                      ? '${(cart.quotedLine(item)!.unitPrice + cart.quotedLine(item)!.optionsTotal).toStringAsFixed(0)} ${cart.displayCurrency}'
                      : '${item.price.toStringAsFixed(0)} ${item.currencyCode} (estimé)',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: orangeFlavor),
                ),
                if (item.options.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.options.values.join(' • '),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _quantityButton(Icons.remove,
                        () => cart.updateQuantity(item.id, item.quantity - 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text('${item.quantity}',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    _quantityButton(Icons.add,
                        () => cart.updateQuantity(item.id, item.quantity + 1)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        height: 90,
        width: 90,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imageFallback(),
      );
    }

    return Image.asset(
      imagePath,
      height: 90,
      width: 90,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _imageFallback(),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 90,
      width: 90,
      color: orangeFlavor.withOpacity(0.1),
      child: const Icon(Icons.restaurant_menu, color: orangeFlavor),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: violetFlavor),
      ),
    );
  }

  Widget _buildCheckoutBar(BuildContext context, CartService cart) {
    final isLoading = cart.quoteStatus == CartQuoteStatus.loadingQuote;
    final canProceed = cart.items.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _priceRow(
            cart.hasValidQuote ? 'Sous-total' : 'Articles (estimation)',
            '${cart.displaySubtotal.toStringAsFixed(0)} ${cart.displayCurrency}',
            isBold: false,
          ),
          const SizedBox(height: 10),
          _priceRow(
            'Livraison',
            cart.hasValidQuote
                ? '${cart.displayDeliveryFee.toStringAsFixed(0)} ${cart.displayCurrency}'
                : 'Après adresse',
            isBold: false,
          ),
          if (cart.displayDiscount > 0) ...[
            const SizedBox(height: 10),
            _priceRow(
              'Réduction',
              '-${cart.displayDiscount.toStringAsFixed(0)} ${cart.displayCurrency}',
              isBold: false,
              color: Colors.green,
            ),
          ],
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),
          _priceRow(
            'TOTAL',
            cart.hasValidQuote
                ? '${cart.displayTotal.toStringAsFixed(0)} ${cart.displayCurrency}'
                : 'À calculer',
            isBold: true,
            color: orangeFlavor,
          ),
          const SizedBox(height: 10),
          if (!cart.hasValidQuote)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isLoading
                    ? 'Vérification du montant en cours...'
                    : 'Choisissez votre adresse pour obtenir le montant serveur.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isLoading ? violetFlavor : Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: violetFlavor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(90)),
                elevation: 0,
              ),
              onPressed: canProceed
                  ? () => Navigator.pushNamed(context, '/checkout')
                  : null,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Choisir l’adresse de livraison',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {required bool isBold, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: isBold ? 18 : 14,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    color: isBold ? Colors.black87 : Colors.grey))),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: GoogleFonts.poppins(
                    fontSize: isBold ? 20 : 14,
                    fontWeight: FontWeight.bold,
                    color: color ?? Colors.black87))),
      ],
    );
  }
}
