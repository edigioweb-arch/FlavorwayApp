import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/notification_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color lightBackground = Color(0xFFF8F8F8);

  late bool _notificationsEnabled;
  late String _selectedSound;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = NotificationService.instance.notificationsEnabled;
    _selectedSound = NotificationService.instance.selectedMessageSound;
  }

  void _savePreferences() {
    NotificationService.instance.updatePreferences(
      enabled: _notificationsEnabled,
      sound: _selectedSound,
    );

    NotificationService.instance.previewSelectedSound();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paramètres de notification enregistrés avec succès'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.maybePop(context);
  }

  Widget _buildSoundOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedSound == value;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() {
          _selectedSound = value;
        });
        NotificationService.instance.updatePreferences(
          enabled: _notificationsEnabled,
          sound: _selectedSound,
        );
        NotificationService.instance.previewSelectedSound();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? orangeFlavor : Colors.grey.shade200,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: orangeFlavor.withOpacity(0.12),
              child: Icon(icon, color: orangeFlavor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: violetFlavor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedSound,
              activeColor: orangeFlavor,
              onChanged: (newValue) {
                if (newValue == null) return;
                setState(() {
                  _selectedSound = newValue;
                });
                NotificationService.instance.updatePreferences(
                  enabled: _notificationsEnabled,
                  sound: _selectedSound,
                );
                NotificationService.instance.previewSelectedSound();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        centerTitle: true,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            color: violetFlavor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _notificationsEnabled,
                activeColor: orangeFlavor,
                title: Text(
                  'Recevoir les notifications',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Messages, commandes et activités du compte',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Son de notification des messages',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: violetFlavor,
              ),
            ),
            const SizedBox(height: 12),
            _buildSoundOption(
              value: 'classic',
              title: 'Son classique',
              subtitle: 'Notification simple et directe',
              icon: Icons.notifications_active_outlined,
            ),
            const SizedBox(height: 12),
            _buildSoundOption(
              value: 'soft',
              title: 'Son doux',
              subtitle: 'Notification plus discrète',
              icon: Icons.music_note_outlined,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeFlavor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(90),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text(
                  'Enregistrer',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
