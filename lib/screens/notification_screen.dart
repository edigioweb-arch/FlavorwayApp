import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/app_notification_model.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService.instance;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _notificationService.fetchNotifications();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toutes les notifications ont été marquées comme lues.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_toMessage(error))),
      );
    }
  }

  Future<void> _openNotification(AppNotificationModel notification) async {
    try {
      if (!notification.isRead) {
        await _notificationService.markAsRead(notification.id);
      }
    } catch (_) {
      // L'ouverture visuelle reste possible même si la mise à jour de lecture échoue.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _notificationService,
      builder: (context, _) {
        final notifications = _notificationService.notifications;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Notifications',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2A1B4D),
              ),
            ),
            actions: [
              IconButton(
                onPressed: notifications.isEmpty ? null : _markAllAsRead,
                icon: const Icon(Icons.mark_email_read_outlined),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadNotifications,
            child: _buildBody(notifications),
          ),
        );
      },
    );
  }

  Widget _buildBody(List<AppNotificationModel> notifications) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.error_outline, size: 48, color: Colors.orange.shade400),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF6F7390),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Réessayer'),
            ),
          ),
        ],
      );
    }

    if (notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.notifications_none, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Aucune notification pour le moment.',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2A1B4D),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : const Color(0xFFF8F2FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEAE3F4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: _buildNotificationIcon(notification.type),
            title: Text(
              notification.title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: const Color(0xFF2A1B4D),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  notification.body,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6F7390),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(notification.createdAt),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF9AA0B5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            trailing: Icon(
              notification.isRead ? Icons.chevron_right : Icons.circle,
              size: notification.isRead ? 18 : 10,
              color: notification.isRead
                  ? Colors.grey.shade400
                  : const Color(0xFFF36A2D),
            ),
            onTap: () => _openNotification(notification),
          ),
        );
      },
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'reservation_confirmed':
      case 'order_confirmed':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'reservation_rejected':
      case 'order_cancelled':
        icon = Icons.cancel_outlined;
        color = Colors.redAccent;
        break;
      case 'promotion':
      case 'promo':
        icon = Icons.local_offer_outlined;
        color = const Color(0xFFF36A2D);
        break;
      case 'message':
        icon = Icons.message_outlined;
        color = const Color(0xFF00A6A6);
        break;
      default:
        icon = Icons.notifications_active_outlined;
        color = const Color(0xFF6D37A1);
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  String _toMessage(Object error) {
    final message = error.toString().trim();
    if (message.isEmpty) {
      return 'Une erreur est survenue.';
    }
    return message;
  }
}
