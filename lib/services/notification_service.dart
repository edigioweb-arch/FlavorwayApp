import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_auth_service.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? type;
  final String? targetId;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.type,
    this.targetId,
    this.isRead = false,
  });
}

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._();

  NotificationService._() {
    _load();
  }

  final List<AppNotification> _notifications = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _notificationsEnabled = true;
  String _selectedMessageSound = 'classic';
  bool _isLoaded = false;

  bool get notificationsEnabled => _notificationsEnabled;
  String get selectedMessageSound => _selectedMessageSound;

  CollectionReference<Map<String, dynamic>>? get _notificationCollection {
    final uid = UserAuthService.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications');
  }

  DocumentReference<Map<String, dynamic>>? get _preferencesDoc {
    final uid = UserAuthService.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications');
  }

  Future<void> _load() async {
    if (_isLoaded) return;
    _isLoaded = true;
    try {
      final preferences = await _preferencesDoc?.get();
      final settings = preferences?.data();
      if (settings != null) {
        _notificationsEnabled =
            (settings['enabled'] as bool?) ?? _notificationsEnabled;
        _selectedMessageSound =
            (settings['sound'] as String?) ?? _selectedMessageSound;
      }

      final snapshot = await _notificationCollection
          ?.orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      if (snapshot != null) {
        _notifications
          ..clear()
          ..addAll(
            snapshot.docs.map((doc) {
              final data = doc.data();
              return AppNotification(
                id: doc.id,
                title: data['title'] as String? ?? '',
                message: data['message'] as String? ?? '',
                createdAt:
                    (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                type: data['type'] as String?,
                targetId: data['targetId'] as String?,
                isRead: (data['isRead'] as bool?) ?? false,
              );
            }),
          );
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    try {
      await _preferencesDoc?.set({
        'enabled': _notificationsEnabled,
        'sound': _selectedMessageSound,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  void addOrderNotification(String orderNumber) {
    addNotification(
      title: 'Commande',
      message: 'Votre commande n°$orderNumber a été enregistrée.',
      type: 'order',
      targetId: orderNumber,
    );
  }

  void addReservationNotification(String restaurant) {
    addNotification(
      title: 'Réservation',
      message: 'Votre réservation chez $restaurant est confirmée.',
      type: 'reservation',
    );
  }

  void addSupportNotification(String message) {
    addNotification(
      title: 'Support FlavorWay',
      message: message,
      type: 'support',
    );
  }

  void addIncomingMessageNotification(
    String conversationTitle, {
    required String conversationId,
  }) {
    if (!_notificationsEnabled) return;

    final soundLabel =
        _selectedMessageSound == 'soft' ? 'Son doux' : 'Son classique';
    _playSelectedSound();
    addNotification(
      title: 'Message reçu',
      message: '$conversationTitle • $soundLabel',
      type: 'message',
      targetId: conversationId,
    );
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  void markAllAsRead() {
    for (final notification in _notifications) {
      notification.isRead = true;
    }
    notifyListeners();
    for (final notification in _notifications) {
      _notificationCollection?.doc(notification.id).update({'isRead': true});
    }
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((item) => item.id == id);

    if (index == -1) return;

    _notifications[index].isRead = true;
    notifyListeners();
    _notificationCollection?.doc(id).update({'isRead': true});
  }

  void addNotification({
    required String title,
    required String message,
    String? type,
    String? targetId,
  }) {
    if (!_notificationsEnabled) return;

    _notifications.insert(
      0,
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        createdAt: DateTime.now(),
        type: type,
        targetId: targetId,
      ),
    );

    notifyListeners();
    _persistNotification(_notifications.first);
  }

  void updatePreferences({
    required bool enabled,
    required String sound,
  }) {
    _notificationsEnabled = enabled;
    _selectedMessageSound = sound;
    notifyListeners();
    _savePreferences();
  }

  Future<void> _persistNotification(AppNotification notification) async {
    try {
      await _notificationCollection?.doc(notification.id).set({
        'title': notification.title,
        'message': notification.message,
        'createdAt': Timestamp.fromDate(notification.createdAt),
        'type': notification.type,
        'targetId': notification.targetId,
        'isRead': notification.isRead,
      });
    } catch (_) {}
  }

  Future<void> previewSelectedSound() async {
    if (!_notificationsEnabled) return;
    await _playSelectedSound();
  }

  Future<void> _playSelectedSound() async {
    final assetPath = _selectedMessageSound == 'soft'
        ? 'sounds/notification_soft.mp3'
        : 'sounds/notification_classic.mp3';

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (_) {}
  }

  void clear() {
    _notifications.clear();
    notifyListeners();
  }
}
