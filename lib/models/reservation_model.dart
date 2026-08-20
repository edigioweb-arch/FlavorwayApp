class ReservationTimelineStep {
  const ReservationTimelineStep({
    required this.status,
    required this.source,
    required this.changedAt,
  });

  final String status;
  final String source;
  final DateTime changedAt;

  factory ReservationTimelineStep.fromJson(Map<String, dynamic> json) {
    return ReservationTimelineStep(
      status: (json['to_status'] ?? '').toString(),
      source: (json['source'] ?? 'system').toString(),
      changedAt: DateTime.tryParse((json['changed_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class ReservationModel {
  const ReservationModel({
    required this.id,
    required this.reservationNumber,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantPhone,
    required this.status,
    required this.reservationDate,
    required this.reservationTime,
    required this.partySize,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.notes,
    required this.specialRequests,
    required this.rejectionReason,
    required this.cancellationReason,
    required this.createdAt,
    required this.timeline,
  });

  final int id;
  final String reservationNumber;
  final String restaurantId;
  final String restaurantName;
  final String restaurantAddress;
  final String restaurantPhone;
  final String status;
  final String reservationDate;
  final String reservationTime;
  final int partySize;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String notes;
  final String specialRequests;
  final String? rejectionReason;
  final String? cancellationReason;
  final DateTime createdAt;
  final List<ReservationTimelineStep> timeline;

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final restaurant = Map<String, dynamic>.from(
      (json['restaurant'] as Map?) ?? const {},
    );
    final customer = Map<String, dynamic>.from(
      (json['customer'] as Map?) ?? const {},
    );
    final rawHistory = (json['status_history'] as List?) ?? const [];

    return ReservationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      reservationNumber: (json['reservation_number'] ?? '').toString(),
      restaurantId: (restaurant['id'] ?? '').toString(),
      restaurantName: (restaurant['name'] ?? 'Restaurant').toString(),
      restaurantAddress: (restaurant['address'] ?? '').toString(),
      restaurantPhone: (restaurant['phone'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      reservationDate: (json['reservation_date'] ?? '').toString(),
      reservationTime: (json['reservation_time'] ?? '').toString(),
      partySize: (json['party_size'] as num?)?.toInt() ?? 0,
      customerName: (customer['name'] ?? '').toString(),
      customerPhone: customer['phone']?.toString(),
      customerEmail: customer['email']?.toString(),
      notes: (json['notes'] ?? '').toString(),
      specialRequests: (json['special_requests'] ?? '').toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      timeline: rawHistory
          .whereType<Map>()
          .map((item) => ReservationTimelineStep.fromJson(
              Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }

  bool get isUpcoming => status == 'pending' || status == 'confirmed';

  String get displayStatus {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'rejected':
        return 'Refusée';
      case 'cancelled_by_client':
        return 'Annulée par vous';
      case 'cancelled_by_restaurant':
        return 'Annulée par le restaurant';
      case 'honored':
        return 'Honorée';
      case 'no_show':
        return 'No-show';
      default:
        return status;
    }
  }
}
