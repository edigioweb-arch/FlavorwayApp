import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/restaurant_owner/restaurant_dashboard_screen.dart';
import '../services/laravel_sync_service.dart';
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
              return const _RestaurantBootstrapGate();
            }

            return homeWidget ?? const SizedBox();
          },
        );
      },
    );
  }
}

class _RestaurantBootstrapGate extends StatefulWidget {
  const _RestaurantBootstrapGate();

  @override
  State<_RestaurantBootstrapGate> createState() =>
      _RestaurantBootstrapGateState();
}

class _RestaurantBootstrapGateState extends State<_RestaurantBootstrapGate> {
  late Future<void> _syncFuture;

  @override
  void initState() {
    super.initState();
    _syncFuture = _runSync();
  }

  Future<void> _runSync() async {
    try {
      await LaravelSyncService.instance.syncCurrentRestaurantOwner();
    } on LaravelSyncException catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('=== AUTHGATE RESTAURANT SYNC WARNING ===');
        // ignore: avoid_print
        print('Cause sync Laravel via AuthGate: ${e.message}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _syncFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const RestaurantDashboardScreen();
      },
    );
  }
}
