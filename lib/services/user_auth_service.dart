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
  ///
  /// Exemple :
  /// ```dart
  /// UserAuthService.instance.authStateChanges().listen((User? user) {
  ///   if (user == null) {
  ///     // rediriger vers la connexion
  ///   } else {
  ///     // rediriger vers l'accueil
  ///   }
  /// });
  /// ```
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // Authentification
  // ---------------------------------------------------------------------------

  /// Connecte un utilisateur avec son adresse e-mail et son mot de passe.
  ///
  /// Lance une [UserAuthException] si la connexion échoue, avec un message
  /// compréhensible expliquant la cause (email invalide, mot de passe
  /// incorrect, compte désactivé, problème réseau, etc.).
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
  /// de passe.
  ///
  /// Lance une [UserAuthException] si la création échoue, par exemple si
  /// l'adresse e-mail est déjà utilisée ou si le mot de passe est trop faible.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _convertAuthException(e);
    } catch (e) {
      throw UserAuthException(
        message:
            'Impossible de créer le compte. Vérifiez votre connexion réseau.',
      );
    }
  }

  /// Déconnecte l'utilisateur actuel.
  ///
  /// Après cette méthode, [currentUser] retourne null et le stream
  /// [authStateChanges] émet un événement avec null.
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Gestion du mot de passe
  // ---------------------------------------------------------------------------

  /// Envoie un e-mail de réinitialisation de mot de passe à l'adresse
  /// indiquée.
  ///
  /// Lance une [UserAuthException] si l'adresse e-mail est invalide ou
  /// si l'utilisateur n'existe pas.
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
  ///
  /// Nécessite que l'utilisateur soit connecté ([currentUser] non null).
  /// Lance une [UserAuthException] si l'utilisateur n'est pas connecté,
  /// si le nouveau mot de passe est trop faible, ou si la session a expiré
  /// (l'utilisateur doit alors se reconnecter).
  Future<void> updatePassword({
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw UserAuthException(
        message:
            'Vous devez être connecté pour modifier votre mot de passe.',
      );
    }

    try {
      await user.updatePassword(newPassword);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw _convertAuthException(e);
    } catch (e) {
      throw UserAuthException(
        message:
            'Impossible de modifier le mot de passe. Réessayez plus tard.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Rechargement et suppression
  // ---------------------------------------------------------------------------

  /// Recharge les données de l'utilisateur actuel depuis Firebase.
  ///
  /// Utile pour rafraîchir les informations comme l'adresse e-mail
  /// vérifiée ou le nom d'affichage après une modification.
  Future<void> reloadUser() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw UserAuthException(
        message:
            'Vous devez être connecté pour recharger vos informations.',
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
  ///
  /// Action irréversible. Le compte est définitivement supprimé de
  /// Firebase Authentication. Le profil Firestore devra être supprimé
  /// séparément si nécessaire.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw UserAuthException(
        message:
            'Vous devez être connecté pour supprimer votre compte.',
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
  // Profil Firestore (méthodes préparées)
  // ---------------------------------------------------------------------------

  /// Collection Firestore utilisée pour les profils utilisateurs.
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Crée un document de profil dans Firestore pour l'utilisateur
  /// identifié par [uid].
  ///
  /// Les [data] doivent contenir les informations du profil
  /// (nom, email, rôle, etc.).
  ///
  /// Cette méthode est préparée pour une utilisation ultérieure dans
  /// les écrans d'inscription et de profil.
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
  ///
  /// Retourne un [DocumentSnapshot] contenant les données du profil,
  /// ou null si le document n'existe pas.
  ///
  /// Cette méthode est préparée pour une utilisation ultérieure dans
  /// les écrans de profil et de tableau de bord.
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
  ///
  /// Seuls les champs présents dans [data] seront modifiés.
  ///
  /// Cette méthode est préparée pour une utilisation ultérieure dans
  /// les écrans d'édition de profil.
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
        message =
            'Trop de tentatives. Réessayez dans quelques minutes.';
        break;

      // Inscription
      case 'email-already-in-use':
        message = 'Cette adresse e-mail est déjà utilisée.';
        break;
      case 'weak-password':
        message = 'Le mot de passe doit contenir au moins 6 caractères.';
        break;
      case 'operation-not-allowed':
        message =
            'La connexion par e-mail et mot de passe n\'est pas activée.';
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
        message =
            'Veuillez vous reconnecter avant de supprimer votre compte.';
        break;

      // Réseau
      case 'network-request-failed':
        message = 'Vérifiez votre connexion Internet puis réessayez.';
        break;

      // Par défaut
      default:
        message = e.message ??
            'Une erreur d\'authentification est survenue.';
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
</create_file>
