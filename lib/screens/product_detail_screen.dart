import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productName;
  final String productImage;
  final String productPrice;
  final String productDescription;

  const ProductDetailScreen({
    super.key,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.productDescription,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);

  int quantity = 1;
  bool spicy = false;
  String cookingLevel = 'Moyen';
  List<String> selectedExtras = [];
  String selectedDrink = 'Sans boisson';

  final List<Map<String, dynamic>> extras = [
    {'name': 'Fromage', 'price': '500 CFA'},
    {'name': 'Oignon', 'price': '200 CFA'},
    {'name': 'Piment', 'price': '300 CFA'},
  ];

  final List<String> cookingLevels = [
    'Saignant',
    'À point',
    'Bien cuit',
    'Moyen'
  ];
  final List<Map<String, dynamic>> drinks = [
    {'name': 'Sans boisson', 'price': '0 CFA'},
    {'name': 'Bissap', 'price': '1000 CFA'},
    {'name': 'Gnamakoudji', 'price': '1200 CFA'},
    {'name': 'Soda', 'price': '800 CFA'},
  ];

  double get totalPrice {
    double basePrice = double.parse(
        widget.productPrice.replaceAll(' CFA', '').replaceAll(',', ''));
    double extrasPrice = selectedExtras.length * 300; // average
    double drinkPrice = selectedDrink == 'Sans boisson' ? 0 : 1000;
    return basePrice + extrasPrice + drinkPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: violetFlavor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.productName,
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Image produit
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.productImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.productName,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '⭐ 4.8 (127 avis)',
                            style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        '${totalPrice.toStringAsFixed(0)} CFA',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: orangeFlavor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.productDescription,
                    style: GoogleFonts.poppins(
                      height: 1.5,
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Options
                  _buildOptionSection(
                      'Cuisson',
                      DropdownButton<String>(
                        value: cookingLevel,
                        isExpanded: true,
                        underline: Container(),
                        items: cookingLevels
                            .map((level) => DropdownMenuItem(
                                  value: level,
                                  child: Text(level),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => cookingLevel = value!),
                      )),

                  _buildOptionSection(
                      'Piquant',
                      CheckboxListTile(
                        title:
                            Text('Extra piment', style: GoogleFonts.poppins()),
                        value: spicy,
                        onChanged: (value) => setState(() => spicy = value!),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: orangeFlavor,
                      )),

                  _buildOptionSection(
                      'Suppléments',
                      Column(
                        children: extras
                            .map((extra) => CheckboxListTile(
                                  title: Text(extra['name'],
                                      style: GoogleFonts.poppins()),
                                  subtitle: Text(extra['price']),
                                  value: selectedExtras.contains(extra['name']),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value!) {
                                        selectedExtras.add(extra['name']);
                                      } else {
                                        selectedExtras.remove(extra['name']);
                                      }
                                    });
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  activeColor: orangeFlavor,
                                ))
                            .toList(),
                      )),

                  _buildOptionSection(
                      'Accompagnement',
                      DropdownButton<String>(
                        value: selectedDrink,
                        isExpanded: true,
                        underline: Container(),
                        items: drinks
                            .map<DropdownMenuItem<String>>(
                                (drink) => DropdownMenuItem<String>(
                                      value: drink['name'],
                                      child: Text(
                                          '${drink['name']} - ${drink['price']}'),
                                    ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedDrink = value!),
                      )),

                  const SizedBox(height: 30),

                  // Quantité
                  _buildQuantityRow(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: orangeFlavor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            onPressed: () {
              // Add to cart logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${widget.productName} (${quantity}x) ajouté au panier!'),
                  backgroundColor: orangeFlavor,
                  duration: const Duration(seconds: 2),
                ),
              );
              Navigator.pop(context);
            },
            child: Text(
              'Ajouter au panier • ${totalPrice.toStringAsFixed(0)} CFA',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: child,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildQuantityRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantité',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed:
                    quantity > 1 ? () => setState(() => quantity--) : null,
                icon: const Icon(Icons.remove, color: Colors.grey),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$quantity',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => setState(() => quantity++),
                icon: const Icon(Icons.add, color: Colors.grey),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
