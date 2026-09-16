import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification_model.dart';
import '../firebase_options.dart';
import 'api_client.dart';
import 'notification_navigation_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._();

  NotificationService._({
    ApiClient? apiClient,
    FirebaseAuth? auth,
    FirebaseMessaging? messaging,
  })  : _apiClient = apiClient ?? ApiClient(),
        _auth = auth ?? FirebaseAuth.instance,
        _messaging = messaging ?? FirebaseMessaging.instance {
    _authSubscription = _auth.authStateChanges().listen(_handleAuthChanged);
  }

  final ApiClient _apiClient;
  final FirebaseAuth _auth;
  final FirebaseMessaging _messaging;
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  final List<AppNotificationModel> _notifications = [];
  bool _notificationsEnabled = true;
  String _selectedMessageSound = 'classic';
  bool _initialized = false;
  bool _isBootstrapping = false;
  String? _currentDeviceToken;
  int _unreadCount = 0;

  bool get notificationsEnabled => _notificationsEnabled;
  String get selectedMessageSound => _selectedMessageSound;
  List<AppNotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;

  void _debugLog(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(message);
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermissionIfNeeded();

    FirebaseMessaging.onMessage.listen((message) async {
      await _handleIncomingMessage(message, navigate: false, showBanner: true);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _handleIncomingMessage(message, navigate: true, showBanner: false);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleIncomingMessage(
        initialMessage,
        navigate: true,
        showBanner: false,
      );
    }

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      _currentDeviceToken = token;
      await registerCurrentDeviceToken(tokenOverride: token);
    });

    await _handleAuthChanged(_auth.currentUser);
  }

  Future<void> _handleAuthChanged(User? user) async {
    if (_isBootstrapping) return;
    _isBootstrapping = true;

    try {
      if (user == null) {
        _notifications.clear();
        _unreadCount = 0;
        notifyListeners();
        return;
      }

      await _requestPermissionIfNeeded();
      final token = await _messaging.getToken();
      _currentDeviceToken = token;
      if (token != null && token.isNotEmpty) {
        await registerCurrentDeviceToken(tokenOverride: token);
      }
      await fetchNotifications();
    } catch (error) {
      _debugLog('Bootstrap notifications ignoré: $error');
      // On ne bloque pas l'application si FCM n'est pas disponible localement.
    } finally {
      _isBootstrapping = false;
    }
  }

  Future<void> fetchNotifications() async {
    final response = await _apiClient.getJson(
      '/api/v1/notifications',
      headers: await _authHeaders(),
    );

    final data = (response['data'] as List?) ?? const [];
    _notifications
      ..clear()
      ..addAll(
        data.whereType<Map>().map((item) =>
            AppNotificationModel.fromJson(Map<String, dynamic>.from(item))),
      );

    final meta =
        Map<String, dynamic>.from((response['meta'] as Map?) ?? const {});
    _unreadCount = (meta['unread_count'] as num?)?.toInt() ??
        _notifications.where((item) => !item.isRead).length;

    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    await _apiClient.postJson(
      '/api/v1/notifications/read-all',
      headers: await _authHeaders(),
    );

    for (var index = 0; index < _notifications.length; index++) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> markAsRead(int id) async {
    await _apiClient.postJson(
      '/api/v1/notifications/$id/read',
      headers: await _authHeaders(),
    );

    final index = _notifications.indexWhere((item) => item.id == id);
    if (index == -1) return;

    if (!_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, 1 << 30);
      notifyListeners();
    }
  }

  Future<void> registerCurrentDeviceToken({String? tokenOverride}) async {
    final token =
        tokenOverride ?? _currentDeviceToken ?? await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _apiClient.postJson(
      '/api/v1/device-tokens',
      headers: await _authHeaders(),
      body: {
        'token': token,
        'platform': _platformName,
        'device_name': null,
        'app_version': null,
      },
    );

    _currentDeviceToken = token;
  }

  Future<void> deactivateCurrentDeviceToken() async {
    final token = _currentDeviceToken;
    if (token == null || token.isEmpty) return;

    try {
      await _apiClient.postJson(
        '/api/v1/device-tokens/deactivate',
        headers: await _authHeaders(),
        body: {'token': token},
      );
    } catch (error) {
      _debugLog('Désactivation token FCM ignorée au logout: $error');
      // Logout ne doit pas être bloqué par un échec réseau.
    }
  }

  void addNotification({
    required String title,
    required String message,
    String? type,
    String? targetId,
  }) {
    final local = AppNotificationModel(
      id: DateTime.now().millisecondsSinceEpoch,
      type: type ?? 'generic',
      title: title,
      body: message,
      data: {
        if (targetId != null) 'target_id': targetId,
        'type': type ?? 'generic',
      },
      isRead: false,
      createdAt: DateTime.now(),
    );

    _notifications.insert(0, local);
    _unreadCount += 1;
    notifyListeners();
  }

  void addOrderNotification(String orderNumber) {
    addNotification(
      title: 'Commande',
      message: 'Votre commande $orderNumber a été enregistrée.',
      type: 'order_created',
      targetId: orderNumber,
    );
  }

  void addReservationNotification(String restaurant) {
    addNotification(
      title: 'Réservation',
      message: 'Votre réservation chez $restaurant a été enregistrée.',
      type: 'reservation_created',
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
    addNotification(
      title: 'Message reçu',
      message: conversationTitle,
      type: 'message',
      targetId: conversationId,
    );
  }

  void updatePreferences({
    required bool enabled,
    required String sound,
  }) {
    _notificationsEnabled = enabled;
    _selectedMessageSound = sound;
    notifyListeners();
  }

  Future<void> previewSelectedSound() async {
    if (!_notificationsEnabled) return;
    await _playSelectedSound();
  }

  Future<void> _handleIncomingMessage(
    RemoteMessage message, {
    required bool navigate,
    required bool showBanner,
  }) async {
    if (navigate) {
      NotificationNavigationService.instance
          .handlePayload(Map<String, dynamic>.from(message.data));
    }
    final parsed = _mapRemoteMessage(message);

    if (parsed == null) {
      return;
    }

    _notifications.insert(0, parsed);
    if (!parsed.isRead) {
      _unreadCount += 1;
    }
    notifyListeners();

    if (showBanner && _notificationsEnabled) {
      NotificationNavigationService.instance.showForegroundBanner(
          parsed.title, parsed.body,
          payload: parsed.data);
      await _playSelectedSound();
    }
  }

  AppNotificationModel? _mapRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = Map<String, dynamic>.from(message.data);
    final title = notification?.title ?? (data['title'] ?? '').toString();
    final body = notification?.body ?? (data['body'] ?? '').toString();

    if (title.trim().isEmpty && body.trim().isEmpty) {
      return null;
    }

    return AppNotificationModel(
      id: int.tryParse((data['notification_id'] ?? '0').toString()) ??
          DateTime.now().millisecondsSinceEpoch,
      type: (data['type'] ?? 'generic').toString(),
      title: title,
      body: body,
      data: data,
      isRead: false,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _requestPermissionIfNeeded() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _playSelectedSound() async {
    final assetPath = _selectedMessageSound == 'soft'
        ? 'sounds/notification_soft.mp3'
        : 'sounds/notification_classic.mp3';

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (error) {
      _debugLog('Lecture son notification indisponible: $error');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
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

  String get _platformName {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
