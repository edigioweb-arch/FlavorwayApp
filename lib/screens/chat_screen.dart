

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color lightBackground = Color(0xFFF8F8F8);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageService>().markAsRead(widget.conversationId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _sendTextMessage() {
    final content = _messageController.text.trim();

    if (content.isEmpty) return;

    context.read<MessageService>().sendTextMessage(
          conversationId: widget.conversationId,
          content: content,
        );

    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _sendImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1000,
    );

    if (image == null) return;

    context.read<MessageService>().sendImageMessage(
          conversationId: widget.conversationId,
          imagePath: image.path,
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _sendLocation() {
    context.read<MessageService>().sendLocationMessage(
          conversationId: widget.conversationId,
          latitude: -4.2634,
          longitude: 15.2429,
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ajouter un élément',
                  style: GoogleFonts.poppins(
                    color: violetFlavor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _attachmentTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Envoyer une image',
                  subtitle: 'Choisir depuis la galerie',
                  onTap: () {
                    Navigator.maybePop(context);
                    _sendImage(ImageSource.gallery);
                  },
                ),
                _attachmentTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Prendre une photo',
                  subtitle: 'Utiliser la caméra',
                  onTap: () {
                    Navigator.maybePop(context);
                    _sendImage(ImageSource.camera);
                  },
                ),
                _attachmentTile(
                  icon: Icons.location_on_outlined,
                  title: 'Partager ma position',
                  subtitle: 'Envoyer la localisation actuelle',
                  onTap: () {
                    Navigator.maybePop(context);
                    _sendLocation();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attachmentTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: orangeFlavor.withOpacity(0.12),
        child: Icon(icon, color: orangeFlavor),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageService>(
      builder: (context, messageService, child) {
        final conversation = messageService.conversationById(widget.conversationId);
        final messages = messageService.messagesFor(widget.conversationId);

        return Scaffold(
          backgroundColor: lightBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: violetFlavor,
              onPressed: () => Navigator.maybePop(context),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                _conversationAvatar(conversation),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation?.title ?? 'Conversation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: violetFlavor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        conversation?.type == ConversationType.courier
                            ? 'Livreur • En ligne'
                            : 'Restaurant • En ligne',
                        style: GoogleFonts.poppins(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appel bientôt disponible'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.phone_rounded),
                color: orangeFlavor,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? _emptyConversation()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _messageBubble(messages[index]);
                        },
                      ),
              ),
              _messageInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _conversationAvatar(ConversationModel? conversation) {
    final avatar = conversation?.avatar ?? '';

    if (avatar.startsWith('assets/')) {
      return ClipOval(
        child: Image.asset(
          avatar,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _avatarFallback(conversation),
        ),
      );
    }

    return _avatarFallback(conversation);
  }

  Widget _avatarFallback(ConversationModel? conversation) {
    return CircleAvatar(
      radius: 21,
      backgroundColor: orangeFlavor.withOpacity(0.12),
      child: Icon(
        conversation?.type == ConversationType.courier
            ? Icons.delivery_dining_rounded
            : Icons.restaurant_rounded,
        color: orangeFlavor,
      ),
    );
  }

  Widget _emptyConversation() {
    return Center(
      child: Text(
        'Aucun message pour le moment',
        style: GoogleFonts.poppins(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _messageBubble(MessageModel message) {
    final isMe = message.isMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? orangeFlavor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(message.imageUrl!),
                  width: 220,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (message.latitude != null && message.longitude != null) ...[
              Container(
                width: 220,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white.withOpacity(0.18) : lightBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: isMe ? Colors.white : orangeFlavor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Position partagée\n${message.latitude}, ${message.longitude}',
                        style: GoogleFonts.poppins(
                          color: isMe ? Colors.white : violetFlavor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message.content,
              style: GoogleFonts.poppins(
                color: isMe ? Colors.white : const Color(0xFF1F1F1F),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _formatTime(message.timestamp),
              style: GoogleFonts.poppins(
                color: isMe ? Colors.white.withOpacity(0.8) : Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _showAttachmentSheet,
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: violetFlavor,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendTextMessage(),
              decoration: InputDecoration(
                hintText: 'Écrire un message...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: lightBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(90),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendTextMessage,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: orangeFlavor,
                borderRadius: BorderRadius.circular(90),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}