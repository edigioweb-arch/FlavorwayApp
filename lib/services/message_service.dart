import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import 'notification_service.dart';
import 'user_auth_service.dart';

class MessageService extends ChangeNotifier {
  MessageService() {
    _load();
  }

  final List<ConversationModel> _conversations = [
    ConversationModel(
      id: 'support_flavorway',
      title: 'Support FlavorWay',
      avatar: '',
      type: ConversationType.support,
      lastMessage: 'Bienvenue au support FlavorWay.',
      lastMessageTime: DateTime.now(),
      unreadCount: 0,
    ),
    ConversationModel(
      id: 'restaurant_joli_coin',
      title: 'Joli Coin',
      avatar: 'assets/images/restaurants/joli_coin/cover.png',
      type: ConversationType.restaurant,
      lastMessage: 'Bonjour, votre commande est bien reçue.',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 12)),
      unreadCount: 2,
    ),
    ConversationModel(
      id: 'courier_jean_m',
      title: 'Jean M. - Livreur',
      avatar: '',
      type: ConversationType.courier,
      lastMessage: 'Je suis en route vers vous.',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 4)),
      unreadCount: 1,
    ),
  ];

  final Map<String, List<MessageModel>> _messages = {
    'support_flavorway': [
      MessageModel(
        id: 'support_msg_1',
        conversationId: 'support_flavorway',
        senderId: 'support_flavorway',
        senderName: 'Support FlavorWay',
        content: 'Bonjour 👋 Comment pouvons-nous aider ?',
        timestamp: DateTime.now(),
        isMe: false,
        isRead: true,
      ),
    ],
    'restaurant_joli_coin': [
      MessageModel(
        id: 'msg_1',
        conversationId: 'restaurant_joli_coin',
        senderId: 'restaurant_joli_coin',
        senderName: 'Joli Coin',
        content: 'Bonjour, votre commande est bien reçue.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
        isMe: false,
        isRead: false,
      ),
      MessageModel(
        id: 'msg_2',
        conversationId: 'restaurant_joli_coin',
        senderId: 'client_current',
        senderName: 'Vous',
        content: 'Merci, je reste disponible.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 14)),
        isMe: true,
        isRead: true,
      ),
      MessageModel(
        id: 'msg_3',
        conversationId: 'restaurant_joli_coin',
        senderId: 'restaurant_joli_coin',
        senderName: 'Joli Coin',
        content: 'Votre plat est en préparation.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        isMe: false,
        isRead: false,
      ),
    ],
    'courier_jean_m': [
      MessageModel(
        id: 'msg_4',
        conversationId: 'courier_jean_m',
        senderId: 'courier_jean_m',
        senderName: 'Jean M.',
        content: 'Bonjour, je viens de récupérer votre commande.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
        isMe: false,
        isRead: false,
      ),
      MessageModel(
        id: 'msg_5',
        conversationId: 'courier_jean_m',
        senderId: 'courier_jean_m',
        senderName: 'Jean M.',
        content: 'Je suis en route vers vous.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        isMe: false,
        isRead: false,
      ),
    ],
  };
  bool _isLoaded = false;

  CollectionReference<Map<String, dynamic>>? get _conversationCollection {
    final uid = UserAuthService.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('conversations');
  }

  Future<void> _load() async {
    if (_isLoaded) return;
    _isLoaded = true;
    final collection = _conversationCollection;
    if (collection == null) return;

    try {
      final snapshot = await collection.get();
      if (snapshot.docs.isEmpty) {
        await _saveAll();
        return;
      }

      _conversations
        ..clear()
        ..addAll(snapshot.docs.map((doc) {
          final data = doc.data();
          return ConversationModel(
            id: doc.id,
            title: data['title'] as String? ?? 'Conversation',
            avatar: data['avatar'] as String? ?? '',
            type: _typeFromString(data['type'] as String?),
            lastMessage: data['lastMessage'] as String? ?? '',
            lastMessageTime:
                (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
            unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
          );
        }));

      _messages.clear();
      for (final doc in snapshot.docs) {
        final messagesSnapshot = await doc.reference
            .collection('messages')
            .orderBy('timestamp')
            .get();
        _messages[doc.id] = messagesSnapshot.docs.map((messageDoc) {
          final data = messageDoc.data();
          return MessageModel(
            id: messageDoc.id,
            conversationId: doc.id,
            senderId: data['senderId'] as String? ?? '',
            senderName: data['senderName'] as String? ?? '',
            content: data['content'] as String? ?? '',
            timestamp:
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isMe: (data['isMe'] as bool?) ?? false,
            isRead: (data['isRead'] as bool?) ?? false,
            imageUrl: data['imageUrl'] as String?,
            latitude: (data['latitude'] as num?)?.toDouble(),
            longitude: (data['longitude'] as num?)?.toDouble(),
          );
        }).toList();
      }

      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveAll() async {
    final collection = _conversationCollection;
    if (collection == null) return;

    try {
      for (final conversation in _conversations) {
        await collection.doc(conversation.id).set({
          'title': conversation.title,
          'avatar': conversation.avatar,
          'type': conversation.type.name,
          'lastMessage': conversation.lastMessage,
          'lastMessageTime': Timestamp.fromDate(conversation.lastMessageTime),
          'unreadCount': conversation.unreadCount,
        });

        final messagesCollection =
            collection.doc(conversation.id).collection('messages');
        final existing = await messagesCollection.get();
        for (final doc in existing.docs) {
          await doc.reference.delete();
        }
        for (final message in _messages[conversation.id] ?? []) {
          await messagesCollection.doc(message.id).set({
            'senderId': message.senderId,
            'senderName': message.senderName,
            'content': message.content,
            'timestamp': Timestamp.fromDate(message.timestamp),
            'isMe': message.isMe,
            'isRead': message.isRead,
            'imageUrl': message.imageUrl,
            'latitude': message.latitude,
            'longitude': message.longitude,
          });
        }
      }
    } catch (_) {}
  }

  ConversationType _typeFromString(String? value) {
    switch (value) {
      case 'courier':
        return ConversationType.courier;
      case 'support':
        return ConversationType.support;
      default:
        return ConversationType.restaurant;
    }
  }

  List<ConversationModel> get conversations =>
      List.unmodifiable(_conversations);

  int get totalUnreadCount {
    return _conversations.fold<int>(
      0,
      (total, conversation) => total + conversation.unreadCount,
    );
  }

  List<MessageModel> messagesFor(String conversationId) {
    return List.unmodifiable(_messages[conversationId] ?? []);
  }

  ConversationModel? conversationById(String conversationId) {
    try {
      return _conversations.firstWhere((item) => item.id == conversationId);
    } catch (_) {
      return null;
    }
  }

  void sendTextMessage({
    required String conversationId,
    required String content,
  }) {
    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) return;

    final message = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: 'client_current',
      senderName: 'Vous',
      content: trimmedContent,
      timestamp: DateTime.now(),
      isMe: true,
      isRead: true,
    );

    _messages.putIfAbsent(conversationId, () => []);
    _messages[conversationId]!.add(message);
    _updateConversationPreview(
      conversationId: conversationId,
      lastMessage: trimmedContent,
      unreadCount: 0,
    );

    final conversation = conversationById(conversationId);

    if (conversation != null) {
      NotificationService.instance.addNotification(
        title: 'Message envoyé',
        message: 'Conversation avec ${conversation.title}',
        type: 'message',
        targetId: conversationId,
      );
    }
    _saveAll();
  }

  void sendImageMessage({
    required String conversationId,
    required String imagePath,
  }) {
    final message = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: 'client_current',
      senderName: 'Vous',
      content: 'Image envoyée',
      timestamp: DateTime.now(),
      isMe: true,
      isRead: true,
      imageUrl: imagePath,
    );

    _messages.putIfAbsent(conversationId, () => []);
    _messages[conversationId]!.add(message);
    _updateConversationPreview(
      conversationId: conversationId,
      lastMessage: '📷 Image envoyée',
      unreadCount: 0,
    );

    final conversation = conversationById(conversationId);

    if (conversation != null) {
      NotificationService.instance.addNotification(
        title: 'Image envoyée',
        message: 'Conversation avec ${conversation.title}',
        type: 'message',
        targetId: conversationId,
      );
    }
    _saveAll();
  }

  void sendLocationMessage({
    required String conversationId,
    required double latitude,
    required double longitude,
  }) {
    final message = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: 'client_current',
      senderName: 'Vous',
      content: 'Position partagée',
      timestamp: DateTime.now(),
      isMe: true,
      isRead: true,
      latitude: latitude,
      longitude: longitude,
    );

    _messages.putIfAbsent(conversationId, () => []);
    _messages[conversationId]!.add(message);
    _updateConversationPreview(
      conversationId: conversationId,
      lastMessage: '📍 Position partagée',
      unreadCount: 0,
    );

    final conversation = conversationById(conversationId);

    if (conversation != null) {
      NotificationService.instance.addNotification(
        title: 'Position partagée',
        message: 'Conversation avec ${conversation.title}',
        type: 'message',
        targetId: conversationId,
      );
    }
    _saveAll();
  }

  void sendSupportMessage(String content) {
    sendTextMessage(
      conversationId: 'support_flavorway',
      content: content,
    );

    NotificationService.instance.addSupportNotification(
      'Nouveau message envoyé au support.',
    );
  }

  void receiveTextMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
  }) {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) return;

    final message = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: trimmedContent,
      timestamp: DateTime.now(),
      isMe: false,
      isRead: false,
    );

    _messages.putIfAbsent(conversationId, () => []);
    _messages[conversationId]!.add(message);

    final conversation = conversationById(conversationId);
    if (conversation != null) {
      _updateConversationPreview(
        conversationId: conversationId,
        lastMessage: trimmedContent,
        unreadCount: conversation.unreadCount + 1,
      );
      NotificationService.instance.addIncomingMessageNotification(
        conversation.title,
        conversationId: conversationId,
      );
    }
    _saveAll();
  }

  void markAsRead(String conversationId) {
    final index =
        _conversations.indexWhere((item) => item.id == conversationId);

    if (index == -1) return;

    final current = _conversations[index];
    _conversations[index] = ConversationModel(
      id: current.id,
      title: current.title,
      avatar: current.avatar,
      type: current.type,
      lastMessage: current.lastMessage,
      lastMessageTime: current.lastMessageTime,
      unreadCount: 0,
    );

    final messages = _messages[conversationId];
    if (messages != null) {
      _messages[conversationId] = messages
          .map(
            (message) => message.copyWith(isRead: true),
          )
          .toList();
    }

    notifyListeners();
    _saveAll();
  }

  void _updateConversationPreview({
    required String conversationId,
    required String lastMessage,
    required int unreadCount,
  }) {
    final index =
        _conversations.indexWhere((item) => item.id == conversationId);

    if (index == -1) return;

    final current = _conversations[index];
    _conversations[index] = ConversationModel(
      id: current.id,
      title: current.title,
      avatar: current.avatar,
      type: current.type,
      lastMessage: lastMessage,
      lastMessageTime: DateTime.now(),
      unreadCount: unreadCount,
    );

    notifyListeners();
    _saveAll();
  }
}
