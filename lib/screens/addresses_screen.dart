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
  String? _error;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cities = await CityApiService()
          .fetchCities()
          .timeout(const Duration(seconds: 20));
      final snapshot = await _addressCollection
          ?.orderBy('createdAt')
          .get()
          .timeout(const Duration(seconds: 20));

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
                'zoneAreaName':
                    data['delivery_zone_area_name'] as String? ?? '',
                'default': (data['default'] as bool?) ?? false,
                'latitude': (data['latitude'] as num?)?.toDouble(),
                'longitude': (data['longitude'] as num?)?.toDouble(),
                'icon': _iconFromType(data['type'] as String?),
              };
            }).toList() ??
            []);
    } catch (_) {
      _error =
          'Impossible de charger vos adresses. Vérifiez votre connexion et réessayez.';
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

  Future<void> _persistAddress(Map<String, dynamic> address) async {
    final collection = _addressCollection;
    if (collection == null)
      throw StateError('Connectez-vous pour enregistrer votre adresse.');
    final isNew = address['id'] == null;
    final reference =
        isNew ? collection.doc() : collection.doc(address['id'] as String);
    await reference.set({
      'label': address['label'],
      'address': address['address'],
      'city_id': int.tryParse(address['cityId'].toString()),
      'city_name': address['cityName'],
      'delivery_zone_area_id':
          int.tryParse((address['zoneAreaId'] ?? '').toString()),
      'delivery_zone_area_name': address['zoneAreaName'],
      'default': address['default'] == true,
      'type': _typeFromIcon(address['icon'] as IconData),
      'latitude': address['latitude'],
      'longitude': address['longitude'],
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 20));
    address['id'] = reference.id;
  }

  Future<void> _saveAddress({
    int? index,
    required String label,
    required String address,
    required CityModel city,
    DeliveryZoneAreaModel? area,
    double? latitude,
    double? longitude,
  }) async {
    final entry = {
      'id': index != null ? _addresses[index]['id'] : null,
      'label': label,
      'address': address,
      'cityId': city.id,
      'cityName': city.name,
      'zoneAreaId': area?.id,
      'zoneAreaName': area?.name,
      'default': index != null
          ? (_addresses[index]['default'] == true)
          : _addresses.isEmpty,
      'latitude': latitude,
      'longitude': longitude,
      'icon':
          index != null ? _addresses[index]['icon'] : Icons.location_on_rounded,
    };

    await _persistAddress(entry);
    if (!mounted) return;
    setState(() {
      if (index == null) {
        _addresses.add(entry);
      } else {
        _addresses[index] = entry;
      }
    });
  }

  Future<void> _openEditor({int? index}) async {
    try {
      await _showEditor(index: index);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Impossible de charger les secteurs. Réessayez.')));
    }
  }

  Future<void> _showEditor({int? index}) async {
    final existing = index != null ? _addresses[index] : null;
    final labelController =
        TextEditingController(text: existing?['label'] as String? ?? '');
    final addressController =
        TextEditingController(text: existing?['address'] as String? ?? '');

    CityModel? selectedCity = _cities.cast<CityModel?>().firstWhere(
          (city) => city?.id == (existing?['cityId'] ?? ''),
          orElse: () => _cities.isNotEmpty ? _cities.first : null,
        );
    List<DeliveryZoneModel> zones =
        selectedCity != null ? await _zonesForCity(selectedCity.id) : const [];
    DeliveryZoneAreaModel? selectedArea = _findArea(
      zones,
      (existing?['zoneAreaId'] ?? '').toString(),
    );

    if (!mounted) return;
    double? latitude = (existing?['latitude'] as num?)?.toDouble();
    double? longitude = (existing?['longitude'] as num?)?.toDouble();
    bool saving = false;
    bool loadingZones = false;
    String? editorError;
    int zoneVersion = 0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allAreas =
                zones.expand((zone) => zone.areas).toList(growable: false);

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
                      index == null
                          ? 'Ajouter une adresse'
                          : 'Modifier l’adresse',
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: labelController,
                      decoration:
                          const InputDecoration(labelText: 'Nom de l’adresse'),
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
                        final version = ++zoneVersion;
                        setModalState(() {
                          selectedCity = city;
                          selectedArea = null;
                          zones = [];
                          loadingZones = true;
                          editorError = null;
                        });
                        try {
                          final fetchedZones = await _zonesForCity(city.id)
                              .timeout(const Duration(seconds: 20));
                          if (!context.mounted || version != zoneVersion)
                            return;
                          setModalState(() {
                            zones = fetchedZones;
                            loadingZones = false;
                          });
                        } catch (_) {
                          if (!context.mounted || version != zoneVersion)
                            return;
                          setModalState(() {
                            loadingZones = false;
                            editorError =
                                'Impossible de charger les secteurs. Sélectionnez à nouveau la ville.';
                          });
                        }
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
                      decoration: const InputDecoration(
                          labelText: 'Quartier / zone FlavorWay'),
                      onChanged: (area) =>
                          setModalState(() => selectedArea = area),
                    ),
                    if (loadingZones) const LinearProgressIndicator(),
                    const Text(
                        'Pour une livraison FlavorWay, choisissez un secteur. Pour une livraison restaurant, le tarif sera vérifié au résumé.'),
                    if (editorError != null)
                      Text(editorError!,
                          style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration:
                          const InputDecoration(labelText: 'Adresse détaillée'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final currentAddress =
                                  await _getCurrentPositionAddress();
                              if (currentAddress == null) return;
                              addressController.text =
                                  currentAddress['address'] as String;
                              latitude = currentAddress['latitude'] as double?;
                              longitude =
                                  currentAddress['longitude'] as double?;
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
                        onPressed:
                            selectedCity == null || saving || loadingZones
                                ? null
                                : () async {
                                    if (labelController.text.trim().isEmpty ||
                                        addressController.text.trim().isEmpty) {
                                      setModalState(() => editorError =
                                          'Renseignez le nom et l’adresse détaillée.');
                                      return;
                                    }
                                    setModalState(() {
                                      saving = true;
                                      editorError = null;
                                    });
                                    try {
                                      await _saveAddress(
                                        index: index,
                                        label: labelController.text.trim(),
                                        address: addressController.text.trim(),
                                        city: selectedCity!,
                                        area: selectedArea,
                                        latitude: latitude,
                                        longitude: longitude,
                                      );

                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                    } catch (_) {
                                      if (context.mounted)
                                        setModalState(() {
                                          saving = false;
                                          editorError =
                                              'Adresse non enregistrée. Réessayez.';
                                        });
                                    }
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

  DeliveryZoneAreaModel? _findArea(
      List<DeliveryZoneModel> zones, String areaId) {
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
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    final place = placemarks.isNotEmpty ? placemarks.first : null;
    final address = [
      place?.street,
      place?.subLocality,
      place?.locality,
      place?.country,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(', ');

    return {
      'address': address.isNotEmpty
          ? address
          : '${position.latitude}, ${position.longitude}',
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
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!),
                  TextButton(
                      onPressed: _bootstrap, child: const Text('Réessayer'))
                ]))
              : _addresses.isEmpty
                  ? const Center(
                      child: Text('Aucune adresse. Appuyez sur Ajouter.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _addresses.length,
                      itemBuilder: (context, index) {
                        final item = _addresses[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          child: ListTile(
                            onTap: () {
                              if (!_cities
                                  .any((city) => city.id == item['cityId'])) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Ville invalide ou inactive. Modifiez cette adresse.')));
                                return;
                              }
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
                              ]
                                  .whereType<String>()
                                  .where((value) => value.isNotEmpty)
                                  .join(' • '),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                try {
                                  if (value == 'edit') {
                                    await _openEditor(index: index);
                                  } else if (value == 'default') {
                                    final collection = _addressCollection;
                                    if (collection == null) return;
                                    final batch =
                                        FirebaseFirestore.instance.batch();
                                    for (final address in _addresses) {
                                      batch.update(
                                          collection.doc(address['id']), {
                                        'default': address['id'] == item['id']
                                      });
                                    }
                                    await batch
                                        .commit()
                                        .timeout(const Duration(seconds: 20));
                                    if (!mounted) return;
                                    setState(() {
                                      for (final address in _addresses) {
                                        address['default'] =
                                            address['id'] == item['id'];
                                      }
                                    });
                                  } else if (value == 'delete') {
                                    await _addressCollection
                                        ?.doc(item['id'])
                                        .delete()
                                        .timeout(const Duration(seconds: 20));
                                    if (!mounted) return;
                                    setState(() => _addresses.removeWhere(
                                        (address) =>
                                            address['id'] == item['id']));
                                  }
                                } catch (_) {
                                  if (mounted)
                                    ScaffoldMessenger.of(this.context)
                                        .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Modification non enregistrée. Réessayez.')));
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                    value: 'edit', child: Text('Modifier')),
                                PopupMenuItem(
                                    value: 'default',
                                    child: Text('Définir par défaut')),
                                PopupMenuItem(
                                    value: 'delete', child: Text('Supprimer')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
