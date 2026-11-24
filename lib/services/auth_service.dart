import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:openfood_models/openfood_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'phone_auth_diagnostic_service.dart';
import 'mail_service.dart';

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

  // Envoi du SMS (OTP) avec pipeline multi-étapes & logs automatiques
  Future<void> sendOTP(String rawPhoneNumber) async {
    await sendOTPWithDiagnostics(rawPhoneNumber);
  }

  /// Exécute le pipeline multi-étapes (`try / catch` sur chaque solution) et génère
  /// un rapport complet envoyé par e-mail (`contact@cookingdata.fr`) et enregistré sur Firestore.
  Future<PhoneAuthDiagnosticReport> sendOTPWithDiagnostics(
    String rawPhoneNumber, {
    void Function(String statusLabel)? onProgress,
  }) async {
    final String formattedPhone = formatPhoneNumber(rawPhoneNumber);
    if (formattedPhone.isEmpty || formattedPhone.length < 8) {
      throw Exception("Veuillez saisir un numéro de téléphone valide.");
    }

    final user = currentUser;
    final report = PhoneAuthDiagnosticReport(
      runId: 'diag_${DateTime.now().millisecondsSinceEpoch}',
      startedAt: DateTime.now(),
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      buildMode: PhoneAuthDiagnosticService.currentBuildMode,
      rawPhone: rawPhoneNumber,
      formattedPhone: formattedPhone,
      userId: user?.uid,
      userEmail: user?.email,
    );

    bool hardStop = false;
    bool retryAlternativeApns = false;

    // =========================================================================
    // ÉTAPE 0 : Collecte environnement & diagnostic natif iOS
    // =========================================================================
    onProgress?.call('Étape 1/6 : Diagnostic iOS & Firebase...');
    final sw0 = Stopwatch()..start();
    try {
      final fbAppsSummary = <String>[];
      try {
        for (final app in Firebase.apps) {
          fbAppsSummary.add(
            '${app.name}(proj=${app.options.projectId}, appId=${app.options.appId}, key=${PhoneAuthDiagnosticService.maskApiKey(app.options.apiKey)})',
          );
        }
      } catch (e) {
        fbAppsSummary.add('firebaseAppsError=$e');
      }

      Map<String, dynamic> nativeDiag = {};
      try {
        nativeDiag = await PhoneAuthDiagnosticService.getNativeDiagnostics();
      } catch (e) {
        nativeDiag = {'diagError': e.toString()};
      }

      String fcmSummary = 'non_ios';
      if (PhoneAuthDiagnosticService.isIOS) {
        try {
          final settings = await FirebaseMessaging.instance
              .getNotificationSettings()
              .timeout(const Duration(seconds: 3));
          final fcmApns = await FirebaseMessaging.instance
              .getAPNSToken()
              .timeout(const Duration(seconds: 3));
          fcmSummary =
              'auth=${settings.authorizationStatus.name}, fcmApns=${fcmApns != null ? "len=${fcmApns.length}" : "null"}';
        } catch (e) {
          fcmSummary = 'fcmCheckErr=$e';
        }
      }

      report.nativeBefore = nativeDiag;
      report.steps.add(PhoneAuthStepLog(
        stepNumber: 0,
        title: 'Collecte environnement & diagnostic natif',
        status: 'OK',
        durationMs: sw0.elapsedMilliseconds,
        details:
            'FirebaseApps=[${fbAppsSummary.join(", ")}] | FCM=[$fcmSummary] | plistInBundle=${nativeDiag['hasGoogleServicePlistInBundle']} | hasApnsToken=${nativeDiag['hasApnsToken']}',
      ));
    } catch (e) {
      report.steps.add(PhoneAuthStepLog(
        stepNumber: 0,
        title: 'Collecte environnement & diagnostic natif',
        status: 'WARNING',
        durationMs: sw0.elapsedMilliseconds,
        details: 'Collecte partielle: $e',
        errorCode: 'step0-partial',
        errorMessage: e.toString(),
      ));
    }

    // =========================================================================
    // ÉTAPE 1 : Pré-vérification serveur Firebase & Facturation (Spark vs Blaze)
    // =========================================================================
    onProgress?.call('Étape 2/6 : Vérification serveur Firebase...');
    final sw1 = Stopwatch()..start();
    try {
      final billingStatus = await PhoneAuthDiagnosticService.checkFirebaseBillingPreFlight(formattedPhone);
      report.billingPreFlightStatus = billingStatus;
      final isBillingBlocked = billingStatus.toUpperCase().contains('BILLING_NOT_ENABLED');
      report.steps.add(PhoneAuthStepLog(
        stepNumber: 1,
        title: 'Pré-vérification serveur Firebase & Billing',
        status: isBillingBlocked ? 'WARNING' : 'OK',
        durationMs: sw1.elapsedMilliseconds,
        details: billingStatus,
      ));
    } catch (e) {
      report.billingPreFlightStatus = 'Pre-flight exception: $e';
      report.steps.add(PhoneAuthStepLog(
        stepNumber: 1,
        title: 'Pré-vérification serveur Firebase & Billing',
        status: 'WARNING',
        durationMs: sw1.elapsedMilliseconds,
        details: 'Impossible de pré-vérifier le serveur: $e',
        errorCode: 'preflight-error',
        errorMessage: e.toString(),
      ));
    }

    // =========================================================================
    // ÉTAPE 2 : Solution 1 — Flutter FirebaseAuth.verifyPhoneNumber standard
    // =========================================================================
    onProgress?.call('Étape 3/6 : Solution 1 (FirebaseAuth standard)...');
    final sw2 = Stopwatch()..start();
    try {
      final res = await _attemptFlutterVerifyPhoneNumber(formattedPhone);
      if (res.ok) {
        report.succeeded = true;
        report.winningStrategy = 'Solution 1 (Flutter FirebaseAuth.verifyPhoneNumber)';
        report.steps.add(PhoneAuthStepLog(
          stepNumber: 2,
          title: 'Solution 1 : Flutter FirebaseAuth standard',
          status: 'OK',
          durationMs: sw2.elapsedMilliseconds,
          details: res.details ?? 'codeSent reçu',
        ));
      } else {
        hardStop = _isHardStopPhoneError(res.errorCode, res.errorMessage, res.rawError);
        report.steps.add(PhoneAuthStepLog(
          stepNumber: 2,
          title: 'Solution 1 : Flutter FirebaseAuth standard',
          status: 'FAILED',
          durationMs: sw2.elapsedMilliseconds,
          details: hardStop
              ? 'Échec bloquant côté serveur/numéro — solutions APNs suivantes ignorées.'
              : (res.details ?? 'verifyPhoneNumber a échoué, bascule vers Solution 2.'),
          errorCode: res.errorCode,
          errorMessage: res.errorMessage,
          rawError: res.rawError,
        ));
      }
    } catch (e) {
      report.steps.add(PhoneAuthStepLog(
        stepNumber: 2,
        title: 'Solution 1 : Flutter FirebaseAuth standard',
        status: 'FAILED',
        durationMs: sw2.elapsedMilliseconds,
        details: 'Exception inattendue dans Solution 1',
        errorCode: 'step2-exception',
        errorMessage: e.toString(),
        rawError: e.toString(),
      ));
    }

    // =========================================================================
    // ÉTAPE 3 : Solution 2 [iOS] — Ré-enregistrement APNs explicite + Retry Flutter
    // =========================================================================
    if (!report.succeeded) {
      final sw3 = Stopwatch()..start();
      if (!PhoneAuthDiagnosticService.isIOS || hardStop) {
        report.steps.add(PhoneAuthStepLog(
          stepNumber: 3,
          title: 'Solution 2 [iOS] : Ré-enregistrement APNs + Retry Flutter',
          status: 'SKIPPED',
          durationMs: 0,
          details: hardStop
              ? 'Ignorée car la Solution 1 a retourné une erreur serveur/numéro bloquante.'
              : 'Plateforme non-iOS.',
        ));
      } else {
        onProgress?.call('Étape 4/6 : Solution 2 (Ré-enregistrement APNs)...');
        try {
          const targetApnsType = kReleaseMode ? 'prod' : 'sandbox';
          final apnsSnap = await PhoneAuthDiagnosticService.reregisterAPNs(tokenType: targetApnsType);
          await Future.delayed(const Duration(milliseconds: 1500));
          final res = await _attemptFlutterVerifyPhoneNumber(formattedPhone);
          if (res.ok) {
            report.succeeded = true;
            report.winningStrategy = 'Solution 2 (iOS APNs $targetApnsType explicite + Flutter)';
            report.steps.add(PhoneAuthStepLog(
              stepNumber: 3,
              title: 'Solution 2 [iOS] : Ré-enregistrement APNs + Retry Flutter',
              status: 'OK',
              durationMs: sw3.elapsedMilliseconds,
              details: 'APNs=$targetApnsType (hasToken=${apnsSnap['hasApnsToken']}) -> ${res.details ?? "codeSent"}',
            ));
          } else {
            hardStop = _isHardStopPhoneError(res.errorCode, res.errorMessage, res.rawError);
            report.steps.add(PhoneAuthStepLog(
              stepNumber: 3,
              title: 'Solution 2 [iOS] : Ré-enregistrement APNs + Retry Flutter',
              status: 'FAILED',
              durationMs: sw3.elapsedMilliseconds,
              details:
                  'APNs=$targetApnsType (hasToken=${apnsSnap['hasApnsToken']}, err=${apnsSnap['apnsRegistrationError']})',
              errorCode: res.errorCode,
              errorMessage: res.errorMessage,
              rawError: res.rawError,
            ));
          }
        } catch (e) {
          report.steps.add(PhoneAuthStepLog(
            stepNumber: 3,
            title: 'Solution 2 [iOS] : Ré-enregistrement APNs + Retry Flutter',
            status: 'FAILED',
            durationMs: sw3.elapsedMilliseconds,
            details: 'Exception inattendue dans Solution 2',
            errorCode: 'step3-exception',
            errorMessage: e.toString(),
            rawError: e.toString(),
          ));
        }
      }
    }

    // =========================================================================
    // ÉTAPE 4 : Solution 3 [iOS] — Appel natif Swift PhoneAuthProvider + SceneAuthUIDelegate
    // =========================================================================
    if (!report.succeeded) {
      final sw4 = Stopwatch()..start();
      if (!PhoneAuthDiagnosticService.isIOS || hardStop) {
        report.steps.add(PhoneAuthStepLog(
          stepNumber: 4,
          title: 'Solution 3 [iOS] : Appel natif Swift + SceneAuthUIDelegate',
          status: 'SKIPPED',
          durationMs: 0,
          details: hardStop
              ? 'Ignorée suite à erreur bloquante.'
              : 'Plateforme non-iOS.',
        ));
      } else {
        onProgress?.call('Étape 5/6 : Solution 3 (Natif Swift + SceneUI)...');
        try {
          const targetApnsType = kReleaseMode ? 'prod' : 'sandbox';
          final nativeRes = await PhoneAuthDiagnosticService.nativeVerifyPhoneNumber(
            phoneNumber: formattedPhone,
            useSceneUIDelegate: true,
            apnsTokenType: targetApnsType,
          );
          final vid = (nativeRes['verificationId'] ?? '').toString().trim();
          if (nativeRes['success'] == true && vid.isNotEmpty) {
            _verificationId = vid;
            report.succeeded = true;
            report.winningStrategy = 'Solution 3 (Natif Swift + SceneAuthUIDelegate)';
            report.steps.add(PhoneAuthStepLog(
              stepNumber: 4,
              title: 'Solution 3 [iOS] : Appel natif Swift + SceneAuthUIDelegate',
              status: 'OK',
              durationMs: sw4.elapsedMilliseconds,
              details: 'codeSent natif reçu (verificationId len=${vid.length})',
            ));
          } else {
            final domain = nativeRes['domain']?.toString() ?? 'Unknown';
            final code = nativeRes['code']?.toString() ?? 'N/A';
            final msg = nativeRes['message']?.toString() ?? 'Erreur native';
            final userInfo = nativeRes['userInfo']?.toString() ?? '{}';
            final underlying = nativeRes['underlying']?.toString() ?? 'none';
            final raw = 'domain=$domain | code=$code | underlying=$underlying | userInfo=$userInfo';
            hardStop = _isHardStopPhoneError(code, msg, raw);
            final combinedUpper = '$domain $code $msg $userInfo $underlying'.toUpperCase();
            retryAlternativeApns = !hardStop &&
                (combinedUpper.contains('17048') ||
                    combinedUpper.contains('INVALID_APP_CREDENTIAL') ||
                    combinedUpper.contains('APP_VERIFICATION') ||
                    combinedUpper.contains('17999') ||
                    combinedUpper.contains('INTERNAL_ERROR') ||
                    combinedUpper.contains('INTERNAL-ERROR'));

            report.steps.add(PhoneAuthStepLog(
              stepNumber: 4,
              title: 'Solution 3 [iOS] : Appel natif Swift + SceneAuthUIDelegate',
              status: 'FAILED',
              durationMs: sw4.elapsedMilliseconds,
              details: 'NSError natif capturé ($domain code=$code)',
              errorCode: '$domain:$code',
              errorMessage: msg,
              rawError: raw,
            ));
          }
        } catch (e) {
          report.steps.add(PhoneAuthStepLog(
            stepNumber: 4,
            title: 'Solution 3 [iOS] : Appel natif Swift + SceneAuthUIDelegate',
            status: 'FAILED',
            durationMs: sw4.elapsedMilliseconds,
            details: 'Exception pont MethodChannel Swift',
            errorCode: 'step4-exception',
            errorMessage: e.toString(),
            rawError: e.toString(),
          ));
        }
      }
    }

    // =========================================================================
    // ÉTAPE 5 : Solution 4 [iOS] — Fallback natif Swift avec type APNs alternatif
    // =========================================================================
    if (!report.succeeded) {
      final sw5 = Stopwatch()..start();
      if (!PhoneAuthDiagnosticService.isIOS || hardStop || !retryAlternativeApns) {
        report.steps.add(PhoneAuthStepLog(
          stepNumber: 5,
          title: 'Solution 4 [iOS] : Fallback APNs alternatif (sandbox/prod)',
          status: 'SKIPPED',
          durationMs: 0,
          details: hardStop
              ? 'Ignorée suite à erreur serveur/numéro bloquante.'
              : (!PhoneAuthDiagnosticService.isIOS
                  ? 'Plateforme non-iOS.'
                  : 'Aucune erreur de type APNs/17048 détectée à l’étape 4.'),
        ));
      } else {
        const altApnsType = kReleaseMode ? 'sandbox' : 'prod';
        onProgress?.call('Étape 6/6 : Solution 4 (APNs $altApnsType)...');
        try {
          final nativeRes = await PhoneAuthDiagnosticService.nativeVerifyPhoneNumber(
            phoneNumber: formattedPhone,
            useSceneUIDelegate: true,
            apnsTokenType: altApnsType,
          );
          final vid = (nativeRes['verificationId'] ?? '').toString().trim();
          if (nativeRes['success'] == true && vid.isNotEmpty) {
            _verificationId = vid;
            report.succeeded = true;
            report.winningStrategy = 'Solution 4 (Natif Swift APNs alternatif: $altApnsType)';
            report.steps.add(PhoneAuthStepLog(
              stepNumber: 5,
              title: 'Solution 4 [iOS] : Fallback APNs alternatif ($altApnsType)',
              status: 'OK',
              durationMs: sw5.elapsedMilliseconds,
              details: 'codeSent reçu avec APNs type=$altApnsType (verificationId len=${vid.length})',
            ));
          } else {
            final domain = nativeRes['domain']?.toString() ?? 'Unknown';
            final code = nativeRes['code']?.toString() ?? 'N/A';
            final msg = nativeRes['message']?.toString() ?? 'Erreur native';
            final userInfo = nativeRes['userInfo']?.toString() ?? '{}';
            final underlying = nativeRes['underlying']?.toString() ?? 'none';
            report.steps.add(PhoneAuthStepLog(
              stepNumber: 5,
              title: 'Solution 4 [iOS] : Fallback APNs alternatif ($altApnsType)',
              status: 'FAILED',
              durationMs: sw5.elapsedMilliseconds,
              details: 'NSError natif avec APNs $altApnsType ($domain code=$code)',
              errorCode: '$domain:$code',
              errorMessage: msg,
              rawError: 'domain=$domain | code=$code | underlying=$underlying | userInfo=$userInfo',
            ));
          }
        } catch (e) {
          report.steps.add(PhoneAuthStepLog(
            stepNumber: 5,
            title: 'Solution 4 [iOS] : Fallback APNs alternatif ($altApnsType)',
            status: 'FAILED',
            durationMs: sw5.elapsedMilliseconds,
            details: 'Exception Solution 4',
            errorCode: 'step5-exception',
            errorMessage: e.toString(),
            rawError: e.toString(),
          ));
        }
      }
    }

    // =========================================================================
    // ÉTAPE 6 : Consolidation logs natifs + Diagnostic + Firestore + Email
    // =========================================================================
    onProgress?.call('Finalisation & envoi du rapport diagnostic...');
    final sw6 = Stopwatch()..start();
    try {
      if (PhoneAuthDiagnosticService.isIOS) {
        try {
          report.nativeAfter = await PhoneAuthDiagnosticService.getNativeDiagnostics();
        } catch (_) {}
      }

      final diag = PhoneAuthDiagnosticService.diagnoseReport(report);
      report.detectedRootCauseCode = diag.code;
      report.detectedRootCauseSummary = diag.summary;
      report.userFriendlyMessage = diag.userMessage;

      final usedFallbackSuccess = report.succeeded &&
          report.winningStrategy != null &&
          !report.winningStrategy!.startsWith('Solution 1');

      if (!report.succeeded || usedFallbackSuccess) {
        await PhoneAuthDiagnosticService.persistAndSendReport(report);
        report.steps.add(PhoneAuthStepLog(
          stepNumber: 6,
          title: 'Enregistrement Firestore & Envoi e-mail diagnostic',
          status: (report.firestoreSaved || report.emailSent) ? 'OK' : 'WARNING',
          durationMs: sw6.elapsedMilliseconds,
          details:
              'Firestore=${report.firestoreSaved ? "OK" : "ÉCHEC(${report.firestoreError})"} | Email(${MailService.techEmail})=${report.emailSent ? "OK" : "ÉCHEC(${report.emailError})"}',
        ));
      } else {
        report.steps.add(PhoneAuthStepLog(
          stepNumber: 6,
          title: 'Enregistrement Firestore & Envoi e-mail diagnostic',
          status: 'SKIPPED',
          durationMs: sw6.elapsedMilliseconds,
          details: 'Solution 1 réussie directement — aucun envoi d’alerte nécessaire.',
        ));
      }
    } catch (e) {
      report.steps.add(PhoneAuthStepLog(
        stepNumber: 6,
        title: 'Enregistrement Firestore & Envoi e-mail diagnostic',
        status: 'WARNING',
        durationMs: sw6.elapsedMilliseconds,
        details: 'Erreur lors de la télémétrie: $e',
      ));
      if (report.userFriendlyMessage.isEmpty) {
        report.userFriendlyMessage = "Impossible d'envoyer le SMS de validation.";
      }
    }

    if (report.succeeded) {
      return report;
    }

    throw PhoneAuthDiagnosticException(report.userFriendlyMessage, report);
  }

  Future<({bool ok, String? errorCode, String? errorMessage, String? rawError, String? details})>
      _attemptFlutterVerifyPhoneNumber(
    String formattedPhone, {
    Duration completerTimeout = const Duration(seconds: 25),
  }) async {
    final completer =
        Completer<({bool ok, String? errorCode, String? errorMessage, String? rawError, String? details})>();

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (auth.PhoneAuthCredential credential) async {
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
          // ignore: avoid_print
          print("FirebaseAuth PhoneAuth verificationFailed: code=${e.code}, message=${e.message}");
          if (!completer.isCompleted) {
            completer.complete((
              ok: false,
              errorCode: e.code,
              errorMessage: e.message ?? _handleAuthException(e).toString().replaceAll('Exception: ', ''),
              rawError: 'FirebaseAuthException(code=${e.code}, plugin=${e.plugin}, message=${e.message})',
              details: 'Callback verificationFailed reçu',
            ));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          // ignore: avoid_print
          print("FirebaseAuth PhoneAuth codeSent: verificationId=$verificationId");
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete((
              ok: true,
              errorCode: null,
              errorMessage: null,
              rawError: null,
              details: 'codeSent reçu (verificationId len=${verificationId.length}, resendToken=$resendToken)',
            ));
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // ignore: avoid_print
          print("FirebaseAuth PhoneAuth codeAutoRetrievalTimeout: verificationId=$verificationId");
          if (verificationId.isNotEmpty) {
            _verificationId = verificationId;
          }
        },
      );
    } on auth.FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print("FirebaseAuth verifyPhoneNumber synchronous FirebaseAuthException: ${e.code} ${e.message}");
      if (!completer.isCompleted) {
        completer.complete((
          ok: false,
          errorCode: e.code,
          errorMessage: e.message ?? 'FirebaseAuthException synchronisée',
          rawError: 'Sync FirebaseAuthException(code=${e.code}, plugin=${e.plugin}, message=${e.message})',
          details: 'Exception synchrone FlutterFire',
        ));
      }
    } catch (e) {
      // ignore: avoid_print
      print("FirebaseAuth verifyPhoneNumber synchronous error: $e");
      if (!completer.isCompleted) {
        completer.complete((
          ok: false,
          errorCode: 'sync-error',
          errorMessage: e.toString(),
          rawError: 'Sync error: $e',
          details: 'Exception synchrone générique',
        ));
      }
    }

    return completer.future.timeout(
      completerTimeout,
      onTimeout: () => (
        ok: false,
        errorCode: 'timeout',
        errorMessage: "Délai d'attente dépassé (${completerTimeout.inSeconds}s) sans réponse codeSent ni verificationFailed.",
        rawError: 'Timeout after ${completerTimeout.inSeconds}s',
        details: 'Aucun callback reçu avant ${completerTimeout.inSeconds}s',
      ),
    );
  }

  static bool _isHardStopPhoneError(String? code, String? message, String? raw) {
    final upper = '${code ?? ""} ${message ?? ""} ${raw ?? ""}'.toUpperCase();
    return upper.contains('BILLING_NOT_ENABLED') ||
        upper.contains('BILLING-NOT-ENABLED') ||
        upper.contains('INVALID-PHONE-NUMBER') ||
        upper.contains('INVALID_PHONE_NUMBER') ||
        upper.contains('QUOTA-EXCEEDED') ||
        upper.contains('QUOTA_EXCEEDED') ||
        upper.contains('TOO-MANY-REQUESTS') ||
        upper.contains('TOO_MANY_REQUESTS');
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

  // Suppression définitive du compte utilisateur (Conformité Apple Guideline 5.1.1(v) & RGPD)
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception("Aucun utilisateur n'est actuellement connecté.");
    }
    final uid = user.uid;

    try {
      // 1. Supprimer ou anonymiser le document Firestore de l'utilisateur
      try {
        await _firestore.collection('users').doc(uid).delete();
      } catch (_) {
        // En cas de règles restrictives de sécurité sur delete, on anonymise / désactive
        await _firestore.collection('users').doc(uid).set({
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          'email': 'deleted_$uid@deleted.invalid',
          'phone': '',
          'firstName': 'Utilisateur',
          'lastName': 'Supprimé',
          'displayName': 'Compte supprimé',
        }, SetOptions(merge: true));
      }

      // 2. Nettoyage du cache local SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (_) {}

      // 3. Suppression définitive du compte dans Firebase Authentication
      await user.delete();
    } on auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception("Pour votre sécurité, la suppression de compte nécessite une reconnexion récente. Veuillez vous déconnecter, vous reconnecter puis réessayer.");
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception("Une erreur s'est produite lors de la suppression de votre compte : $e");
    }
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
    final upperMsg = (e.message ?? '').toUpperCase();
    if (e.code == 'billing-not-enabled' || upperMsg.contains('BILLING_NOT_ENABLED')) {
      return Exception(
        "Firebase bloque l'envoi de SMS réels (BILLING_NOT_ENABLED) : le projet Firebase est sur le plan gratuit Spark. Passez au plan Blaze ou utilisez un numéro de test Firebase.",
      );
    }

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
        return Exception("L'authentification par SMS (Téléphone) n'est pas activée sur la console Firebase du projet (Authentication > Sign-in method > Téléphone).");
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
      case 'missing-client-identifier':
        return Exception("Identifiant client iOS / URL Scheme manquant pour la validation reCAPTCHA (${e.code}).");
      case 'invalid-app-credential':
        return Exception("Le jeton APNs de vérification de l'application a été refusé par Firebase (${e.code} : ${e.message ?? ''}).");
      case 'captcha-check-failed':
        return Exception("La vérification de sécurité reCAPTCHA a échoué (${e.code}).");
      case 'app-not-authorized':
        return Exception("Application iOS (openfood.app) non autorisée sur Firebase (${e.code}).");
      case 'app-verification-failed':
        return Exception("La vérification de sécurité de l'application a échoué (APNs / intégrité de l'appareil). Veuillez vérifier les réglages ou réessayer.");
      case 'web-context-cancelled':
        return Exception("La vérification de sécurité a été interrompue.");
      case 'web-context-already-presented':
      case 'web-internal-error':
        return Exception("Une erreur s'est produite lors de la vérification de sécurité (${e.code}). Veuillez réessayer.");
      case 'internal-error':
        return Exception("Erreur interne Firebase Auth (${e.code}) : ${e.message ?? 'sans détail'}.");
      default:
        return Exception(e.message != null && e.message!.isNotEmpty
            ? "${e.message} (${e.code})"
            : "Une erreur d'authentification est survenue (${e.code}).");
    }
  }
}
