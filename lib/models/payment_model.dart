class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.orderNumber,
    required this.provider,
    required this.paymentMethod,
    required this.internalReference,
    required this.amount,
    required this.currency,
    required this.status,
    this.providerReference,
    this.failureCode,
    this.failureMessage,
    this.metadata = const {},
  });

  final int id;
  final String orderNumber;
  final String provider;
  final String paymentMethod;
  final String internalReference;
  final String? providerReference;
  final double amount;
  final String currency;
  final String status;
  final String? failureCode;
  final String? failureMessage;
  final Map<String, dynamic> metadata;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNumber: (json['order_number'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString(),
      paymentMethod: (json['payment_method'] ?? '').toString(),
      internalReference: (json['internal_reference'] ?? '').toString(),
      providerReference: json['provider_reference']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'XAF').toString(),
      status: (json['status'] ?? '').toString(),
      failureCode: json['failure_code']?.toString(),
      failureMessage: json['failure_message']?.toString(),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const {},
      ),
    );
  }

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending' || status == 'processing';
  bool get isFailed =>
      status == 'failed' || status == 'expired' || status == 'cancelled';
}
