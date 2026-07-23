import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/restaurant_service.dart';

class EditRestaurantScreen extends StatefulWidget {
  const EditRestaurantScreen({super.key});

  @override
  State<EditRestaurantScreen> createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color violetDark = Color(0xFF2A0D35);
  static const Color softBg = Color(0xFFF8F4FA);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();

  bool _isInitialized = false;
  bool _isOpen = true;

  final List<String> availableServices = const [
    'Réservation',
    'Menu QR',
    'Sur place',
    'À emporter',
    'Livraison',
  ];

  final Set<String> selectedServices = {};

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _hoursController.dispose();
    _timeController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  void _initFields(RestaurantData restaurant) {
    if (_isInitialized) return;

    _nameController.text = restaurant.name;
    _typeController.text = restaurant.type;
    _descriptionController.text = restaurant.description;
    _addressController.text = restaurant.address;
    _phoneController.text = restaurant.phone;
    _hoursController.text = restaurant.openingHours;
    _timeController.text = restaurant.preparationTime;
    _distanceController.text = restaurant.distance;
    _isOpen = restaurant.isOpen;
    selectedServices.addAll(restaurant.services);

    _isInitialized = true;
  }

  void _saveRestaurant(RestaurantService service) {
    service.updateRestaurantInfo(
      restaurantId: 'joli_coin',
      name: _nameController.text.trim(),
      type: _typeController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      openingHours: _hoursController.text.trim(),
      preparationTime: _timeController.text.trim(),
      distance: _distanceController.text.trim(),
      isOpen: _isOpen,
    );

    final restaurant = service.joliCoin;
    for (final item in availableServices) {
      final exists = restaurant.services.contains(item);
      final shouldExist = selectedServices.contains(item);

      if (exists != shouldExist) {
        service.toggleService(
          restaurantId: 'joli_coin',
          service: item,
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informations restaurant mises à jour')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantService>(
      builder: (context, restaurantService, child) {
        final restaurant = restaurantService.joliCoin;
        _initFields(restaurant);

        return Scaffold(
          backgroundColor: softBg,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Informations principales'),
                        const SizedBox(height: 14),
                        _inputField(
                          controller: _nameController,
                          label: 'Nom du restaurant',
                          icon: Icons.storefront_rounded,
                        ),
                        _inputField(
                          controller: _typeController,
                          label: 'Type de cuisine',
                          icon: Icons.restaurant_menu_rounded,
                        ),
                        _inputField(
                          controller: _descriptionController,
                          label: 'Description',
                          icon: Icons.description_rounded,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 12),
                        _sectionTitle('Adresse & contact'),
                        const SizedBox(height: 14),
                        _inputField(
                          controller: _addressController,
                          label: 'Adresse',
                          icon: Icons.location_on_rounded,
                        ),
                        _inputField(
                          controller: _phoneController,
                          label: 'Téléphone',
                          icon: Icons.call_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        _inputField(
                          controller: _hoursController,
                          label: 'Horaires',
                          icon: Icons.schedule_rounded,
                        ),
                        _inputField(
                          controller: _timeController,
                          label: 'Temps estimé',
                          icon: Icons.timer_rounded,
                        ),
                        _inputField(
                          controller: _distanceController,
                          label: 'Zone / distance',
                          icon: Icons.map_rounded,
                        ),
                        const SizedBox(height: 12),
                        _sectionTitle('Statut'),
                        const SizedBox(height: 14),
                        _openSwitch(),
                        const SizedBox(height: 20),
                        _sectionTitle('Services'),
                        const SizedBox(height: 14),
                        _servicesSelector(),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: () => _saveRestaurant(restaurantService),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeFlavor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(90),
                              ),
                            ),
                            child: Text(
                              'Enregistrer les modifications',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        color: violetFlavor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(90),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modifier le restaurant',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Les changements seront visibles côté client.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: violetDark,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(maxLines > 1 ? 18 : 90),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
          color: violetDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 13 : 0),
            child: Icon(icon, color: violetFlavor, size: 22),
          ),
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey.shade500,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: maxLines > 1 ? 18 : 17,
          ),
        ),
      ),
    );
  }

  Widget _openSwitch() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: orangeFlavor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(90),
            ),
            child: const Icon(
              Icons.power_settings_new_rounded,
              color: orangeFlavor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOpen ? 'Restaurant ouvert' : 'Restaurant fermé',
                  style: GoogleFonts.poppins(
                    color: violetDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Statut affiché sur la fiche client.',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isOpen,
            activeColor: orangeFlavor,
            onChanged: (value) {
              setState(() {
                _isOpen = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _servicesSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: availableServices.map((service) {
        final bool isSelected = selectedServices.contains(service);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedServices.remove(service);
              } else {
                selectedServices.add(service);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? orangeFlavor : Colors.white,
              borderRadius: BorderRadius.circular(90),
              border: Border.all(
                color:
                    isSelected ? orangeFlavor : violetFlavor.withOpacity(0.12),
              ),
            ),
            child: Text(
              service,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : violetFlavor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
