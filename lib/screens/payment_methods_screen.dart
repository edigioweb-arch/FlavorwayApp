import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


const Color orangeFlavor = Color(0xFFF36A2D);
const Color violetFlavor = Color(0xFF4B1F5C);
const Color pageBackground = Color(0xFFF7F8FA);

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  int selectedMethod = 3;

  final List<Map<String, dynamic>> methods = [
    {
      'name': 'Airtel Money', // Dynamic data, keep as is
      'subtitle': '1234',
      'type': 'orange',
    },
    {
      'name': 'MTN MoMo', // Dynamic data, keep as is
      'subtitle': '5678',
      'type': 'mtn',
    },
    {
      'name': 'Visa ****9012', // Dynamic data, keep as is
      'subtitle': '9012',
      'type': 'visa',
    },
    {
      'name': 'Mastercard', // Dynamic data, keep as is
      'subtitle': '2234 5678 9020',
      'type': 'mastercard',
    },
    {
      'name': 'Paiement à la livraison', // Dynamic data, keep as is
      'subtitle': '',
      'type': 'cash',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: pageBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Colors.black, size: 26),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Moyens de paiement',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              ...methods.asMap().entries.map((entry) {
                final index = entry.key;
                final method = entry.value;
                final isSelected = selectedMethod == index;

                return _PaymentMethodTile(
                  method: method,
                  isSelected: isSelected,
                  onTap: () => setState(() => selectedMethod = index),
                );
              }),
              const SizedBox(height: 14),
              _AddCardPanel(onTap: _showAddCardSheet),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddCardSheet() {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final monthController = TextEditingController();
    final yearController = TextEditingController();
    final cvvController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(90),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Ajouter une carte',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nom sur la carte',
                  hintText: 'Ex : Cynthia Kaussa',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Numéro de carte',
                  hintText: '0000 0000 0000 0000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: monthController,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'Mois',
                        hintText: 'MM',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'Année',
                        hintText: 'AA',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'CVV',
                        hintText: '123',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final holderName = nameController.text.trim();
                    final cardNumber = numberController.text.trim();
                    final month = monthController.text.trim();
                    final year = yearController.text.trim();
                    final cvv = cvvController.text.trim();

                    if (holderName.isEmpty ||
                        cardNumber.isEmpty ||
                        month.isEmpty ||
                        year.isEmpty ||
                        cvv.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Complétez les informations de la carte'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      methods.insert(3, {
                        'name': 'Nouvelle carte',
                        'subtitle':
                            '**** ${cardNumber.length >= 4 ? cardNumber.substring(cardNumber.length - 4) : cardNumber}',
                        'type': 'card',
                      });
                      selectedMethod = 3;
                    });

                    Navigator.maybePop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeFlavor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Enregistrer',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final Map<String, dynamic> method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        constraints: const BoxConstraints(minHeight: 92),
        decoration: BoxDecoration(
          color: isSelected ? orangeFlavor.withOpacity(0.055) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? orangeFlavor.withOpacity(0.70)
                : Colors.grey.shade300,
            width: 1.05,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              child: _PaymentLogo(type: method['type']),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    method['name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if ((method['subtitle'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      method['subtitle'],
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _Selector(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _Selector extends StatelessWidget {
  final bool isSelected;

  const _Selector({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? orangeFlavor : Colors.transparent,
        border: Border.all(
          color: isSelected ? orangeFlavor : Colors.grey.shade700,
          width: isSelected ? 0 : 1.8,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 15,
            )
          : null,
    );
  }
}

class _PaymentLogo extends StatelessWidget {
  final String type;

  const _PaymentLogo({required this.type});

  @override
  Widget build(BuildContext context) {
    if (type == 'orange') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          // l10n: airtelMoney
          'assets/images/airtelmoney.png',
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Text(
            'OM',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    if (type == 'mtn') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          // l10n: mtnMomo
          'assets/images/mtnmomo.png',
          width: 48,
          height: 38,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.phone_iphone_rounded,
            color: orangeFlavor,
            size: 38,
          ),
        ),
      );
    }

    if (type == 'visa') {
      return Text(
        // l10n: visaCard
        'VISA',
        style: GoogleFonts.poppins(
          color: const Color(0xFF1A4E9A),
          fontSize: 18,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (type == 'mastercard') {
      return SizedBox(
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 2,
              top: 7,
              child: Container(
                width: 27,
                height: 27,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 7,
              child: Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: orangeFlavor.withOpacity(0.90),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (type == 'cash') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          // l10n: cashOnDelivery
          'assets/images/cash.png',
          width: 44,
          height: 44,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.payments_rounded,
            color: orangeFlavor,
            size: 38,
          ),
        ),
      );
    }

    return const Icon(
      Icons.credit_card_rounded,
      color: orangeFlavor,
      size: 38,
    );
  }
}

class _AddCardPanel extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCardPanel({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EBEF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Card(
            elevation: 8,
            shadowColor: violetFlavor.withOpacity(0.22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: AspectRatio(
              aspectRatio: 1.586,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      violetFlavor,
                      Color(0xFF2C0F38),
                      orangeFlavor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.credit_card_rounded,
                            color: Colors.white, size: 30),
                        Text('FlavorWay',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Text('**** **** **** 4242',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _cardInfo('TITULAIRE', 'Cynthia K.'),
                        _cardInfo('EXPIRE', '12/28'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add_card_rounded,
                  color: Colors.black, size: 23),
              label: Text('Ajouter une carte',
                  style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w700)),
        Text(value,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
