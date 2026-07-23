import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/notification_service.dart';
import 'messages_screen.dart';
import 'order_tracking_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const Color violetFlavor = Color(0xFF4B1F5C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: violetFlavor,
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: NotificationService.instance.markAllAsRead,
            icon: const Icon(Icons.done_all_rounded),
            color: violetFlavor,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: NotificationService.instance,
        builder: (context, _) {
          final notifications = NotificationService.instance.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Text(
                'Aucune notification',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return _NotificationCard(
                icon: Icons.notifications_rounded,
                title: notification.title,
                message: notification.message,
                time: _formatTime(notification.createdAt),
                isRead: notification.isRead,
                onTap: () {
                  NotificationService.instance.markAsRead(notification.id);

                  if (notification.title.contains('Commande')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrderTrackingScreen(),
                      ),
                    );
                    return;
                  }

                  if (notification.title.contains('Réservation')) {
                    Navigator.pushNamed(context, '/reservations');
                    return;
                  }

                  if (notification.title.contains('Article')) {
                    Navigator.pushNamed(context, '/cart');
                    return;
                  }

                  if (notification.title.contains('Message') ||
                      notification.title.contains('Image') ||
                      notification.title.contains('Position')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MessagesScreen(),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
            Text(time),
          ],
        ),
      ),
    );
  }
}
