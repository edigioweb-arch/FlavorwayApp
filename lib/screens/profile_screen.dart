import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'edit_profile_screen.dart';
import 'payment_methods_screen.dart';
import 'home_screen.dart';
import 'addresses_screen.dart';
import 'chat_screen.dart';
import '../services/locale_service.dart';
import '../services/user_auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = 'Cynthia Kaussa';
  String userEmail = 'cynthia@email.com';
  String userPhone = '+242 06 00 00 00';
  String? profileImagePath;

  Future<void> _openEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );

    if (result is Map) {
      setState(() {
        userName = result['name'] ?? userName;
        userEmail = result['email'] ?? userEmail;
        userPhone = result['phone'] ?? userPhone;
        profileImagePath = result['imagePath'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
        ),
      );
    }
  }

  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color lightBackground = Color(0xFFF8F8F8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: violetFlavor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: lightBackground,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                  child: Column(
                    children: [
                      _buildUserCard(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Mon compte'),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        children: [
                          _buildMenuTile(
                            icon: Icons.person_outline,
                            title: 'Informations personnelles',
                            subtitle: 'Nom, e-mail, téléphone',
                            onTap: _openEditProfile,
                          ),
                          _divider(),
                          _buildMenuTile(
                            icon: Icons.location_on_outlined,
                            title: 'Mes adresses',
                            subtitle: 'Maison, bureau, autres',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddressesScreen(),
                              ),
                            ),
                          ),
                          _divider(),
                          _buildMenuTile(
                            icon: Icons.credit_card_outlined,
                            title: 'Moyens de paiement',
                            subtitle: 'Carte, mobile money',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const PaymentMethodsScreen())),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Mes activités'),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        children: [
                          _buildMenuTile(
                            icon: Icons.receipt_long_outlined,
                            title: 'Historique des commandes',
                            subtitle: 'Voir vos anciennes commandes',
                            onTap: () =>
                                Navigator.pushNamed(context, '/orders'),
                          ),
                          _divider(),
                          _buildMenuTile(
                            icon: Icons.event_seat_outlined,
                            title: 'Mes réservations',
                            subtitle: 'Tables réservées et statuts',
                            onTap: () =>
                                Navigator.pushNamed(context, '/reservations'),
                          ),
                          _divider(),
                          _buildMenuTile(
                            icon: Icons.favorite_border,
                            title: 'Mes favoris',
                            subtitle: 'Restaurants et plats enregistrés',
                            onTap: () =>
                                Navigator.pushNamed(context, '/favorites'),
                          ),
                          _divider(),
                          _buildMenuTile(
                            icon: Icons.local_offer_outlined,
                            title: 'Promotions',
                            subtitle: 'Mes offres et réductions',
                            onTap: () => _showPromotionsSheet(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Aide & paramètres'),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        children: [
                          _buildMenuTile(
                            icon: Icons.support_agent_outlined,
                            title: 'Support client',
                            subtitle: 'Besoin d\'aide ?',
                            onTap: () => _showSupportSheet(context),
                          ),
                          _divider(),
                          _buildMenuTile(
                            icon: Icons.settings_outlined,
                            title: 'Paramètres',
                            subtitle: 'Notifications, sécurité, langue',
                            onTap: () => _showSettingsSheet(context),
                          ),
                          _divider(),
                          _buildMenuTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Confidentialité',
                            subtitle: 'Conditions et politique',
                            onTap: () => _showPrivacySheet(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: orangeFlavor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(90),
                              side: const BorderSide(color: orangeFlavor),
                            ),
                          ),
                          onPressed: () => _showLogoutDialog(context),
                          icon: const Icon(Icons.logout),
                          label: Text(
                            'Se déconnecter',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(),
                ),
                (route) => false,
              );
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Mon profil',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _openEditProfile,
            icon: const Icon(
              Icons.edit_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        final TextEditingController addressController = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 18),
              _sheetTitle('Mes adresses'),
              const SizedBox(height: 14),
              _addressCard('Maison', 'Brazzaville, Centre-ville'),
              _addressCard('Bureau', 'Plateau, Brazzaville'),
              const SizedBox(height: 14),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  hintText: 'Ajouter une nouvelle adresse',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  filled: true,
                  fillColor: lightBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.maybePop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Adresse enregistrée')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeFlavor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(90),
                    ),
                  ),
                  child: Text(
                    'Enregistrer l’adresse',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _addressCard(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: orangeFlavor),
          const SizedBox(width: 12),
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
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, color: Colors.grey),
        ],
      ),
    );
  }

  void _showPromotionsSheet(BuildContext context) {
    _showSimpleSheet(
      context,
      title: 'Promotions',
      icon: Icons.local_offer_outlined,
      message:
          'Vous n’avez pas encore de promotion active. Les offres disponibles apparaîtront ici.',
    );
  }

  void _showSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 18),
              _sheetTitle('Support client'),
              const SizedBox(height: 12),
              _supportTile(
                Icons.chat_bubble_outline,
                'Écrire au support',
                'Ouvrir une conversation',
                () {
                  Navigator.maybePop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatScreen(
                        conversationId: 'support_flavorway',
                      ),
                    ),
                  );
                },
              ),
              _supportTile(
                Icons.call_outlined,
                'Appeler FlavorWay',
                '+242 00 000 00 00',
                () {
                  Navigator.maybePop(context);
                  _showCallSupportDialog(context);
                },
              ),
              _supportTile(
                Icons.help_outline,
                'Centre d’aide',
                'Questions fréquentes',
                () {
                  Navigator.maybePop(context);
                  _showHelpCenterSheet(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _supportTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: orangeFlavor),
      title:
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 15),
      onTap: onTap,
    );
  }

  void _showCallSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Appeler FlavorWay',
            style: TextStyle(
              color: Color(0xFF4B1F5C),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Numéro du support : +242 00 000 00 00',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text(
                'Fermer',
                style: TextStyle(
                  color: Color(0xFF4B1F5C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.maybePop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appel téléphonique à connecter ensuite'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: orangeFlavor,
              ),
              child: const Text(
                'Appeler',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showHelpCenterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 18),
              _sheetTitle('Centre d’aide'),
              const SizedBox(height: 12),
              _helpQuestion('Comment suivre ma commande ?',
                  'Ouvrez Mes commandes puis cliquez sur Suivre.'),
              _helpQuestion('Comment annuler une réservation ?',
                  'Allez dans Mes réservations puis cliquez sur Annuler.'),
              _helpQuestion('Comment contacter un restaurant ?',
                  'Utilisez le bouton Message depuis la fiche restaurant ou le suivi de commande.'),
            ],
          ),
        );
      },
    );
  }

  Widget _helpQuestion(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.poppins(
              color: violetFlavor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        bool notifications = true;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 18),
                  _sheetTitle('Paramètres'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: notifications,
                    activeColor: orangeFlavor,
                    title: const Text(
                      'Notifications',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('Commandes, promotions et messages'),
                    onChanged: (value) {
                      setModalState(() {
                        notifications = value;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Notifications activées'
                                : 'Notifications désactivées',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language_outlined,
                        color: orangeFlavor),
                    title: const Text('Langue'),
                    subtitle: const Text('Français'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 15),
                    onTap: () => _showLanguageSheet(context),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.lock_outline, color: orangeFlavor),
                    title: const Text('Sécurité'),
                    subtitle: const Text('Mot de passe et connexion'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 15),
                    onTap: () => _showSecuritySheet(context),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLanguageSheet(BuildContext context) {
    Navigator.maybePop(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 18),
              _sheetTitle('Langue'),
              const SizedBox(height: 12),
              RadioListTile<String>(
                value: 'fr',
                groupValue: LocaleService.instance.locale.languageCode,
                activeColor: orangeFlavor,
                title: const Text('Français'),
                subtitle: Text(
                  LocaleService.instance.isFrench
                      ? 'Langue actuelle'
                      : 'Changer en français',
                ),
                onChanged: (_) {
                  LocaleService.instance.setFrench();
                  Navigator.maybePop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Langue française activée'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              RadioListTile<String>(
                value: 'en',
                groupValue: LocaleService.instance.locale.languageCode,
                activeColor: orangeFlavor,
                title: const Text('English'),
                subtitle: Text(
                  LocaleService.instance.isEnglish
                      ? 'Current language'
                      : 'Switch to English',
                ),
                onChanged: (_) {
                  LocaleService.instance.setEnglish();
                  Navigator.maybePop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('English enabled'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSecuritySheet(BuildContext context) {
    Navigator.maybePop(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        final currentPasswordController = TextEditingController();
        final newPasswordController = TextEditingController();
        final confirmPasswordController = TextEditingController();

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 18),
              _sheetTitle('Sécurité'),
              const SizedBox(height: 12),
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: const Icon(Icons.verified_user_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (currentPasswordController.text.trim().isEmpty ||
                        newPasswordController.text.trim().isEmpty ||
                        confirmPasswordController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Complétez tous les champs'),
                        ),
                      );
                      return;
                    }

                    if (newPasswordController.text.trim() !=
                        confirmPasswordController.text.trim()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Les mots de passe ne correspondent pas'),
                        ),
                      );
                      return;
                    }

                    final updated = UserAuthService.instance.updatePassword(
                      currentPassword: currentPasswordController.text.trim(),
                      newPassword: newPasswordController.text.trim(),
                    );

                    if (!updated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mot de passe actuel incorrect'),
                        ),
                      );
                      return;
                    }

                    Navigator.maybePop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mot de passe modifié avec succès'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeFlavor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(90),
                    ),
                  ),
                  child: Text(
                    'Enregistrer',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacySheet(BuildContext context) {
    _showSimpleSheet(
      context,
      title: 'Confidentialité',
      icon: Icons.privacy_tip_outlined,
      message:
          'Retrouvez ici les conditions d’utilisation, la politique de confidentialité et la gestion de vos données personnelles.',
    );
  }

  void _showSimpleSheet(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String message,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 18),
              Icon(icon, color: orangeFlavor, size: 42),
              const SizedBox(height: 12),
              _sheetTitle(title),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade700,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.maybePop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeFlavor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(90),
                    ),
                  ),
                  child: Text(
                    'Compris',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Se déconnecter',
            style: TextStyle(
              color: Color(0xFF4B1F5C),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Voulez-vous vraiment vous déconnecter ?',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Color(0xFF4B1F5C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: orangeFlavor),
              child: const Text(
                'Déconnexion',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _sheetTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: violetFlavor,
        fontSize: 21,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [orangeFlavor, violetFlavor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: orangeFlavor.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: ClipOval(
              child: profileImagePath != null
                  ? Image.file(
                      File(profileImagePath!),
                      fit: BoxFit.cover,
                      width: 72,
                      height: 72,
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 38,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userPhone,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: violetFlavor,
        ),
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: orangeFlavor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: orangeFlavor),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Divider(
        height: 1,
        color: Colors.grey.shade200,
      ),
    );
  }
}
