import 'package:flutter/foundation.dart';

class UserAuthService extends ChangeNotifier {
  static final UserAuthService instance = UserAuthService._();

  UserAuthService._();

  String _email = 'cynthia@email.com';
  String _password = '123456';

  String get email => _email;
  String get password => _password;

  bool login({
    required String email,
    required String password,
  }) {
    return email.trim().toLowerCase() == _email.toLowerCase() &&
        password.trim() == _password;
  }

  bool updatePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    if (currentPassword.trim() != _password) {
      return false;
    }

    _password = newPassword.trim();
    notifyListeners();
    return true;
  }

  void updateEmail(String email) {
    _email = email.trim();
    notifyListeners();
  }
}
