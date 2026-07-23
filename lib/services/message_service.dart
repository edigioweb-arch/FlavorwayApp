import 'package:flutter/material.dart';
import '../models/message_model.dart';
import 'notification_service.dart';

class MessageService extends ChangeNotifier {
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
      );
    }
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
      );
    }
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
      );
    }
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
  }
}
