import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'laravel_sync_service.dart';
import 'notification_service.dart';

/// Service d'authentification utilisant Firebase Authentication et Firestore.
class UserAuthService extends ChangeNotifier {
  static final UserAuthService instance = UserAuthService._();

  UserAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  Stream<User?> userChanges() => _auth.userChanges();

  void _debugLog(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(message);
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _convertAuthException(e);
    } catch (e) {
      throw UserAuthException(
        message: 'Impossible de se connecter. Vérifiez votre connexion réseau.',
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> profileData,
  }) async {
    User? createdUser;
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      createdUser = credential.user;
      if (createdUser == null) {
        throw UserAuthException(
          message: 'La création du compte a échoué. Veuillez réessayer.',
        );
      }
      await _usersCollection.doc(createdUser.uid).set({
        'uid': createdUser.uid,
        'email': normalizedEmail,
        ...profileData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final normalizedRole =
          (profileData['role'] as String?)?.trim().toLowerCase();
      if (normalizedRole == 'client' || normalizedRole == 'customer') {
        await LaravelSyncService.instance.syncCurrentClient();
      }
      if (normalizedRole == 'restaurant' ||
          normalizedRole == 'restaurant_owner') {
        await LaravelSyncService.instance.syncCurrentRestaurantOwner();
      }
      if (profileData['firstName'] != null || profileData['lastName'] != null) {
        final displayName = [
          profileData['firstName'] ?? '',
          profileData['lastName'] ?? '',
        ].where((n) => n.isNotEmpty).join(' ').trim();
        if (displayName.isNotEmpty) {
          await createdUser.updateDisplayName(displayName);
        }
      }
      try {
        await createdUser.sendEmailVerification();
      } catch (error) {
        _debugLog(
          'Envoi email de vérification ignoré après inscription: $error',
        );
      } // L'échec de l'envoi d'e-mail ne doit pas bloquer l'inscription
    } on FirebaseAuthException catch (e) {
      if (createdUser != null) {
        try {
          await createdUser.delete(); // Rollback de la création Firebase Auth
        } catch (error) {
          _debugLog('Rollback Firebase Auth après erreur signup: $error');
        }
      }
      throw _convertAuthException(e);
    } on FirebaseException catch (e) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (error) {
          _debugLog('Rollback profil Firebase après erreur Firestore: $error');
        }
      }
      throw UserAuthException(
        message: e.message ?? 'Impossible de créer le profil utilisateur.',
      );
    } on LaravelSyncException catch (e) {
      if (createdUser != null) {
        try {
          await _auth.signOut();
        } catch (error) {
          _debugLog('SignOut après échec sync Laravel signup: $error');
        }
      }
      throw UserAuthException(
        message:
            'Compte Firebase créé, mais la synchronisation FlavorWay a échoué: ${e.message}',
      );
    } catch (e) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (error) {
          _debugLog('Rollback Firebase inattendu après signup: $error');
        }
      }
      throw UserAuthException(
        message: 'Une erreur inattendue est survenue lors de l\'inscription.',
      );
    }
  }

  Future<void> signOut() async {
    await NotificationService.instance.deactivateCurrentDeviceToken();
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _convertAuthException(e);
    } catch (e) {
      throw UserAuthException(
        message: 'Impossible d\'envoyer l\'e-mail de réinitialisation.',
      );
    }
  }

  Future<void> updatePassword({required String newPassword}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw UserAuthException(
        message: 'Vous devez être connecté pour modifier votre mot de passe.',
      );
    }
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _convertAuthException(e);
    } catch (e) {
      throw UserAuthException(
        message: 'Impossible de modifier le mot de passe. Réessayez plus tard.',
      );
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw UserAuthException(
        message: 'Vous devez être connecté pour vérifier votre adresse e-mail.',
      );
    }
    if (user.emailVerified) {
      throw UserAuthException(
        message: 'Votre adresse e-mail est déjà vérifiée.',
      );
    }
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _convertAuthException(e);
    } catch (e) {
      throw UserAuthException(
        message: 'Impossible d\'envoyer l\'e-mail de vérification.',
      );
    }
  }

  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw UserAuthException(
        message: 'Vous devez être connecté pour recharger vos informations.',
      );
    }
    try {
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw _convertAuthException(e);
    } catch (e) {
      throw UserAuthException(
        message: 'Impossible de recharger les informations.',
      );
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw UserAuthException(
        message: 'Vous devez être connecté pour supprimer votre compte.',
      );
    }
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _convertAuthException(e);
    } catch (e) {
      throw UserAuthException(
        message: 'Impossible de supprimer le compte. Réessayez plus tard.',
      );
    }
  }

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<void> createUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _usersCollection.doc(uid).set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw UserAuthException(
        message: 'Impossible de créer le profil utilisateur.',
      );
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile({
    required String uid,
  }) async {
    try {
      return await _usersCollection.doc(uid).get();
    } catch (e) {
      throw UserAuthException(
        message: 'Impossible de récupérer le profil utilisateur.',
      );
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw UserAuthException(
        message: 'Impossible de mettre à jour le profil utilisateur.',
      );
    }
  }

  Future<void> signInWithProfileCheck({
    required String email,
    required String password,
  }) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('=== signInWithProfileCheck DEBUT ===');
      // ignore: avoid_print
      print('Email reçu: "$email"');
      // ignore: avoid_print
      print('Password renseigné: ${password.isNotEmpty}');
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (kDebugMode) {
        // ignore: avoid_print
        print('--- Firebase Auth OK ---');
        // ignore: avoid_print
        print('UID: ${user?.uid}');
        // ignore: avoid_print
        print('emailVerified: ${user?.emailVerified}');
        // ignore: avoid_print
        print('user is null: ${user == null}');
      }

      if (user == null) {
        throw UserAuthException(
          message: 'Impossible de récupérer les informations de connexion.',
        );
      }

      if (kDebugMode) {
        // ignore: avoid_print
        print('--- Firestore read users/${user.uid} ---');
      }

      final docSnapshot = await _usersCollection.doc(user.uid).get();

      if (kDebugMode) {
        // ignore: avoid_print
        print('Firestore doc exists: ${docSnapshot.exists}');
        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          // ignore: avoid_print
          print('Firestore data:');
          // ignore: avoid_print
          print('  status: "${data?['status']}"');
          // ignore: avoid_print
          print('  email: "${data?['email']}"');
          // ignore: avoid_print
          print('  uid: "${data?['uid']}"');
        } else {
          // ignore: avoid_print
          print('DOCUMENT FIRESTORE N\'EXISTE PAS !');
        }
      }

      if (!docSnapshot.exists) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('--- signOut car document Firestore introuvable ---');
        }
        await _auth.signOut();
        throw UserAuthException(
          message: 'Votre profil est introuvable. Contactez l\'assistance.',
        );
      }

      final data = docSnapshot.data() ?? {};
      final String? status = data['status'] as String?;
      final String? role = data['role'] as String?;
      final normalizedRole = role?.trim().toLowerCase();

      if (kDebugMode) {
        // ignore: avoid_print
        print('Valeur du champ status: "$status"');
        // ignore: avoid_print
        print('Valeur du champ role: "$role"');
        // ignore: avoid_print
        print(
            'Condition status != null && status != "active": ${status != null && status != 'active'}');
      }

      if (status != null && status != 'active') {
        final isRestaurantRole = normalizedRole == 'restaurant' ||
            normalizedRole == 'restaurant_owner';

        if (kDebugMode) {
          // ignore: avoid_print
          print('=== RESTAURANT SYNC DEBUG ===');
          // ignore: avoid_print
          print('role Firestore: ${normalizedRole ?? 'null'}');
          // ignore: avoid_print
          print('status Firestore: ${status.trim().toLowerCase()}');
          // ignore: avoid_print
          print('Firebase currentUser null: ${_auth.currentUser == null}');
        }

        if (status == 'pending' && isRestaurantRole) {
          try {
            final syncResult =
                await LaravelSyncService.instance.syncCurrentRestaurantOwner();

            if (kDebugMode) {
              final restaurant =
                  syncResult['restaurant'] as Map<String, dynamic>?;
              // ignore: avoid_print
              print(
                'restaurant Laravel id: ${restaurant?['id'] ?? 'null'}',
              );
              // ignore: avoid_print
              print(
                'restaurant Laravel status: ${restaurant?['status'] ?? 'null'}',
              );
            }
          } on LaravelSyncException catch (e) {
            if (kDebugMode) {
              // ignore: avoid_print
              print('sync success: false');
              // ignore: avoid_print
              print('Cause sync Laravel: ${e.message}');
            }

            await _auth.signOut();
            throw UserAuthException(message: e.message);
          }

          if (kDebugMode) {
            // ignore: avoid_print
            print(
              '--- Restaurateur pending autorise a poursuivre vers son espace ---',
            );
          }

          return;
        }

        if (kDebugMode) {
          // ignore: avoid_print
          print('--- signOut car status != active ---');
        }
        await _auth.signOut();
        String statusMessage;
        switch (status) {
          case 'suspended':
            statusMessage = 'Votre compte a été suspendu.';
            break;
          case 'inactive':
            statusMessage = 'Votre compte est inactif.';
            break;
          case 'blocked':
          case 'disabled':
            statusMessage = 'Votre compte a été désactivé.';
            break;
          case 'pending':
            statusMessage = 'Votre compte est en attente de validation.';
            break;
          default:
            statusMessage = 'Votre compte n\'est pas actif.';
        }
        throw UserAuthException(
            message: '$statusMessage Contactez l\'assistance.');
      }

      if (normalizedRole == 'client' || normalizedRole == 'customer') {
        try {
          await LaravelSyncService.instance.syncCurrentClient();
        } on LaravelSyncException catch (e) {
          await _auth.signOut();
          throw UserAuthException(
            message:
                'Connexion Firebase réussie, mais la synchronisation FlavorWay a échoué: ${e.message}',
          );
        }
      }

      if (kDebugMode) {
        // ignore: avoid_print
        print('--- signInWithProfileCheck FIN NORME ---');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print(
            'EXCEPTION FirebaseAuthException code="${e.code}" message="${e.message}"');
      }
      throw _convertAuthException(e);
    } on UserAuthException {
      if (kDebugMode) {
        // ignore: avoid_print
        print('EXCEPTION UserAuthException (rethrow)');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('EXCEPTION generique type=${e.runtimeType} value=$e');
      }
      throw UserAuthException(
        message: 'Impossible de se connecter. Vérifiez votre connexion réseau.',
      );
    }
  }

  Future<bool> hasValidProfile() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final doc = await _usersCollection.doc(user.uid).get();
      if (!doc.exists) return false;
      final data = doc.data();
      if (data == null) return false;
      final String? status = data['status'] as String?;
      return status == null || status == 'active';
    } catch (error) {
      _debugLog('Lecture statut pending restaurant impossible: $error');
      return false;
    }
  }

  UserAuthException _convertAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'invalid-email':
        message = 'L\'adresse e-mail n\'est pas valide.';
        break;
      case 'user-not-found':
        message = 'Aucun compte ne correspond à cette adresse e-mail.';
        break;
      case 'wrong-password':
        message = 'Le mot de passe est incorrect.';
        break;
      case 'invalid-credential':
        message = 'E-mail ou mot de passe incorrect.';
        break;
      case 'user-disabled':
        message = 'Ce compte a été désactivé.';
        break;
      case 'too-many-requests':
        message = 'Trop de tentatives. Réessayez dans quelques minutes.';
        break;
      case 'network-request-failed':
        message = 'Vérifiez votre connexion Internet puis réessayez.';
        break;
      case 'email-already-in-use':
        message = 'Cette adresse e-mail est déjà utilisée.';
        break;
      case 'weak-password':
        message = 'Le mot de passe doit contenir au moins 6 caractères.';
        break;
      case 'operation-not-allowed':
        message = 'La connexion par e-mail et mot de passe n\'est pas activée.';
        break;
      case 'missing-android-pkg-name':
      case 'missing-continue-uri':
      case 'missing-ios-bundle-id':
        message =
            'Configuration de réinitialisation incomplète. Contactez le support.';
        break;
      case 'invalid-continue-uri':
        message = 'Le lien de réinitialisation n\'est pas valide.';
        break;
      case 'requires-recent-login':
        message =
            'Veuillez vous reconnecter avant de modifier votre mot de passe.';
        break;
      case 'credential-too-old-login-again':
        message = 'Veuillez vous reconnecter avant de supprimer votre compte.';
        break;
      default:
        message = e.message ?? 'Une erreur d\'authentification est survenue.';
    }
    return UserAuthException(message: message, code: e.code);
  }
}

class UserAuthException implements Exception {
  UserAuthException({required this.message, this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}
