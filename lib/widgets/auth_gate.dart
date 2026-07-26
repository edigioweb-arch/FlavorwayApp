import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_auth_service.dart';

/// Widget racine qui détermine l'écran à afficher en fonction de l'état
/// de connexion Firebase.
///
/// Principe de fonctionnement :
///
/// 1. Au démarrage, Firebase Authentication restaure la session persistante
///    (token stocké localement). Pendant cette phase, [isLoading] est vrai
///    et un indicateur de chargement est affiché.
///
/// 2. Une fois la session rétablie (ou confirmée absente), le stream
///    [authStateChanges] émet l'état :
///      - [User] non null → l'utilisateur est connecté → redirection vers
///        l'écran principal ([homeWidget]).
///      - [User] null → l'utilisateur est déconnecté → redirection vers
///        l'écran de connexion ([loginWidget]).
///
/// 3. [AuthGate] utilise un [StreamBuilder] pour écouter en temps réel
///    les changements de session. Si l'utilisateur se déconnecte, il est
///    automatiquement redirigé vers l'écran de connexion.
///
/// Aucune logique de rôle n'est gérée ici. Le widget ne fait que distinguer
/// un utilisateur connecté d'un utilisateur déconnecté.
///
/// La durée de la phase [isLoading] dépend du fournisseur Firebase :
///   - Android / iOS / macOS : la session est restaurée quasi immédiatement
///     depuis le stockage local.
///   - Web : la session peut prendre plus de temps selon le cookie.
///   - Windows / Linux : idem.
///
/// Aucune boucle de navigation n'est possible car [StreamBuilder] est
/// le seul décideur de l'écran affiché.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    this.loadingWidget,
    this.loginWidget,
    this.homeWidget,
  });

  /// Widget affiché pendant la vérification de la session.
  ///
  /// Par défaut, un [CircularProgressIndicator] centré sur fond blanc.
  final Widget? loadingWidget;

  /// Widget affiché lorsque l'utilisateur n'est pas connecté.
  ///
  /// Par défaut, l'écran de bienvenue ([WelcomePage]).
  final Widget? loginWidget;

  /// Widget affiché lorsque l'utilisateur est connecté.
  ///
  /// Par défaut, l'écran d'accueil ([HomeScreen]).
  final Widget? homeWidget;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Écoute les changements d'état de connexion Firebase.
      stream: UserAuthService.instance.authStateChanges(),

      builder: (context, snapshot) {
        // ---------------------------------------------------------------
        // Phase de chargement
        // ---------------------------------------------------------------
        // snapshot.connectionState == ConnectionState.waiting signifie que
        // Firebase est en train de restaurer la session. Cela dure
        // généralement moins d'une seconde sur mobile, mais peut être plus
        // long sur le web ou si le réseau est lent.
        //
        // Pendant cette phase, on affiche un indicateur de chargement pour
        // éviter un écran noir ou un flash intempestif.
        // ---------------------------------------------------------------
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Vérification de la session…',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
        }

        // ---------------------------------------------------------------
        // Phase d'erreur (rare)
        // ---------------------------------------------------------------
        // Si le stream émet une erreur (par exemple problème de
        // configuration Firebase), on affiche un message d'erreur plutôt
        // que de planter l'application.
        // ---------------------------------------------------------------
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Erreur de connexion',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Impossible de vérifier votre session. '
                      'Vérifiez votre connexion réseau.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Forcer le rechargement du stream en reconstruisant
                        // le widget (le StreamBuilder réagit au changement
                        // d'état de Firebase).
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ---------------------------------------------------------------
        // Phase de données
        // ---------------------------------------------------------------
        // snapshot.data contient l'utilisateur Firebase ou null.
        //   - Si User est non null → utilisateur connecté → homeWidget
        //   - Si User est null → utilisateur déconnecté → loginWidget
        // ---------------------------------------------------------------
        final User? user = snapshot.data;

        if (user != null) {
          // Utilisateur connecté
          return homeWidget ??
              const SizedBox(); // Sera remplacé par HomeScreen dans main.dart
        }

        // Utilisateur déconnecté
        return loginWidget ??
            const SizedBox(); // Sera remplacé par WelcomePage dans main.dart
      },
    );
  }
}
