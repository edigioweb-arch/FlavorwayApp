import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/restaurant_owner/restaurant_dashboard_screen.dart';
import '../services/user_auth_service.dart';

/// Widget racine qui détermine l'écran à afficher en fonction de l'état de
/// de connexion Firebase et de la vérification de l'e-mail.
///
/// Utilise un StreamBuilder sur `FirebaseAuth.instance.userChanges()` pour
/// réagir en temps réel aux changements d'état d'authentification.
///
/// Trois états possibles :
///   - user == null                  → loginWidget (WelcomePage)
///   - user != null && !emailVerified → verificationWidget (EmailVerificationScreen)
///   - user != null && emailVerified  → homeWidget (HomeScreen)
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    this.loadingWidget,
    this.loginWidget,
    this.verificationWidget,
    this.homeWidget,
  });

  final Widget? loadingWidget;
  final Widget? loginWidget;
  final Widget? verificationWidget;
  final Widget? homeWidget;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;

        if (kDebugMode) {
          // ignore: avoid_print
          print('=== AuthGate DEBUT ===');
          // ignore: avoid_print
          print('user == null: ${user == null}');
          if (user == null) {
            // ignore: avoid_print
            print('→ WIDGET: WelcomePage (loginWidget)');
          } else {
            // ignore: avoid_print
            print('uid: ${user.uid}');
            // ignore: avoid_print
            print('emailVerified: ${user.emailVerified}');
            if (!user.emailVerified) {
              // ignore: avoid_print
              print('→ WIDGET: EmailVerificationScreen (verificationWidget)');
            } else {
              // ignore: avoid_print
              print('→ WIDGET: HomeScreen (homeWidget)');
            }
          }
          // ignore: avoid_print
          print('=== AuthGate FIN ===');
        }

        if (user == null) {
          return loginWidget ?? const SizedBox();
        }

        if (!user.emailVerified) {
          return verificationWidget ?? const SizedBox();
        }

        return FutureBuilder(
          future: UserAuthService.instance.getUserProfile(uid: user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return loadingWidget ??
                  const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
            }

            if (profileSnapshot.hasError || !profileSnapshot.hasData) {
              return homeWidget ?? const SizedBox();
            }

            final profileData = profileSnapshot.data?.data() ?? {};
            final normalizedRole =
                (profileData['role'] as String?)?.trim().toLowerCase();

            if (kDebugMode) {
              // ignore: avoid_print
              print('AuthGate role Firestore: ${normalizedRole ?? 'null'}');
            }

            if (normalizedRole == 'restaurant' ||
                normalizedRole == 'restaurant_owner') {
              return const RestaurantDashboardScreen();
            }

            return homeWidget ?? const SizedBox();
          },
        );
      },
    );
  }
}
