import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final List<Map<String, dynamic>> addresses = [
    {
      'label': 'Maison',
      'address': '12 Avenue de la Paix, Brazzaville',
      'default': true,
      'icon': Icons.home_rounded,
    },
    {
      'label': 'Bureau',
      'address': 'Tour Mayombe, Centre-ville',
      'default': false,
      'icon': Icons.business_rounded,
    },
  ];

  Future<String?> _getCurrentAddress() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activez la localisation pour utiliser votre position'),
        ),
      );
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission de localisation refusée'),
        ),
      );
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.country,
        ].where((part) => part != null && part.trim().isNotEmpty).join(', ');

        if (parts.isNotEmpty) {
          return parts;
        }
      }
    } catch (_) {}

    return '${position.latitude}, ${position.longitude}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Mes adresses',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAddress,
        label: const Text('Ajouter'),
        icon: const Icon(Icons.add_location_alt_rounded),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: addresses.length,
        itemBuilder: (context, index) {
          final item = addresses[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ListTile(
              leading: Icon(item['icon']),
              title: Text(item['label']),
              subtitle: Text(item['address']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item['default'] == true)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Chip(label: Text('Défaut')),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditAddress(index);
                      }
                      if (value == 'default') {
                        setState(() {
                          for (final address in addresses) {
                            address['default'] = false;
                          }
                          addresses[index]['default'] = true;
                        });
                      }
                      if (value == 'delete') {
                        setState(() {
                          addresses.removeAt(index);
                        });
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifier'),
                      ),
                      const PopupMenuItem(
                        value: 'default',
                        child: Text('Définir par défaut'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer'),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditAddress(int index) {
    final labelController = TextEditingController(
      text: addresses[index]['label'],
    );
    final addressController = TextEditingController(
      text: addresses[index]['address'],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modifier l’adresse',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l’adresse',
                  hintText: 'Maison, Bureau, Autre',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final currentAddress = await _getCurrentAddress();
                    if (currentAddress == null) return;
                    addressController.text = currentAddress;
                  },
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('Utiliser ma position actuelle'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (labelController.text.trim().isEmpty ||
                        addressController.text.trim().isEmpty) {
                      return;
                    }

                    setState(() {
                      addresses[index]['label'] = labelController.text.trim();
                      addresses[index]['address'] = addressController.text.trim();
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('Enregistrer les modifications'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddAddress() {
    final labelController = TextEditingController();
    final addressController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l’adresse',
                  hintText: 'Maison, Bureau, Autre',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final currentAddress = await _getCurrentAddress();
                    if (currentAddress == null) return;
                    addressController.text = currentAddress;
                  },
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('Utiliser ma position actuelle'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (labelController.text.trim().isEmpty ||
                        addressController.text.trim().isEmpty) {
                      return;
                    }

                    setState(() {
                      addresses.add({
                        'label': labelController.text.trim(),
                        'address': addressController.text.trim(),
                        'default': false,
                        'icon': Icons.location_on_rounded,
                      });
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
