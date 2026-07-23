import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color orangeFlavor = Color(0xFFF36A2D);

class RestaurantOrdersScreen extends StatelessWidget {
  const RestaurantOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Commandes',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Badge(
              label: const Text('3'),
              child: IconButton(
                  icon: const Icon(Icons.notifications), onPressed: () {})),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOrderStatusChip('Nouveau', 12, Colors.blue),
          _buildOrderStatusChip('En préparation', 5, Colors.orange),
          _buildOrderStatusChip('Livré', 23, Colors.green),
          const SizedBox(height: 20),
          Text('Nouvelles commandes',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...List.generate(5, (index) => _buildOrderCard(index)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: orangeFlavor,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildOrderStatusChip(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text('$count',
                style: GoogleFonts.poppins(
                    color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Commande #FLW-${1000 + index}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Nouveau',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Cynthia Kaussa • +237 655 123 456',
                style: GoogleFonts.poppins(color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.fastfood)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('Poulet Yassa + Ndolé x2 • 9 000 FCFA',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                const Icon(Icons.arrow_forward_ios),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Préparer'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: orangeFlavor),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call),
                  label: const Text('Appeler'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
