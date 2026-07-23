import 'package:flutter/material.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService instance = LocaleService._();

  LocaleService._();

  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  bool get isFrench => _locale.languageCode == 'fr';
  bool get isEnglish => _locale.languageCode == 'en';

  void setFrench() {
    _locale = const Locale('fr');
    notifyListeners();
  }

  void setEnglish() {
    _locale = const Locale('en');
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
