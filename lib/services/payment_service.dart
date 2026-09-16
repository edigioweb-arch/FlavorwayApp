import 'package:firebase_auth/firebase_auth.dart';

import '../models/payment_model.dart';
import 'api_client.dart';

class PaymentService {
  PaymentService({
    ApiClient? apiClient,
    FirebaseAuth? auth,
  })  : _apiClient = apiClient ?? ApiClient(),
        _auth = auth ?? FirebaseAuth.instance;

  static final PaymentService instance = PaymentService();

  final ApiClient _apiClient;
  final FirebaseAuth _auth;

  Future<PaymentModel> initiatePayment({
    required String orderNumber,
    required String paymentMethod,
    String? phone,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/orders/$orderNumber/payments',
      body: <String, dynamic>{
        'payment_method': _normalizePaymentMethod(paymentMethod),
        'phone': phone,
        'idempotency_key': idempotencyKey,
      },
      headers: await _authHeaders(),
    );

    final payment = PaymentModel.fromJson(
      Map<String, dynamic>.from((response['data'] as Map?) ?? const {}),
    );
    if (payment.orderNumber != orderNumber ||
        payment.internalReference.isEmpty) {
      throw const ApiException(
          statusCode: 502,
          message: 'Réponse de paiement incohérente. Actualisez la commande.');
    }
    return payment;
  }

  Future<PaymentModel?> fetchPaymentStatus(String orderNumber) async {
    final response = await _apiClient.getJson(
      '/api/v1/orders/$orderNumber/payment',
      headers: await _authHeaders(),
    );

    final data = response['data'];
    if (data is! Map) {
      return null;
    }

    return PaymentModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<String, String>> _authHeaders() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Utilisateur non connecté.',
      );
    }

    final token = await user.getIdToken(true);

    return <String, String>{
      'Authorization': 'Bearer $token',
    };
  }

  String _normalizePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'paiement à la livraison':
      case 'cash':
        return 'cash';
      case 'orange money':
        return 'orange_money';
      case 'mtn momo':
        return 'mtn_momo';
      case 'airtel money':
        return 'airtel_money';
      case 'carte bancaire':
        return 'card';
      default:
        return method.toLowerCase().replaceAll(' ', '_');
    }
  }
}
