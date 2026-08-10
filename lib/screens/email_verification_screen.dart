import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_auth_service.dart';

/// Écran affiché lorsque l'utilisateur est connecté mais n'a pas encore
/// vérifié son adresse e-mail.
///
/// Propose trois actions :
///   1. « J'ai vérifié mon e-mail » → reload() + vérifie emailVerified
///   2. « Renvoyer l'e-mail » → envoie un nouveau lien (cooldown 60s)
///   3. « Se déconnecter » → signOut()
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isSending = false;
  bool _cooldownActive = false;
  int _cooldownSeconds = 60;
  Timer? _cooldownTimer;
  String? _errorMessage;

  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);
  static const Color violetDark = Color(0xFF2A0D35);

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _cooldownActive = true;
      _cooldownSeconds = 60;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
      });
      if (_cooldownSeconds <= 0) {
        timer.cancel();
        if (mounted)
          setState(() {
            _cooldownActive = false;
          });
      }
    });
  }

  /// Action du bouton « J'ai vérifié mon e-mail ».
  ///
  /// Logique stricte (3 cas seulement) :
  /// 1. freshUser == null            → « Votre session a expiré. »
  /// 2. freshUser.emailVerified == false → « Votre adresse e-mail n'a pas encore été vérifiée. »
  /// 3. freshUser.emailVerified == true  → SUCCÈS → refreshAuthState() → AuthGate bascule vers HomeScreen
  ///
  /// N'appelle JAMAIS sendEmailVerification().
  /// Ne lance AUCUNE exception sur emailVerified == true.
  Future<void> _checkVerification() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      // 1. Récupérer l'utilisateur Firebase actuel
      final User? user = FirebaseAuth.instance.currentUser;

      // 2. Session expirée ou utilisateur non connecté
      if (user == null) {
        setState(() {
          _errorMessage =
              'Votre session a expir\u00e9. Veuillez vous reconnecter.';
          _isChecking = false;
        });
        return;
      }

      // 3. Si déjà vérifié côté client (sans reload)
      if (user.emailVerified) {
        // Déjà vérifié, AuthGate devrait déjà avoir basculé.
        // On force un rafraîchissement du token pour être sûr que le stream réagisse.
        await user.getIdToken(true);
        // Pas de return ici, le finally s'occupera de _isChecking
      }

      // 4. Recharger depuis le serveur (user.reload() met à jour l'objet sur place)
      await user.reload();

      // 5. Après reload, l'état de user.emailVerified est à jour.
      // Cependant, user.reload() seul ne déclenche pas le stream userChanges().
      // Pour forcer le StreamBuilder de AuthGate à se reconstruire avec le nouvel état,
      // nous devons forcer un rafraîchissement du token.
      if (user.emailVerified) {
        await user.getIdToken(true);
      }

      // 6. Toujours pas vérifié
      if (mounted) {
        setState(() {
          _errorMessage =
              'Votre adresse e-mail n\'a pas encore \u00e9t\u00e9 v\u00e9rifi\u00e9e.';
          _isChecking = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _frenchErrorMessage(e.code);
        _isChecking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Impossible de v\u00e9rifier votre adresse e-mail. R\u00e9essayez.';
        _isChecking = false;
      });
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  String _frenchErrorMessage(String code) {
    switch (code) {
      case 'too-many-requests':
        return 'Trop de tentatives. R\u00e9essayez dans quelques minutes.';
      case 'network-request-failed':
        return 'V\u00e9rifiez votre connexion Internet puis r\u00e9essayez.';
      case 'user-not-found':
        return 'Aucun compte trouv\u00e9. Veuillez vous reconnecter.';
      default:
        return 'Impossible de v\u00e9rifier votre adresse e-mail. R\u00e9essayez.';
    }
  }

  Future<void> _resendEmail() async {
    if (_isSending || _cooldownActive) return;
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });
    try {
      await UserAuthService.instance.sendEmailVerification();
      if (!mounted) return;
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Un nouvel e-mail de v\u00e9rification a \u00e9t\u00e9 envoy\u00e9.'),
          backgroundColor: Colors.green,
        ),
      );
    } on UserAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible d\'envoyer l\'e-mail. R\u00e9essayez.';
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _signOut() async {
    await UserAuthService.instance.signOut();
  }

  String _formatCooldown() {
    final minutes = _cooldownSeconds ~/ 60;
    final seconds = _cooldownSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final User? user = UserAuthService.instance.currentUser;
    final String email = user?.email ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF3EEF7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: orangeFlavor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.email_outlined,
                      color: orangeFlavor, size: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  'V\u00e9rifiez votre adresse e-mail',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: violetDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Un lien de v\u00e9rification a \u00e9t\u00e9 envoy\u00e9 \u00e0 :',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    email,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: violetFlavor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cliquez sur le lien dans l\'e-mail pour activer votre compte, puis revenez ici.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              color: Colors.red.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isChecking ? null : _checkVerification,
                    icon: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline,
                            color: Colors.white),
                    label: Text(
                      _isChecking
                          ? 'V\u00e9rification\u2026'
                          : 'J\'ai v\u00e9rifi\u00e9 mon e-mail',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: violetFlavor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(90)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed:
                        (_isSending || _cooldownActive) ? null : _resendEmail,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(
                      _cooldownActive
                          ? 'Renvoyer (${_formatCooldown()})'
                          : (_isSending ? 'Envoi\u2026' : 'Renvoyer l\'e-mail'),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _cooldownActive ? Colors.grey : orangeFlavor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: orangeFlavor,
                      side: BorderSide(
                        color: _cooldownActive
                            ? Colors.grey.shade300
                            : orangeFlavor,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(90)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                TextButton(
                  onPressed: _signOut,
                  child: Text(
                    'Se d\u00e9connecter',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
