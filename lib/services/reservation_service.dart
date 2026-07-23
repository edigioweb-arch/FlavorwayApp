import 'package:flutter/foundation.dart';

import 'notification_service.dart';

class Reservation {
  final String restaurantName;
  final String date;
  final String time;
  final int guests;

  Reservation({
    required this.restaurantName,
    required this.date,
    required this.time,
    required this.guests,
  });
}

class ReservationService extends ChangeNotifier {
  static final ReservationService instance = ReservationService._();

  ReservationService._();

  final List<Reservation> _reservations = [];

  List<Reservation> get reservations => List.unmodifiable(_reservations);

  void addReservation({
    required String restaurantName,
    required String date,
    required String time,
    required int guests,
  }) {
    _reservations.insert(
      0,
      Reservation(
        restaurantName: restaurantName,
        date: date,
        time: time,
        guests: guests,
      ),
    );

    notifyListeners();

    NotificationService.instance.addReservationNotification(restaurantName);
  }

  void cancelReservation(Reservation reservation) {
    _reservations.remove(reservation);
    notifyListeners();
  }

  void clear() {
    _reservations.clear();
    notifyListeners();
  }
}
