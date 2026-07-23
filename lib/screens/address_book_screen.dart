import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Définition des couleurs en dehors des classes pour qu'elles soient accessibles partout
const Color orangeFlavor = Color(0xFFF36A2D);
const Color violetFlavor = Color(0xFF4B1F5C);

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  final List<Map<String, String>> addresses = [
    {
      'name': 'Maison',
      'full': 'Rue 1.501, Akwa, Douala',
      'type': 'home',
      'phone': '+237 6 55 12 34 56',
    },
    {
      'name': 'Bureau',
      'full': 'Bonanjo Business Center, Douala',
      'type': 'work',
      'phone': '+237 6 99 87 65 43',
    },
    {
      'name': 'Chez maman',
      'full': 'New Bell, Douala',
      'type': 'other',
      'phone': '+237 6 12 34 56 78',
    },
  ];

  void _addNewAddress() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddressForm(),
    );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mes adresses',
          style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: orangeFlavor),
            onPressed: _addNewAddress,
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: addresses.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final address = addresses[index];
          return Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: _buildAddressTypeIcon(address['type']!),
              title: Text(
                address['name']!,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address['full']!),
                  const SizedBox(height: 4),
                  Text(
                    address['phone']!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'default', child: Text('Adresse par défaut')),
                  const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  const PopupMenuItem(
                      value: 'delete', child: Text('Supprimer')),
                ],
                onSelected: (value) {
                  // Logique d'action ici
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'home':
        icon = Icons.home;
        color = Colors.blue;
        break;
      case 'work':
        icon = Icons.business;
        color = Colors.orange;
        break;
      default:
        icon = Icons.location_on;
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class AddressForm extends StatefulWidget {
  const AddressForm({super.key});

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String fullAddress = '';
  String phone = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 15),
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nouvelle adresse',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Nom (Maison, Bureau...)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.label),
              ),
              validator: (value) => value!.isEmpty ? 'Nom requis' : null,
              onSaved: (value) => name = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Adresse complète',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.location_on),
              ),
              validator: (value) => value!.isEmpty ? 'Adresse requise' : null,
              onSaved: (value) => fullAddress = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Téléphone',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => value!.isEmpty ? 'Téléphone requis' : null,
              onSaved: (value) => phone = value!,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Annuler', style: GoogleFonts.poppins()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Adresse ajoutée !')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeFlavor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('Enregistrer', style: GoogleFonts.poppins()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
