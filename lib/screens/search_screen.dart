import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color orangeFlavor = Color(0xFFF36A2D);
const Color violetFlavor = Color(0xFF4B1F5C);

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String query = '';
  List<String> categories = [
    'Grillades',
    'Riz',
    'Burger',
    'Poissons',
    'Soupes'
  ];
  List<bool> selectedFilters = List.generate(5, (index) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher restaurants, plats...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _searchController.clear()),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey.shade200,
          ),
          onChanged: (value) => setState(() => query = value),
        ),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(
                      () => selectedFilters[index] = !selectedFilters[index]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          selectedFilters[index] ? orangeFlavor : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: orangeFlavor.withOpacity(0.3)),
                    ),
                    child: Text(
                      categories[index],
                      style: GoogleFonts.poppins(
                        color: selectedFilters[index]
                            ? Colors.white
                            : orangeFlavor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: query.isEmpty
                ? _buildEmptySearch()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 10,
                    itemBuilder: (context, index) => Card(
                      child: ListTile(
                        leading:
                            const CircleAvatar(child: Icon(Icons.restaurant)),
                        title: Text(
                            'Restaurant $index (${categories.where((cat) => selectedFilters[categories.indexOf(cat)]).join(', ')} )'),
                        subtitle:
                            const Text('4.5⭐ • 25 min • Livraison 500 FCFA'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {},
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Rechercher',
              style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Restaurants ou plats près de vous',
              style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }
}
