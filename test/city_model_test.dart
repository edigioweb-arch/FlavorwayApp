import 'package:flavorapps/models/city_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CityModel parses Laravel payload', () {
    final city = CityModel.fromJson({
      'id': 1,
      'name': 'Brazzaville',
      'slug': 'brazzaville',
      'is_active': true,
      'is_visible_in_app': true,
      'launch_status': 'launched',
      'country': {
        'id': 10,
        'name': 'Congo',
        'iso_code': 'CG',
      },
    });

    expect(city.id, '1');
    expect(city.name, 'Brazzaville');
    expect(city.countryIsoCode, 'CG');
    expect(city.isLaunched, isTrue);
  });
}
