import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/restaurant_service.dart';

class EditMenuScreen extends StatefulWidget {
  const EditMenuScreen({super.key});

  @override
  State<EditMenuScreen> createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends State<EditMenuScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color violetDark = Color(0xFF2A0D35);
  static const Color softBg = Color(0xFFF8F4FA);

  String? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantService>(
      builder: (context, restaurantService, child) {
        final restaurant = restaurantService.joliCoin;
        selectedCategoryId ??= restaurant.menuCategories.isNotEmpty
            ? restaurant.menuCategories.first.id
            : null;

        final selectedCategory = restaurant.menuCategories.firstWhere(
          (category) => category.id == selectedCategoryId,
          orElse: () => restaurant.menuCategories.first,
        );

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
                        _sectionTitle('Catégories'),
                        const SizedBox(height: 12),
                        _categorySelector(restaurant.menuCategories),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionTitle(selectedCategory.name),
                            _smallButton(
                              label: 'Ajouter',
                              icon: Icons.add_rounded,
                              onTap: () => _showDishForm(
                                context,
                                restaurantService,
                                categoryId: selectedCategory.id,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...selectedCategory.dishes.map(
                          (dish) => _dishCard(
                            context,
                            restaurantService,
                            selectedCategory.id,
                            dish,
                          ),
                        ),
                        const SizedBox(height: 24),
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
                  'Gestion des menus',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ajoutez, modifiez ou supprimez les plats visibles côté client.',
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
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _categorySelector(List<RestaurantMenuCategory> categories) {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.id == selectedCategoryId;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategoryId = category.id;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? orangeFlavor : Colors.white,
                borderRadius: BorderRadius.circular(90),
                border: Border.all(
                  color: isSelected
                      ? orangeFlavor
                      : violetFlavor.withOpacity(0.12),
                ),
              ),
              child: Text(
                category.name,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : violetFlavor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _smallButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: orangeFlavor,
          borderRadius: BorderRadius.circular(90),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dishCard(
    BuildContext context,
    RestaurantService restaurantService,
    String categoryId,
    RestaurantDish dish,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: orangeFlavor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(90),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: orangeFlavor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dish.name,
                  style: GoogleFonts.poppins(
                    color: violetDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dish.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dish.priceText,
                  style: GoogleFonts.poppins(
                    color: orangeFlavor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: violetFlavor),
                onPressed: () => _showDishForm(
                  context,
                  restaurantService,
                  categoryId: categoryId,
                  dish: dish,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                onPressed: () {
                  restaurantService.removeDish(
                    restaurantId: 'joli_coin',
                    categoryId: categoryId,
                    dishId: dish.id,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDishForm(
    BuildContext context,
    RestaurantService restaurantService, {
    required String categoryId,
    RestaurantDish? dish,
  }) {
    final nameController = TextEditingController(text: dish?.name ?? '');
    final descriptionController =
        TextEditingController(text: dish?.description ?? '');
    final priceTextController =
        TextEditingController(text: dish?.priceText ?? '');
    final priceController = TextEditingController(
      text: dish == null ? '' : dish.price.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish == null ? 'Ajouter un plat' : 'Modifier le plat',
                    style: GoogleFonts.poppins(
                      color: violetDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _modalInput(nameController, 'Nom du plat'),
                  _modalInput(descriptionController, 'Description'),
                  _modalInput(priceTextController, 'Prix affiché ex: 2500F'),
                  _modalInput(priceController, 'Prix numérique ex: 2500',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        final price =
                            double.tryParse(priceController.text.trim()) ?? 0;

                        if (dish == null) {
                          restaurantService.addDish(
                            restaurantId: 'joli_coin',
                            categoryId: categoryId,
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            priceText: priceTextController.text.trim(),
                            price: price,
                          );
                        } else {
                          restaurantService.updateDish(
                            restaurantId: 'joli_coin',
                            categoryId: categoryId,
                            dishId: dish.id,
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            priceText: priceTextController.text.trim(),
                            price: price,
                          );
                        }

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeFlavor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(90),
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
            ),
          ),
        );
      },
    );
  }

  Widget _modalInput(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
