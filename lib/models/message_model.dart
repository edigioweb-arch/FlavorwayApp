

enum ConversationType {
  restaurant,
  courier,
  support,
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final bool isRead;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isMe,
    this.isRead = false,
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  MessageModel copyWith({
    bool? isRead,
  }) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: timestamp,
      isMe: isMe,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class ConversationModel {
  final String id;
  final String title;
  final String avatar;
  final ConversationType type;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.title,
    required this.avatar,
    required this.type,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });
}