class CityModel {
  const CityModel({
    required this.id,
    required this.name,
    required this.countryId,
    required this.countryName,
    required this.countryIsoCode,
    required this.isActive,
    required this.isVisibleInApp,
    required this.launchStatus,
  });

  final String id;
  final String name;
  final String countryId;
  final String countryName;
  final String countryIsoCode;
  final bool isActive;
  final bool isVisibleInApp;
  final String launchStatus;

  bool get isLaunched => launchStatus == 'launched' && isActive;

  String get displayLabel => '$name, $countryName';

  factory CityModel.fromJson(Map<String, dynamic> json) {
    final country = Map<String, dynamic>.from(
      (json['country'] as Map?) ?? const {},
    );

    return CityModel(
      id: '${json['id']}',
      name: (json['name'] ?? '').toString(),
      countryId: '${country['id'] ?? ''}',
      countryName: (country['name'] ?? '').toString(),
      countryIsoCode: (country['iso_code'] ?? '').toString(),
      isActive: json['is_active'] == true,
      isVisibleInApp: json['is_visible_in_app'] != false,
      launchStatus: (json['launch_status'] ?? 'not_launched').toString(),
    );
  }
}
