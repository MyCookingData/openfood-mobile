import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:openfood_models/openfood_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:openfood_models/openfood_models.dart' show UserRole;

class AuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService() {
    _firebaseAuth.setLanguageCode('fr');
  }

  // Stream pour suivre l'état de connexion de l'utilisateur
  Stream<auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Obtenir l'utilisateur actuel
  auth.User? get currentUser => _firebaseAuth.currentUser;

  String? _verificationId;

  // Envoi ou réexpédition de l'email de vérification personnalisé
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        // 1. Appel de la Cloud Function pour l'envoi HTML brandé OpenFood via OVH SMTP
        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendVerificationEmail');
        await callable.call(<String, dynamic>{
          'email': user.email,
          'displayName': user.displayName,
        });
      } catch (e) {
        // Fallback Firebase standard en cas de besoin
        try {
          await _firebaseAuth.setLanguageCode('fr');
          await user.sendEmailVerification();
        } on auth.FirebaseAuthException catch (authErr) {
          throw _handleAuthException(authErr);
        } catch (_) {
          throw Exception("Impossible d'expédier l'e-mail de confirmation : $e");
        }
      }
    } else {
      throw Exception("Aucun utilisateur n'est actuellement connecté.");
    }
  }

  // Rafraîchir l'état de validation de l'email
  Future<bool> reloadAndCheckEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
      return _firebaseAuth.currentUser?.emailVerified ?? false;
    }
    return false;
  }

  // Normalisation du numéro au format international E.164
  static String formatPhoneNumber(String raw) {
    String cleaned = raw.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
    if (cleaned.isEmpty) return '';

    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }

    // Si commence déjà par un indicatif international avec '+'
    if (cleaned.startsWith('+596')) {
      String rest = cleaned.substring(4);
      if (rest.startsWith('0')) rest = rest.substring(1);
      return '+596$rest';
    }
    if (cleaned.startsWith('+590')) {
      String rest = cleaned.substring(4);
      if (rest.startsWith('0')) rest = rest.substring(1);
      return '+590$rest';
    }
    if (cleaned.startsWith('+594')) {
      String rest = cleaned.substring(4);
      if (rest.startsWith('0')) rest = rest.substring(1);
      return '+594$rest';
    }
    if (cleaned.startsWith('+33')) {
      String rest = cleaned.substring(3);
      if (rest.startsWith('0')) rest = rest.substring(1);
      return '+33$rest';
    }
    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    // Sans indicatif international
    // Antilles & Guyane (avec 0 initial: 0696..., 0690..., 0694..., 0596..., etc.)
    if (cleaned.startsWith('0696') || cleaned.startsWith('0697') || cleaned.startsWith('0596')) {
      return '+596${cleaned.substring(1)}';
    }
    if (cleaned.startsWith('0690') || cleaned.startsWith('0691') || cleaned.startsWith('0590')) {
      return '+590${cleaned.substring(1)}';
    }
    if (cleaned.startsWith('0694') || cleaned.startsWith('0594')) {
      return '+594${cleaned.substring(1)}';
    }

    // Antilles & Guyane (sans 0 initial: 696..., 690..., 694..., 596...)
    if (cleaned.startsWith('696') || cleaned.startsWith('697')) {
      return '+596$cleaned';
    }
    if (cleaned.startsWith('690') || cleaned.startsWith('691')) {
      return '+590$cleaned';
    }
    if (cleaned.startsWith('694')) {
      return '+594$cleaned';
    }
    if (cleaned.startsWith('596') && cleaned.length >= 9) {
      return '+596$cleaned';
    }
    if (cleaned.startsWith('590') && cleaned.length >= 9) {
      return '+590$cleaned';
    }
    if (cleaned.startsWith('594') && cleaned.length >= 9) {
      return '+594$cleaned';
    }

    // Métropole (06..., 07..., 01..., etc.)
    if (cleaned.startsWith('06') || cleaned.startsWith('07') || cleaned.startsWith('01') || cleaned.startsWith('02') || cleaned.startsWith('03') || cleaned.startsWith('04') || cleaned.startsWith('05')) {
      return '+33${cleaned.substring(1)}';
    }
    if (cleaned.startsWith('6') || cleaned.startsWith('7')) {
      return '+33$cleaned';
    }

    return '+$cleaned';
  }

  // Validation stricte de la sécurité du mot de passe
  static String? validatePasswordStrength(String password) {
    if (password.length < 8) {
      return "Le mot de passe doit comporter au moins 8 caractères.";
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Le mot de passe doit contenir au moins une lettre majuscule (A-Z).";
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Le mot de passe doit contenir au moins une lettre minuscule (a-z).";
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Le mot de passe doit contenir au moins un chiffre (0-9).";
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>\_\-+=\[\]/\\]').hasMatch(password)) {
      return "Le mot de passe doit contenir au moins un caractère spécial (@, #, !, %, &...).";
    }
    return null;
  }

  // Envoi du SMS (OTP)
  Future<void> sendOTP(String rawPhoneNumber) async {
    final String formattedPhone = formatPhoneNumber(rawPhoneNumber);
    final completer = Completer<void>();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: (auth.PhoneAuthCredential credential) async {
        // Résolution automatique sur Android si le SMS est lu
        try {
          if (currentUser != null) {
            await currentUser!.linkWithCredential(credential);
            await _firestore.collection('users').doc(currentUser!.uid).update({
              'isPhoneVerified': true,
              'phone': formattedPhone,
            }).catchError((_) {});
          }
        } catch (_) {}
      },
      verificationFailed: (auth.FirebaseAuthException e) {
        if (!completer.isCompleted) completer.completeError(_handleAuthException(e));
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );

    return completer.future;
  }

  // Vérification de l'OTP saisi par l'utilisateur
  Future<void> verifyOTP(String smsCode, {String? phoneNumber}) async {
    if (_verificationId == null) {
      throw Exception("Aucun code OTP n'a été envoyé. Veuillez demander un nouveau code SMS.");
    }

    final credential = auth.PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode.trim(),
    );

    try {
      if (currentUser != null) {
        try {
          await currentUser!.linkWithCredential(credential);
        } catch (e) {
          // Si déjà lié ou conflit mineur, ignorer
        }
        // Mise à jour Firestore du statut vérifié
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'isPhoneVerified': true,
          if (phoneNumber != null) 'phone': formatPhoneNumber(phoneNumber),
        }).catchError((_) {});
      } else {
        await _firebaseAuth.signInWithCredential(credential);
      }
    } on auth.FirebaseAuthException catch (e) {
      if (e.code != 'credential-already-in-use') {
        throw _handleAuthException(e);
      }
    }
  }

  // Création de compte (Sign Up) et enregistrement du rôle dans Firestore
  Future<auth.User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required UserRole role,
    required String phone,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  }) async {
    final formattedPhone = formatPhoneNumber(phone);
    final fullName = "${firstName ?? ''} ${lastName ?? ''}".trim();

    try {
      // 0. Vérification de la majorité (18 ans minimum selon les CGU)
      if (dateOfBirth != null) {
        final now = DateTime.now();
        int age = now.year - dateOfBirth.year;
        if (now.month < dateOfBirth.month || (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
          age--;
        }
        if (age < 18) {
          throw Exception("Vous devez avoir au moins 18 ans pour vous inscrire sur OpenFood.");
        }
      }

      // 1. Validation de la complexité du mot de passe
      final pwdError = validatePasswordStrength(password);
      if (pwdError != null) {
        throw Exception(pwdError);
      }

      // 2. Création de l'utilisateur dans Firebase Auth
      final auth.UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final auth.User? user = userCredential.user;

      if (user != null) {
        // Mise à jour du displayName dans Firebase Auth
        if (fullName.isNotEmpty) {
          try {
            await user.updateDisplayName(fullName);
          } catch (_) {}
        }

        // Envoi automatique de l'e-mail de confirmation personnalisé
        try {
          await sendEmailVerification();
        } catch (e) {
          // Log silencieux si l'envoi d'email échoue pour ne pas bloquer l'inscription
        }

        // Enregistrement des données utilisateur complètes dans Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'role': role.name,
          'firstName': firstName?.trim(),
          'lastName': lastName?.trim(),
          'displayName': fullName.isNotEmpty ? fullName : (firstName?.trim() ?? "Client"),
          'phone': formattedPhone,
          'dateOfBirth': dateOfBirth?.toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        // Persistance immédiate dans SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('phoneNumber', formattedPhone);
          if (firstName != null && firstName.trim().isNotEmpty) {
            await prefs.setString('firstName', firstName.trim());
          }
          if (lastName != null && lastName.trim().isNotEmpty) {
            await prefs.setString('lastName', lastName.trim());
          }
          await prefs.setString('displayName', fullName.isNotEmpty ? fullName : (firstName?.trim() ?? "Client"));
        } catch (_) {}
      }

      return user;
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  // Connexion (Sign In)
  Future<auth.User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final auth.UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['isActive'] == false) {
            await _firebaseAuth.signOut();
            throw Exception("Votre compte a été bloqué par un administrateur.");
          }

          // Synchronisation locale immédiate dans SharedPreferences
          try {
            final prefs = await SharedPreferences.getInstance();
            if (data['phone'] != null) await prefs.setString('phoneNumber', data['phone']);
            if (data['firstName'] != null) await prefs.setString('firstName', data['firstName']);
            if (data['lastName'] != null) await prefs.setString('lastName', data['lastName']);
            if (data['displayName'] != null) await prefs.setString('displayName', data['displayName']);
            if (data['isPhoneVerified'] == true) await prefs.setBool('isPhoneValidated', true);
          } catch (_) {}
        }
      }
      
      return userCredential.user;
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception("Une erreur s'est produite lors de la connexion.");
    }
  }

  // Récupération complète du profil utilisateur Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // Déconnexion (Sign Out)
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Obtenir le rôle de l'utilisateur actuel depuis Firestore
  Future<UserRole?> getUserRole(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final String roleString = data['role'] ?? 'client';
        return UserRole.values.firstWhere(
          (e) => e.name == roleString,
          orElse: () => UserRole.client,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Envoi d'un email de réinitialisation de mot de passe
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception("Une erreur s'est produite lors de l'envoi de l'email de réinitialisation.");
    }
  }

  // Gestion des erreurs Firebase avec messages clairs et détaillés
  Exception _handleAuthException(auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception("Le mot de passe est trop court. Veuillez saisir au moins 6 caractères.");
      case 'email-already-in-use':
        return Exception("Cette adresse e-mail est déjà utilisée pour un compte OpenFood. Veuillez vous connecter ou réinitialiser votre mot de passe.");
      case 'user-not-found':
        return Exception("Aucun compte associé à cette adresse e-mail n'a été trouvé.");
      case 'wrong-password':
      case 'invalid-credential':
        return Exception("Mot de passe incorrect. Veuillez vérifier vos identifiants ou cliquer sur « Mot de passe oublié ».");
      case 'invalid-email':
        return Exception("L'adresse e-mail saisie n'a pas un format valide (ex: contact@domaine.fr).");
      case 'operation-not-allowed':
        return Exception("L'authentification par e-mail/mot de passe n'est pas activée sur le serveur.");
      case 'network-request-failed':
        return Exception("Impossible de joindre les serveurs OpenFood. Veuillez vérifier votre connexion internet.");
      case 'too-many-requests':
        return Exception("Trop de tentatives infructueuses consécutives. Votre accès est temporairement suspendu pour des raisons de sécurité. Veuillez réessayer dans quelques minutes.");
      case 'user-disabled':
        return Exception("Ce compte utilisateur a été désactivé par un administrateur.");
      case 'invalid-phone-number':
        return Exception("Le numéro de téléphone saisi est invalide pour l'envoi du SMS de confirmation.");
      case 'quota-exceeded':
        return Exception("Le quota de SMS a été temporairement atteint. Veuillez réessayer ultérieurement.");
      case 'invalid-verification-code':
        return Exception("Le code de validation SMS saisi est incorrect. Veuillez vérifier les 6 chiffres.");
      case 'session-expired':
        return Exception("Le code de validation SMS a expiré. Veuillez demander un nouveau code.");
      default:
        return Exception(e.message ?? "Une erreur d'authentification est survenue (${e.code}).");
    }
  }
}
