import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_auth_service.dart';

class PaymentMethod {
  PaymentMethod({
    required this.name,
    required this.subtitle,
    required this.type,
  });

  final String name;
  final String subtitle;
  final String type;
}

class PaymentMethodService extends ChangeNotifier {
  static final PaymentMethodService instance = PaymentMethodService._();

  PaymentMethodService._() {
    _load();
  }

  final List<PaymentMethod> _methods = [
    PaymentMethod(name: 'Airtel Money', subtitle: '1234', type: 'orange'),
    PaymentMethod(name: 'MTN MoMo', subtitle: '5678', type: 'mtn'),
    PaymentMethod(name: 'Visa ****9012', subtitle: '9012', type: 'visa'),
    PaymentMethod(
      name: 'Mastercard',
      subtitle: '2234 5678 9020',
      type: 'mastercard',
    ),
    PaymentMethod(
      name: 'Paiement à la livraison',
      subtitle: '',
      type: 'cash',
    ),
  ];

  int _selectedIndex = 3;
  bool _isLoaded = false;

  List<PaymentMethod> get methods => List.unmodifiable(_methods);
  int get selectedIndex => _selectedIndex;
  PaymentMethod get selectedMethod => _methods[_selectedIndex];

  CollectionReference<Map<String, dynamic>>? get _paymentCollection {
    final uid = UserAuthService.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('payment_methods');
  }

  Future<void> _load() async {
    if (_isLoaded) return;
    _isLoaded = true;
    final collection = _paymentCollection;
    if (collection == null) return;

    try {
      final snapshot = await collection.orderBy('createdAt').get();
      if (snapshot.docs.isEmpty) {
        await _saveAll();
        return;
      }

      _methods
        ..clear()
        ..addAll(
          snapshot.docs.map((doc) {
            final data = doc.data();
            return PaymentMethod(
              name: data['name'] as String? ?? 'Paiement',
              subtitle: data['subtitle'] as String? ?? '',
              type: data['type'] as String? ?? 'card',
            );
          }),
        );

      final selectedDoc = snapshot.docs.indexWhere(
        (doc) => (doc.data()['isSelected'] as bool?) ?? false,
      );
      if (selectedDoc >= 0) {
        _selectedIndex = selectedDoc;
      } else if (_methods.isNotEmpty) {
        _selectedIndex = 0;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveAll() async {
    final collection = _paymentCollection;
    if (collection == null) return;

    try {
      final existing = await collection.get();
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }

      for (var i = 0; i < _methods.length; i++) {
        final method = _methods[i];
        await collection.add({
          'name': method.name,
          'subtitle': method.subtitle,
          'type': method.type,
          'isSelected': i == _selectedIndex,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  void selectMethod(int index) {
    if (index < 0 || index >= _methods.length) return;
    _selectedIndex = index;
    notifyListeners();
    _saveAll();
  }

  void addCard(String cardNumber) {
    final suffix = cardNumber.length >= 4
        ? cardNumber.substring(cardNumber.length - 4)
        : cardNumber;
    _methods.insert(
      3,
      PaymentMethod(
        name: 'Nouvelle carte',
        subtitle: '**** $suffix',
        type: 'card',
      ),
    );
    _selectedIndex = 3;
    notifyListeners();
    _saveAll();
  }
}
