import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Commande #CMD1245 livrée',
        'subtitle': 'Votre commande a été livrée avec succès',
        'time': 'il y a 2 min',
        'type': 'success',
      },
      {
        'title': 'Nouveau coupon disponible',
        'subtitle': '-20% sur votre prochaine commande chez Mami Wata',
        'time': 'il y a 1h',
        'type': 'promo',
      },
      {
        'title': 'Commande #CMD1244 en cours',
        'subtitle': 'Votre coursier est en route, ETA 12 min',
        'time': 'il y a 2h',
        'type': 'info',
      },
      {
        'title': 'Nouveauté: Poulet DG grillé',
        'subtitle': 'Découvrez notre nouveau plat signature',
        'time': 'hier',
        'type': 'new',
      },
      {
        'title': 'Support: Réponse à votre message',
        'subtitle': 'Nous avons répondu à votre demande',
        'time': '2 jours',
        'type': 'support',
      },
    ];

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
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.mark_email_unread_outlined),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: _buildNotificationIcon(notif['type']),
              title: Text(
                notif['title'],
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif['subtitle'],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif['time'],
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey),
              onTap: () {
                // Navigate to detail
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'success':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'promo':
        icon = Icons.local_offer;
        color = const Color(0xFFF36A2D);
        break;
      case 'new':
        icon = Icons.new_releases;
        color = Colors.blue;
        break;
      case 'info':
        icon = Icons.info;
        color = Colors.blue;
        break;
      default:
        icon = Icons.support_agent;
        color = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
