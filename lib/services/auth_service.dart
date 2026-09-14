import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:openfood_models/openfood_models.dart';

export 'package:openfood_models/openfood_models.dart' show UserRole;

class AuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService();

  // Stream pour suivre l'état de connexion de l'utilisateur
  Stream<auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Obtenir l'utilisateur actuel
  auth.User? get currentUser => _firebaseAuth.currentUser;

  String? _verificationId;

  // Envoi du SMS (OTP)
  Future<void> sendOTP(String phoneNumber) async {
    final completer = Completer<void>();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (auth.PhoneAuthCredential credential) async {
        // Résolution automatique si le téléphone lit le SMS
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

  // Vérification de l'OTP
  Future<void> verifyOTP(String smsCode) async {
    if (_verificationId == null) {
      throw Exception("Aucun code OTP n'a été envoyé.");
    }

    final credential = auth.PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );

    try {
      if (currentUser != null) {
        await currentUser!.linkWithCredential(credential);
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
    try {
      // 0. Vérification du numéro de téléphone unique
      final phoneQuery = await _firestore.collection('users').where('phone', isEqualTo: phone).limit(1).get();
      if (phoneQuery.docs.isNotEmpty) {
        throw Exception("Un compte existe déjà avec ce numéro de téléphone.");
      }
      // 1. Création de l'utilisateur dans Firebase Auth
      final auth.UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final auth.User? user = userCredential.user;

      if (user != null) {
        // 2. Enregistrement des données supplémentaires dans Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'role': role.name,
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          'dateOfBirth': dateOfBirth?.toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
      }

      return user;
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception("Une erreur s'est produite lors de la création du compte.");
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
        }
      }
      
      return userCredential.user;
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception("Une erreur s'est produite lors de la connexion.");
    }
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

  // Gestion des erreurs Firebase
  Exception _handleAuthException(auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception("Le mot de passe fourni est trop faible.");
      case 'email-already-in-use':
        return Exception("Un compte existe déjà pour cet email.");
      case 'user-not-found':
        return Exception("Aucun utilisateur trouvé pour cet email.");
      case 'wrong-password':
        return Exception("Mot de passe incorrect.");
      case 'invalid-email':
        return Exception("Adresse email invalide.");
      default:
        return Exception(e.message ?? "Erreur d'authentification inconnue.");
    }
  }
}
