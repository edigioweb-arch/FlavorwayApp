import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service d'authentification utilisant Firebase Authentication et Firestore.
///
/// Ce service remplace l'ancien système fictif par une architecture réelle
/// basée sur Firebase. Il expose les méthodes nécessaires à l'authentification
/// et à la gestion du profil utilisateur.
///
/// Les erreurs Firebase sont converties en exceptions compréhensibles
/// afin de ne pas exposer les codes techniques directement.
class UserAuthService extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------

  static final UserAuthService instance = UserAuthService._();

  UserAuthService._();

  // ---------------------------------------------------------------------------
  // Firebase instances
  // ---------------------------------------------------------------------------

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Propriétés
  // ---------------------------------------------------------------------------

  /// Retourne l'utilisateur Firebase actuellement connecté, ou null.
  User? get currentUser => _auth.currentUser;

  /// Retourne le fournisseur d'authentification (utilisé pour les écrans
  /// qui auraient besoin d'accéder directement à FirebaseAuth si nécessaire).
  FirebaseAuth get auth => _auth;

  /// Retourne le fournisseur Firestore (utilisé pour les profils).
  FirebaseFirestore get firestore => _firestore;

  // ---------------------------------------------------------------------------
  // Écoute de session
  // ---------------------------------------------------------------------------

  /// Écoute les changements d'état de connexion Firebase Authentication.
  ///
  /// Utilisez ce stream dans vos widgets pour réagir automatiquement
  /// à la connexion ou à la déconnexion d'un utilisateur.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // Authentification
  // ---------------------------------------------------------------------------

  /// Connecte un utilisateur avec son adresse e-mail et son mot de passe.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _convertAuthException(e);
    } catch (e) {
      throw UserAuthException(
        message: 'Impossible de se connecter. Vérifiez votre connexion réseau.',
      );
    }
  }

  /// Crée un nouveau compte utilisateur avec une adresse e-mail et un mot
  /// de passe, puis crée le profil Firestore dans users/{uid}.
  ///
  /// [profileData] doit contenir les champs du profil (firstName, lastName,
  /// phone, role, status, etc.). Les champs uid, email, createdAt et updatedAt
  /// sont ajoutés automatiquement.
  ///
  /// En cas d'échec Firestore après la création Firebase, le compte Firebase
  /// est supprimé pour éviter les orphelins.
  Future<void> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> profileData,
  }) async {
    User? createdUser;

    try {
      // 1. Normalisation de l'email
      final normalizedEmail = email.trim().toLowerCase();

      // 2. Création du compte Firebase Authentication
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

      // 3. Création du profil Firestore avec le vrai UID Firebase
      //    Utilise set() sur doc(uid) pour éviter les doublons
      await _usersCollection.doc(createdUser.uid).set({
        'uid': createdUser.uid,
        'email': normalizedEmail,
        ...profileData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Mettre à jour le displayName Firebase si firstName/lastName fournis
      if (profileData['firstName'] != null || profileData['lastName'] != null) {
        final displayName = [
          profileData['firstName'] ?? '',
          profileData['lastName'] ?? '',
        ].where((n) => n.isNotEmpty).join(' ').trim();

        if (displayName.isNotEmpty) {
          await createdUser.updateDisplayName(displayName);
        }
      }

      // Note : Ne pas naviguer manuellement. Firebase connecte
      // automatiquement l'utilisateur après signUp, et AuthGate réagit
      // à authStateChanges() pour rediriger.
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      // Nettoyage : supprimer le compte Firebase si la création échoue
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      throw _convertAuthException(e);
    } on FirebaseException catch (e) {
      // Échec Firestore : nettoyer le compte Firebase
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      throw UserAuthException(
        message: e.message ?? 'Impossible de créer le profil utilisateur.',
      );
    } catch (e) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      throw UserAuthException(
        message: 'Une erreur inattendue est survenue lors de l\'inscription.',
      );
    }
  }

  /// Déconnecte l'utilisateur actuel.
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Gestion du mot de passe
  // ---------------------------------------------------------------------------

  /// Envoie un e-mail de réinitialisation de mot de passe à l'adresse
  /// indiquée.
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _convertAuthException(e);
    } catch (e) {
      throw UserAuthException(
        message:
            'Impossible d\'envoyer l\'e-mail de réinitialisation. Vérifiez votre connexion réseau.',
      );
    }
  }

  /// Met à jour le mot de passe de l'utilisateur actuellement connecté.
  Future<void> updatePassword({
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw UserAuthException(
        message: 'Vous devez être connecté pour modifier votre mot de passe.',
      );
    }

    try {
      await user.updatePassword(newPassword);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw _convertAuthException(e);
    } catch (e) {
      throw UserAuthException(
        message: 'Impossible de modifier le mot de passe. Réessayez plus tard.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Rechargement et suppression
  // ---------------------------------------------------------------------------

  /// Recharge les données de l'utilisateur actuel depuis Firebase.
  Future<void> reloadUser() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw UserAuthException(
        message: 'Vous devez être connecté pour recharger vos informations.',
      );
    }

    try {
      await user.reload();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw _convertAuthException(e);
    } catch (e) {
      throw UserAuthException(
        message: 'Impossible de recharger les informations.',
      );
    }
  }

  /// Supprime le compte de l'utilisateur actuellement connecté.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw UserAuthException(
        message: 'Vous devez être connecté pour supprimer votre compte.',
      );
    }

    try {
      await user.delete();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw _convertAuthException(e);
    } catch (e) {
      throw UserAuthException(
        message: 'Impossible de supprimer le compte. Réessayez plus tard.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Profil Firestore (méthodes de base)
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Crée un document de profil dans Firestore pour l'utilisateur
  /// identifié par [uid].
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

  /// Récupère le profil Firestore d'un utilisateur à partir de son [uid].
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

  /// Met à jour partiellement ou totalement le profil Firestore d'un
  /// utilisateur.
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

  // ---------------------------------------------------------------------------
  // Inscription complète : Firebase Auth + Firestore
  // ---------------------------------------------------------------------------

  /// Crée un compte Firebase Authentication et son profil Firestore
  /// en une seule opération atomique.
  ///
  /// Les [profileData] doivent au minimum contenir :
  ///   - firstName, lastName, phone, role, status
  ///
  /// En cas d'échec Firestore, le compte Firebase est supprimé pour
  /// éviter les orphelins.
  Future<void> signUpWithProfile({
    required String email,
    required String password,
    required Map<String, dynamic> profileData,
  }) async {
    User? createdUser;

    try {
      // 1. Création du compte Firebase Authentication
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        throw UserAuthException(
          message: 'La création du compte a échoué. Veuillez réessayer.',
        );
      }

      // 2. Création du profil Firestore avec le vrai UID Firebase
      await _usersCollection.doc(createdUser.uid).set({
        'uid': createdUser.uid,
        'email': email.trim().toLowerCase(),
        ...profileData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Mettre à jour le displayName Firebase si firstName/lastName fournis
      if (profileData['firstName'] != null || profileData['lastName'] != null) {
        final displayName = [
          profileData['firstName'] ?? '',
          profileData['lastName'] ?? '',
        ].where((n) => n.isNotEmpty).join(' ').trim();

        if (displayName.isNotEmpty) {
          await createdUser.updateDisplayName(displayName);
        }
      }

      // Note : Ne pas naviguer manuellement. Firebase connecte
      // automatiquement l'utilisateur après signUp, et AuthGate réagit
      // à authStateChanges() pour rediriger.
    } on FirebaseAuthException catch (e) {
      // Nettoyage : supprimer le compte Firebase si la création échoue
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      throw _convertAuthException(e);
    } on FirebaseException catch (e) {
      // Échec Firestore : nettoyer le compte Firebase
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      throw UserAuthException(
        message: e.message ?? 'Impossible de créer le profil utilisateur.',
      );
    } catch (e) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      throw UserAuthException(
        message: 'Une erreur inattendue est survenue lors de l\'inscription.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Connexion complète : Firebase Auth + vérification Firestore
  // ---------------------------------------------------------------------------

  /// Connecte un utilisateur avec son email et mot de passe, puis vérifie
  /// que son profil Firestore existe et que le compte n'est pas désactivé.
  ///
  /// Étapes :
  /// 1. Authentification Firebase (email + mot de passe)
  /// 2. Lecture du document users/{uid} dans Firestore
  /// 3. Vérification que le document existe
  /// 4. Vérification que le status est "active" (si le champ est présent)
  ///
  /// Lance une [UserAuthException] à chaque étape avec un message français.
  Future<void> signInWithProfileCheck({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Authentification Firebase
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw UserAuthException(
          message: 'Impossible de récupérer les informations de connexion.',
        );
      }

      // 2. Lecture du profil Firestore
      final docSnapshot = await _usersCollection.doc(user.uid).get();

      // 3. Vérification que le profil Firestore existe
      if (!docSnapshot.exists) {
        // Profil inexistant → on déconnecte Firebase
        await _auth.signOut();
        throw UserAuthException(
          message: 'Votre compte d\'authentification existe, mais votre profil '
              'utilisateur est introuvable. Contactez l\'assistance.',
        );
      }

      // 4. Vérification du statut du compte
      final data = docSnapshot.data() ?? {};
      final String? status = data['status'] as String?;

      if (status != null && status != 'active') {
        // Compte désactivé → on déconnecte Firebase
        await _auth.signOut();
        String statusMessage;

        switch (status) {
          case 'suspended':
            statusMessage =
                'Votre compte a été suspendu. Contactez l\'assistance.';
            break;
          case 'inactive':
            statusMessage =
                'Votre compte est inactif. Contactez l\'assistance.';
            break;
          case 'blocked':
          case 'disabled':
            statusMessage =
                'Votre compte a été désactivé. Contactez l\'assistance.';
            break;
          case 'pending':
            statusMessage = 'Votre compte est en attente de validation. '
                'Veuillez patienter ou contactez l\'assistance.';
            break;
          default:
            statusMessage = 'Votre compte n\'est pas actif. '
                'Contactez l\'assistance.';
        }

        throw UserAuthException(message: statusMessage);
      }

      // Connexion réussie : AuthGate réagira à authStateChanges()
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw _convertAuthException(e);
    } on UserAuthException {
      // Déjà une exception française, on la relance
      rethrow;
    } catch (e) {
      throw UserAuthException(
        message: 'Impossible de se connecter. Vérifiez votre connexion réseau.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Vérification de profil
  // ---------------------------------------------------------------------------

  /// Vérifie que l'utilisateur actuellement connecté possède un profil
  /// Firestore valide et actif.
  ///
  /// Retourne true si le profil existe et est actif, false sinon.
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
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Conversion des erreurs Firebase
  // ---------------------------------------------------------------------------

  /// Convertit une [FirebaseAuthException] en [UserAuthException] avec
  /// un message compréhensible en français.
  UserAuthException _convertAuthException(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      // Connexion / inscription
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

      // Inscription
      case 'email-already-in-use':
        message = 'Cette adresse e-mail est déjà utilisée.';
        break;
      case 'weak-password':
        message = 'Le mot de passe doit contenir au moins 6 caractères.';
        break;
      case 'operation-not-allowed':
        message = 'La connexion par e-mail et mot de passe n\'est pas activée.';
        break;

      // Réinitialisation du mot de passe
      case 'missing-android-pkg-name':
      case 'missing-continue-uri':
      case 'missing-ios-bundle-id':
        message =
            'Configuration de réinitialisation incomplète. Contactez le support.';
        break;
      case 'invalid-continue-uri':
        message = 'Le lien de réinitialisation n\'est pas valide.';
        break;

      // Changement de mot de passe
      case 'requires-recent-login':
        message =
            'Veuillez vous reconnecter avant de modifier votre mot de passe.';
        break;

      // Suppression de compte
      case 'credential-too-old-login-again':
        message = 'Veuillez vous reconnecter avant de supprimer votre compte.';
        break;

      // Réseau
      case 'network-request-failed':
        message = 'Vérifiez votre connexion Internet puis réessayez.';
        break;

      // Par défaut
      default:
        message = e.message ?? 'Une erreur d\'authentification est survenue.';
    }

    return UserAuthException(
      message: message,
      code: e.code,
    );
  }
}

// ---------------------------------------------------------------------------
// Exception personnalisée
// ---------------------------------------------------------------------------

/// Exception lancée par [UserAuthService] lorsqu'une opération
/// d'authentification échoue.
///
/// Contient un [message] compréhensible en français et un [code]
/// optionnel correspondant au code Firebase d'origine.
class UserAuthException implements Exception {
  UserAuthException({
    required this.message,
    this.code,
  });

  /// Message d'erreur compréhensible.
  final String message;

  /// Code Firebase d'origine (facultatif, utilisé pour le débogage).
  final String? code;

  @override
  String toString() => message;
}
