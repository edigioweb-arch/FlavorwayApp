import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/city_model.dart';
import '../models/delivery_zone_model.dart';
import '../services/city_api_service.dart';
import '../services/delivery_zone_api_service.dart';
import '../services/user_auth_service.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final List<Map<String, dynamic>> _addresses = [];
  final List<CityModel> _cities = [];
  final Map<String, List<DeliveryZoneModel>> _zonesByCity = {};
  bool _loading = true;

  CollectionReference<Map<String, dynamic>>? get _addressCollection {
    final uid = UserAuthService.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses');
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      final cities = await CityApiService().fetchCities();
      final snapshot = await _addressCollection?.orderBy('createdAt').get();

      _cities
        ..clear()
        ..addAll(cities);

      _addresses
        ..clear()
        ..addAll(snapshot?.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'label': data['label'] as String? ?? 'Adresse',
                'address': data['address'] as String? ?? '',
                'cityId': '${data['city_id'] ?? ''}',
                'cityName': data['city_name'] as String? ?? '',
                'zoneAreaId': '${data['delivery_zone_area_id'] ?? ''}',
                'zoneAreaName': data['delivery_zone_area_name'] as String? ?? '',
                'default': (data['default'] as bool?) ?? false,
                'latitude': (data['latitude'] as num?)?.toDouble(),
                'longitude': (data['longitude'] as num?)?.toDouble(),
                'icon': _iconFromType(data['type'] as String?),
              };
            }).toList() ??
            []);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  IconData _iconFromType(String? type) {
    switch (type) {
      case 'work':
        return Icons.business_rounded;
      case 'other':
        return Icons.location_on_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  String _typeFromIcon(IconData icon) {
    if (icon == Icons.business_rounded) return 'work';
    if (icon == Icons.location_on_rounded) return 'other';
    return 'home';
  }

  Future<List<DeliveryZoneModel>> _zonesForCity(String cityId) async {
    if (_zonesByCity.containsKey(cityId)) {
      return _zonesByCity[cityId]!;
    }

    final zones = await DeliveryZoneApiService().fetchZonesForCity(cityId);
    _zonesByCity[cityId] = zones;
    return zones;
  }

  Future<void> _persistAddresses() async {
    final collection = _addressCollection;
    if (collection == null) return;

    final existing = await collection.get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }

    for (final address in _addresses) {
      final docId = (address['id'] as String?)?.isNotEmpty == true
          ? address['id'] as String
          : collection.doc().id;
      address['id'] = docId;
      await collection.doc(docId).set({
        'label': address['label'],
        'address': address['address'],
        'city_id': int.tryParse((address['cityId'] ?? '').toString()),
        'city_name': address['cityName'],
        'delivery_zone_area_id': int.tryParse((address['zoneAreaId'] ?? '').toString()),
        'delivery_zone_area_name': address['zoneAreaName'],
        'default': address['default'] == true,
        'type': _typeFromIcon(address['icon'] as IconData),
        'latitude': address['latitude'],
        'longitude': address['longitude'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _saveAddress({
    int? index,
    required String label,
    required String address,
    required CityModel city,
    required DeliveryZoneAreaModel area,
    double? latitude,
    double? longitude,
  }) async {
    final entry = {
      'id': index != null ? _addresses[index]['id'] : null,
      'label': label,
      'address': address,
      'cityId': city.id,
      'cityName': city.name,
      'zoneAreaId': area.id,
      'zoneAreaName': area.name,
      'default': index != null ? (_addresses[index]['default'] == true) : _addresses.isEmpty,
      'latitude': latitude,
      'longitude': longitude,
      'icon': index != null ? _addresses[index]['icon'] : Icons.location_on_rounded,
    };

    setState(() {
      if (index == null) {
        _addresses.add(entry);
      } else {
        _addresses[index] = entry;
      }
    });

    await _persistAddresses();
  }

  Future<void> _openEditor({int? index}) async {
    final existing = index != null ? _addresses[index] : null;
    final labelController = TextEditingController(text: existing?['label'] as String? ?? '');
    final addressController = TextEditingController(text: existing?['address'] as String? ?? '');

    CityModel? selectedCity = _cities.cast<CityModel?>().firstWhere(
          (city) => city?.id == (existing?['cityId'] ?? ''),
          orElse: () => _cities.isNotEmpty ? _cities.first : null,
        );
    List<DeliveryZoneModel> zones = selectedCity != null ? await _zonesForCity(selectedCity.id) : const [];
    DeliveryZoneAreaModel? selectedArea = _findArea(
      zones,
      (existing?['zoneAreaId'] ?? '').toString(),
    );

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allAreas = zones.expand((zone) => zone.areas).toList(growable: false);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      index == null ? 'Ajouter une adresse' : 'Modifier l’adresse',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(labelText: 'Nom de l’adresse'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CityModel>(
                      value: selectedCity,
                      items: _cities
                          .map(
                            (city) => DropdownMenuItem<CityModel>(
                              value: city,
                              child: Text(city.displayLabel),
                            ),
                          )
                          .toList(growable: false),
                      decoration: const InputDecoration(labelText: 'Ville'),
                      onChanged: (city) async {
                        if (city == null) return;
                        final fetchedZones = await _zonesForCity(city.id);
                        if (!mounted) return;
                        setModalState(() {
                          selectedCity = city;
                          zones = fetchedZones;
                          selectedArea = fetchedZones.isNotEmpty && fetchedZones.first.areas.isNotEmpty
                              ? fetchedZones.first.areas.first
                              : null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DeliveryZoneAreaModel>(
                      value: selectedArea,
                      items: allAreas
                          .map(
                            (area) => DropdownMenuItem<DeliveryZoneAreaModel>(
                              value: area,
                              child: Text(area.name),
                            ),
                          )
                          .toList(growable: false),
                      decoration: const InputDecoration(labelText: 'Quartier / zone FlavorWay'),
                      onChanged: (area) => setModalState(() => selectedArea = area),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Adresse détaillée'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final currentAddress = await _getCurrentPositionAddress();
                              if (currentAddress == null) return;
                              addressController.text = currentAddress['address'] as String;
                            },
                            icon: const Icon(Icons.my_location_rounded),
                            label: const Text('Utiliser ma position'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedCity == null || selectedArea == null
                            ? null
                            : () async {
                                if (labelController.text.trim().isEmpty || addressController.text.trim().isEmpty) {
                                  return;
                                }

                                await _saveAddress(
                                  index: index,
                                  label: labelController.text.trim(),
                                  address: addressController.text.trim(),
                                  city: selectedCity!,
                                  area: selectedArea!,
                                );

                                if (!context.mounted) return;
                                Navigator.pop(context);
                              },
                        child: Text(index == null ? 'Ajouter' : 'Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  DeliveryZoneAreaModel? _findArea(List<DeliveryZoneModel> zones, String areaId) {
    for (final zone in zones) {
      for (final area in zone.areas) {
        if (area.id == areaId) {
          return area;
        }
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _getCurrentPositionAddress() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    final place = placemarks.isNotEmpty ? placemarks.first : null;
    final address = [
      place?.street,
      place?.subLocality,
      place?.locality,
      place?.country,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(', ');

    return {
      'address': address.isNotEmpty ? address : '${position.latitude}, ${position.longitude}',
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
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
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        label: const Text('Ajouter'),
        icon: const Icon(Icons.add_location_alt_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final item = _addresses[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: ListTile(
                    onTap: () {
                      Navigator.pop(context, {
                        'name': item['label'],
                        'full': item['address'],
                        'city_id': item['cityId'],
                        'city_name': item['cityName'],
                        'delivery_zone_area_id': item['zoneAreaId'],
                        'delivery_zone_area_name': item['zoneAreaName'],
                        'latitude': item['latitude'],
                        'longitude': item['longitude'],
                      });
                    },
                    leading: Icon(item['icon'] as IconData),
                    title: Text(item['label'] as String),
                    subtitle: Text(
                      [
                        item['address'],
                        item['cityName'],
                        item['zoneAreaName'],
                      ].whereType<String>().where((value) => value.isNotEmpty).join(' • '),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _openEditor(index: index);
                        } else if (value == 'default') {
                          setState(() {
                            for (final address in _addresses) {
                              address['default'] = false;
                            }
                            _addresses[index]['default'] = true;
                          });
                          await _persistAddresses();
                        } else if (value == 'delete') {
                          setState(() => _addresses.removeAt(index));
                          await _persistAddresses();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Modifier')),
                        PopupMenuItem(value: 'default', child: Text('Définir par défaut')),
                        PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
