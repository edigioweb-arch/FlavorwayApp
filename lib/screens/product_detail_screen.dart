import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/restaurant_model.dart';
import '../services/cart_service.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    this.dish,
    this.productName = '',
    this.productImage = '',
    this.productPrice = '',
    this.productDescription = '',
  });

  final RestaurantDishModel? dish;
  final String productName;
  final String productImage;
  final String productPrice;
  final String productDescription;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);

  int quantity = 1;
  final Map<String, Set<String>> _selectedOptionValues = {};

  String get _name => widget.dish?.name ?? widget.productName;
  String get _description =>
      widget.dish?.description ?? widget.productDescription;
  String? get _image => widget.dish?.image ?? widget.productImage;
  double get _price =>
      widget.dish?.price ?? _parseLegacyPrice(widget.productPrice);
  String get _priceText =>
      widget.dish?.priceText ?? '${_price.toStringAsFixed(0)} FCFA';
  bool get _hasOptions => (widget.dish?.options ?? const []).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final total = (_price + _selectedOptionsTotal) * quantity;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: violetFlavor),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          _name,
          style: GoogleFonts.poppins(
            color: violetFlavor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 260,
            width: double.infinity,
            child: _buildImage(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: violetFlavor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _description,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        _priceText,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: orangeFlavor,
                        ),
                      ),
                    ],
                  ),
                  if (widget.dish?.isAvailable == false)
                    const Text('Ce produit est actuellement indisponible.',
                        style: TextStyle(color: Colors.red)),
                  const SizedBox(height: 22),
                  if (_hasOptions) ...[
                    Text(
                      'Options disponibles',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: violetFlavor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...widget.dish!.options
                        .where((option) => option.isActive)
                        .map(_buildOptionCard),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Quantité',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: violetFlavor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _quantityButton(Icons.remove, () {
                        if (quantity > 1) {
                          setState(() => quantity -= 1);
                        }
                      }),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$quantity',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: violetFlavor,
                          ),
                        ),
                      ),
                      _quantityButton(Icons.add, () {
                        setState(() => quantity += 1);
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: !_canAddToCart
                  ? null
                  : () {
                      if (!_canAddToCart) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Veuillez sélectionner toutes les options obligatoires.',
                            ),
                          ),
                        );
                        return;
                      }

                      try {
                        context.read<CartService>().addItem(
                              CartItem(
                                id: '${widget.dish?.id ?? _name}-${_selectedOptionIds.join("-")}',
                                productId:
                                    int.tryParse(widget.dish?.id ?? '') ?? 0,
                                restaurantId: int.tryParse(
                                        widget.dish?.restaurantId ?? '') ??
                                    0,
                                name: _name,
                                image: _image ?? '',
                                restaurantName: widget.dish?.menuName ??
                                    'Restaurant FlavorWay',
                                price: _price + _selectedOptionsTotal,
                                currencyCode:
                                    widget.dish?.currencyCode ?? 'XAF',
                                quantity: quantity,
                                optionValueIds: _selectedOptionIds,
                                options: _selectedOptionsMap,
                              ),
                            );
                      } on StateError catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.message)));
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Produit ajouté au panier'),
                          action: SnackBarAction(
                              label: 'Voir le panier',
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/cart')),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: violetFlavor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                widget.dish?.isAvailable == false
                    ? 'Produit indisponible'
                    : !_canAddToCart
                        ? 'Sélectionnez les options obligatoires'
                        : 'Ajouter • ${total.toStringAsFixed(0)} FCFA',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final path = _image;

    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child:
            const Icon(Icons.fastfood_rounded, size: 52, color: violetFlavor),
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade100,
          child:
              const Icon(Icons.fastfood_rounded, size: 52, color: violetFlavor),
        ),
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade100,
        child:
            const Icon(Icons.fastfood_rounded, size: 52, color: violetFlavor),
      ),
    );
  }

  Widget _buildOptionCard(ProductOptionModel option) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  option.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: violetFlavor,
                  ),
                ),
              ),
              if (option.isRequired)
                Text(
                  'Obligatoire',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: orangeFlavor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (option.values.isEmpty)
            Text(
              'Aucune valeur publiée.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: option.values.map((value) {
                final selected = _selectedOptionValues[option.id] ?? <String>{};
                final isSelected = selected.contains(value.id);
                final label = (value.priceDelta ?? 0) > 0
                    ? '${value.name} (+${(value.priceDelta ?? 0).toStringAsFixed(0)} FCFA)'
                    : value.name;

                return FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: value.isAvailable
                      ? (_) {
                          setState(() {
                            if (isSelected) {
                              selected.remove(value.id);
                            } else {
                              if (option.selectionType == 'single')
                                selected.clear();
                              selected.add(value.id);
                            }
                            _selectedOptionValues[option.id] = selected;
                          });
                        }
                      : null,
                );
              }).toList(growable: false),
            ),
        ],
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F4FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: violetFlavor),
      ),
    );
  }

  double _parseLegacyPrice(String raw) {
    final normalized = raw.replaceAll('CFA', '').replaceAll('FCFA', '').trim();
    return double.tryParse(
            normalized.replaceAll(' ', '').replaceAll(',', '.')) ??
        0;
  }

  bool get _canAddToCart {
    if (widget.dish == null || !widget.dish!.isAvailable) return false;
    return widget.dish!.options
        .where((option) => option.isActive)
        .every((option) {
      final selected = _selectedOptionValues[option.id] ?? <String>{};
      return (!option.isRequired || selected.isNotEmpty) &&
          (option.selectionType != 'single' || selected.length <= 1);
    });
  }

  double get _selectedOptionsTotal {
    double total = 0;
    for (final option in widget.dish?.options ?? <ProductOptionModel>[]) {
      for (final value in option.values) {
        if (_selectedOptionValues[option.id]?.contains(value.id) == true)
          total += value.priceDelta ?? 0;
      }
    }
    return total;
  }

  List<int> get _selectedOptionIds =>
      _selectedOptionValues.values.expand((ids) => ids).map(int.parse).toList()
        ..sort();

  Map<String, dynamic> get _selectedOptionsMap => {
        for (final option in widget.dish?.options ?? <ProductOptionModel>[])
          if (_selectedOptionValues[option.id]?.isNotEmpty == true)
            option.name: option.values
                .where((value) =>
                    _selectedOptionValues[option.id]!.contains(value.id))
                .map((value) => value.name)
                .join(', '),
      };
}
