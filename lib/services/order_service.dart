import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class TimelineStep {
  final String status;
  final DateTime timestamp;
  final String updatedBy;

  TimelineStep({
    required this.status,
    required this.timestamp,
    required this.updatedBy,
  });

  factory TimelineStep.fromFirestore(Map<String, dynamic> data) {
    return TimelineStep(
      status: data['status'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: data['updatedBy'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'updatedBy': updatedBy,
    };
  }
}

class OrderModel {
  final String orderId;
  final String userId;
  final String restaurantName;
  final String restaurantId;
  final List<Map<String, dynamic>> items;
  final double total;
  final String status;
  final List<TimelineStep> timeline;
  final String deliveryAddress;
  final String paymentMethod;
  final String courierName;
  final String courierPhone;
  final String courierVehicle;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.restaurantName,
    this.restaurantId = '',
    required this.items,
    required this.total,
    required this.status,
    required this.timeline,
    this.deliveryAddress = '',
    this.paymentMethod = '',
    this.courierName = '',
    this.courierPhone = '',
    this.courierVehicle = '',
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromFirestore(String docId, Map<String, dynamic> data) {
    final timelineRaw = data['timeline'] as List<dynamic>? ?? [];
    final timeline = timelineRaw
        .map((e) => TimelineStep.fromFirestore(e as Map<String, dynamic>))
        .toList();

    final itemsRaw = data['items'] as List<dynamic>? ?? [];
    final items =
        itemsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    return OrderModel(
      orderId: docId,
      userId: data['userId'] as String? ?? '',
      restaurantName: data['restaurantName'] as String? ?? '',
      restaurantId: data['restaurantId'] as String? ?? '',
      items: items,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'Commande reçue',
      timeline: timeline,
      deliveryAddress: data['deliveryAddress'] as String? ?? '',
      paymentMethod: data['paymentMethod'] as String? ?? '',
      courierName: data['courierName'] as String? ?? '',
      courierPhone: data['courierPhone'] as String? ?? '',
      courierVehicle: data['courierVehicle'] as String? ?? '',
      note: data['note'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'restaurantName': restaurantName,
      'restaurantId': restaurantId,
      'items': items,
      'total': total,
      'status': status,
      'timeline': timeline.map((t) => t.toFirestore()).toList(),
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'courierName': courierName,
      'courierPhone': courierPhone,
      'courierVehicle': courierVehicle,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isActive => status != 'Livré' && status != 'Annulé';

  TimelineStep get lastTimelineStep => timeline.isNotEmpty
      ? timeline.last
      : TimelineStep(
          status: status,
          timestamp: updatedAt,
          updatedBy: 'system',
        );
}

class OrderService extends ChangeNotifier {
  static final OrderService instance = OrderService._();

  OrderService._();

  final CollectionReference _ordersRef =
      FirebaseFirestore.instance.collection('orders');

  /// Crée une commande dans Firestore lors du checkout.
  Future<String> createOrder({
    required String restaurantName,
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double total,
    required String deliveryAddress,
    required String paymentMethod,
    String note = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final orderId =
        'FLW-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final now = DateTime.now();

    final orderData = {
      'orderId': orderId,
      'userId': user.uid,
      'restaurantName': restaurantName,
      'restaurantId': restaurantId,
      'items': items,
      'total': total,
      'status': 'Commande reçue',
      'timeline': [
        {
          'status': 'Commande reçue',
          'timestamp': Timestamp.fromDate(now),
          'updatedBy': 'system',
        },
      ],
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'courierName': '',
      'courierPhone': '',
      'courierVehicle': '',
      'note': note,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await _ordersRef.doc(orderId).set(orderData);

    notifyListeners();

    NotificationService.instance.addOrderNotification(orderId);

    return orderId;
  }

  /// Récupère une commande par son ID.
  Stream<OrderModel?> orderStream(String orderId) {
    return _ordersRef.doc(orderId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return OrderModel.fromFirestore(
        snapshot.id,
        snapshot.data() as Map<String, dynamic>,
      );
    });
  }

  /// Récupère toutes les commandes actives de l'utilisateur connecté.
  Stream<List<OrderModel>> get activeOrdersStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _ordersRef
        .where('userId', isEqualTo: user.uid)
        .where('status', whereIn: [
          'Commande reçue',
          'En préparation',
          'Coursier en route',
          'En livraison'
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromFirestore(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  ))
              .toList();
        });
  }

  /// Récupère l'historique des commandes de l'utilisateur connecté.
  Stream<List<OrderModel>> get completedOrdersStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _ordersRef
        .where('userId', isEqualTo: user.uid)
        .where('status', whereIn: ['Livré', 'Annulé'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromFirestore(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  ))
              .toList();
        });
  }
}
