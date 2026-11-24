import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../firebase_options.dart';
import 'mail_service.dart';

/// Log unitaire d'une étape du pipeline multi-solutions d'envoi de SMS OTP.
class PhoneAuthStepLog {
  final int stepNumber;
  final String title;
  final String status; // OK | SKIPPED | WARNING | FAILED
  final int durationMs;
  final String details;
  final String? errorCode;
  final String? errorMessage;
  final String? rawError;

  const PhoneAuthStepLog({
    required this.stepNumber,
    required this.title,
    required this.status,
    required this.durationMs,
    required this.details,
    this.errorCode,
    this.errorMessage,
    this.rawError,
  });

  Map<String, dynamic> toMap() {
    return {
      'stepNumber': stepNumber,
      'title': title,
      'status': status,
      'durationMs': durationMs,
      'details': details,
      if (errorCode != null) 'errorCode': errorCode,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (rawError != null) 'rawError': rawError,
    };
  }
}

/// Rapport complet généré à chaque tentative de vérification téléphone (succès ou échec).
class PhoneAuthDiagnosticReport {
  final String runId;
  final DateTime startedAt;
  final String appVersion;
  final String platform;
  final String buildMode;
  final String rawPhone;
  final String formattedPhone;
  final String? userId;
  final String? userEmail;

  String billingPreFlightStatus;
  Map<String, dynamic> nativeBefore;
  Map<String, dynamic> nativeAfter;
  final List<PhoneAuthStepLog> steps;

  bool succeeded;
  String? winningStrategy;
  String detectedRootCauseCode;
  String detectedRootCauseSummary;
  String userFriendlyMessage;

  bool firestoreSaved;
  String? firestoreError;
  bool emailSent;
  String? emailError;

  PhoneAuthDiagnosticReport({
    required this.runId,
    required this.startedAt,
    this.appVersion = '1.0.3+18',
    required this.platform,
    required this.buildMode,
    required this.rawPhone,
    required this.formattedPhone,
    this.userId,
    this.userEmail,
    this.billingPreFlightStatus = 'non_verifie',
    Map<String, dynamic>? nativeBefore,
    Map<String, dynamic>? nativeAfter,
    List<PhoneAuthStepLog>? steps,
    this.succeeded = false,
    this.winningStrategy,
    this.detectedRootCauseCode = 'UNKNOWN',
    this.detectedRootCauseSummary = '',
    this.userFriendlyMessage = '',
    this.firestoreSaved = false,
    this.firestoreError,
    this.emailSent = false,
    this.emailError,
  })  : nativeBefore = nativeBefore ?? {},
        nativeAfter = nativeAfter ?? {},
        steps = steps ?? [];

  Map<String, dynamic> toFirestoreMap() {
    return {
      'runId': runId,
      'startedAt': startedAt.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
      'appVersion': appVersion,
      'platform': platform,
      'buildMode': buildMode,
      'rawPhone': rawPhone,
      'formattedPhone': formattedPhone,
      'userId': userId,
      'userEmail': userEmail,
      'billingPreFlightStatus': billingPreFlightStatus,
      'nativeBefore': nativeBefore,
      'nativeAfter': nativeAfter,
      'steps': steps.map((s) => s.toMap()).toList(),
      'succeeded': succeeded,
      'winningStrategy': winningStrategy,
      'detectedRootCauseCode': detectedRootCauseCode,
      'detectedRootCauseSummary': detectedRootCauseSummary,
      'userFriendlyMessage': userFriendlyMessage,
    };
  }

  String toPlainText() {
    final buf = StringBuffer();
    buf.writeln('=== OPENFOOD DIAGNOSTIC AUTHENTIFICATION SMS ===');
    buf.writeln('Run ID       : $runId');
    buf.writeln('Date (UTC)   : ${startedAt.toUtc().toIso8601String()}');
    buf.writeln('App / Build  : $appVersion ($platform / $buildMode)');
    buf.writeln('Téléphone    : "$rawPhone" -> "$formattedPhone"');
    buf.writeln('Utilisateur  : ${userEmail ?? "Anonyme"} (uid=${userId ?? "N/A"})');
    buf.writeln('Résultat     : ${succeeded ? "SUCCÈS ($winningStrategy)" : "ÉCHEC"}');
    buf.writeln('Cause racine : [$detectedRootCauseCode] $detectedRootCauseSummary');
    buf.writeln('Pré-check Firebase Billing : $billingPreFlightStatus');
    buf.writeln('');
    buf.writeln('--- ÉTAPES EXÉCUTÉES ---');
    for (final s in steps) {
      buf.writeln('[Étape ${s.stepNumber}] ${s.title} => ${s.status} (${s.durationMs} ms)');
      if (s.details.isNotEmpty) buf.writeln('   Détails : ${s.details}');
      if (s.errorCode != null || s.errorMessage != null) {
        buf.writeln('   Erreur  : code=${s.errorCode ?? "N/A"} | msg=${s.errorMessage ?? "N/A"}');
      }
      if (s.rawError != null && s.rawError!.isNotEmpty) {
        buf.writeln('   Raw     : ${s.rawError}');
      }
    }

    final native = nativeAfter.isNotEmpty ? nativeAfter : nativeBefore;
    if (native.isNotEmpty) {
      buf.writeln('');
      buf.writeln('--- ÉTAT NATIF iOS (POST-EXÉCUTION) ---');
      buf.writeln('Bundle / Version     : ${native['bundleId']} | ${native['appVersion']}+${native['buildNumber']} (debug=${native['isDebugBuild']})');
      buf.writeln('GoogleService-Info   : present=${native['hasGoogleServicePlistInBundle']} | firebaseApps=${native['firebaseAppCount']} (initAppDelegate=${native['firebaseConfiguredInAppDelegate']})');
      buf.writeln('Firebase Options     : project=${native['firebaseProjectID']} | googleAppID=${native['firebaseGoogleAppID']}');
      buf.writeln('URL Schemes          : ${native['urlSchemes']}');
      buf.writeln('Background Modes     : ${native['backgroundModes']}');
      buf.writeln('APNs Remote Reg      : registered=${native['isRegisteredForRemoteNotifications']} | authStatus=${native['notificationAuthStatus']}');
      buf.writeln('APNs Token           : hasToken=${native['hasApnsToken']} (len=${native['apnsTokenLength']}, prefix=${native['apnsTokenPrefix']}, type=${native['apnsTokenTypeApplied']})');
      buf.writeln('APNs Reg Error       : ${native['apnsRegistrationError']}');
      buf.writeln('Callbacks Natifs     : remoteNotif=${native['remoteNotificationsReceivedCount']} (auth=${native['authHandledNotificationCount']}) | urls=${native['urlsReceivedCount']} (auth=${native['authHandledUrlCount']})');
      final events = native['events'];
      if (events is List && events.isNotEmpty) {
        buf.writeln('Événements iOS récents :');
        for (final ev in events) {
          buf.writeln('  • $ev');
        }
      }
    }

    buf.writeln('');
    buf.writeln('Télémétrie : Firestore=${firestoreSaved ? "OK" : "ÉCHEC ($firestoreError)"} | Email=${emailSent ? "OK" : "ÉCHEC ($emailError)"}');
    return buf.toString();
  }

  String toHtml() {
    const esc = HtmlEscape();
    final statusBg = succeeded ? '#E8F5E9' : '#FFEBEE';
    final statusColor = succeeded ? '#1B5E20' : '#B71C1C';
    final statusTitle = succeeded ? 'SUCCÈS ($winningStrategy)' : 'ÉCHEC ($detectedRootCauseCode)';

    final stepRows = steps.map((s) {
      final badgeColor = switch (s.status) {
        'OK' => '#2E7D32',
        'WARNING' => '#EF6C00',
        'SKIPPED' => '#546E7A',
        _ => '#C62828',
      };
      return '''
      <tr>
        <td style="padding:10px; border-bottom:1px solid #EDF2F7; font-weight:700; color:#1A202C;">#${s.stepNumber}</td>
        <td style="padding:10px; border-bottom:1px solid #EDF2F7; color:#1A202C;">${esc.convert(s.title)}</td>
        <td style="padding:10px; border-bottom:1px solid #EDF2F7;">
          <span style="background-color:$badgeColor; color:#FFFFFF; padding:3px 8px; border-radius:6px; font-size:11px; font-weight:700;">${esc.convert(s.status)}</span>
        </td>
        <td style="padding:10px; border-bottom:1px solid #EDF2F7; color:#4A5568;">${s.durationMs} ms</td>
        <td style="padding:10px; border-bottom:1px solid #EDF2F7; font-size:12px; color:#2D3748;">
          ${esc.convert(s.details)}
          ${(s.errorCode != null || s.errorMessage != null) ? '<br><strong style="color:#C62828;">Erreur: ${esc.convert(s.errorCode ?? '')} — ${esc.convert(s.errorMessage ?? '')}</strong>' : ''}
          ${(s.rawError != null && s.rawError!.isNotEmpty) ? '<br><code style="font-size:11px; color:#4A5568;">${esc.convert(s.rawError!)}</code>' : ''}
        </td>
      </tr>''';
    }).join('\n');

    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Diagnostic Phone Auth OpenFood</title>
</head>
<body style="margin:0; padding:24px; background-color:#F4F6F8; font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; color:#1A1A1A;">
  <div style="max-width:820px; margin:0 auto; background-color:#FFFFFF; border-radius:14px; overflow:hidden; box-shadow:0 4px 18px rgba(0,0,0,0.08);">
    <div style="background-color:#111A13; padding:22px 28px; color:#FFFFFF;">
      <h2 style="margin:0; font-size:20px;">OpenFood — Rapport Diagnostic SMS / Phone Auth</h2>
      <p style="margin:6px 0 0 0; color:#A3B899; font-size:13px;">Run ${esc.convert(runId)} • ${esc.convert(platform)} (${esc.convert(buildMode)}) • v${esc.convert(appVersion)}</p>
    </div>

    <div style="padding:24px 28px;">
      <div style="background-color:$statusBg; border-left:4px solid $statusColor; padding:14px 16px; border-radius:8px; margin-bottom:20px;">
        <div style="font-weight:800; color:$statusColor; font-size:15px;">${esc.convert(statusTitle)}</div>
        <div style="margin-top:6px; font-size:13px; color:#1A202C;"><strong>Diagnostic :</strong> ${esc.convert(detectedRootCauseSummary)}</div>
        <div style="margin-top:4px; font-size:12px; color:#4A5568;"><strong>Pre-flight Billing Firebase :</strong> ${esc.convert(billingPreFlightStatus)}</div>
      </div>

      <p style="font-size:13px; margin:0 0 16px 0; color:#2D3748;">
        <strong>Numéro :</strong> ${esc.convert(rawPhone)} &rarr; ${esc.convert(formattedPhone)}<br>
        <strong>Utilisateur :</strong> ${esc.convert(userEmail ?? 'Anonyme')} (UID: ${esc.convert(userId ?? 'N/A')})
      </p>

      <h3 style="font-size:15px; margin:18px 0 8px 0; color:#111A13;">Déroulé multi-étapes & solutions</h3>
      <table width="100%" cellspacing="0" cellpadding="0" style="border-collapse:collapse; border:1px solid #E2E8F0; font-size:13px;">
        <thead>
          <tr style="background-color:#F8FAFC; text-align:left;">
            <th style="padding:10px; border-bottom:2px solid #E2E8F0;">#</th>
            <th style="padding:10px; border-bottom:2px solid #E2E8F0;">Étape</th>
            <th style="padding:10px; border-bottom:2px solid #E2E8F0;">Statut</th>
            <th style="padding:10px; border-bottom:2px solid #E2E8F0;">Durée</th>
            <th style="padding:10px; border-bottom:2px solid #E2E8F0;">Détails & Erreurs</th>
          </tr>
        </thead>
        <tbody>
          $stepRows
        </tbody>
      </table>

      <h3 style="font-size:15px; margin:22px 0 8px 0; color:#111A13;">Journal brut complet (iOS natif + Firebase)</h3>
      <pre style="background-color:#0F172A; color:#E2E8F0; padding:16px; border-radius:10px; font-size:11.5px; line-height:1.5; overflow-x:auto; white-space:pre-wrap;">${esc.convert(toPlainText())}</pre>
    </div>
  </div>
</body>
</html>
''';
  }
}

/// Exception métier enrichie contenant le rapport de diagnostic complet.
class PhoneAuthDiagnosticException implements Exception {
  final String message;
  final PhoneAuthDiagnosticReport report;

  PhoneAuthDiagnosticException(this.message, this.report);

  @override
  String toString() => message;
}

/// Service centralisant les ponts natifs iOS, la pré-vérification Firebase Billing,
/// l'analyse automatique de la cause racine et l'envoi des journaux par e-mail / Firestore.
class PhoneAuthDiagnosticService {
  static const MethodChannel _channel = MethodChannel('openfood/phone_auth_diag');

  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static String get currentBuildMode {
    if (kReleaseMode) return 'release';
    if (kProfileMode) return 'profile';
    return 'debug';
  }

  /// Lit l'état natif iOS (GoogleService-Info.plist, URL schemes, APNs token, événements Swift).
  static Future<Map<String, dynamic>> getNativeDiagnostics() async {
    if (!isIOS) {
      return {'platform': defaultTargetPlatform.name, 'nativeBridgeSupported': false};
    }
    try {
      final res = await _channel.invokeMethod<dynamic>('getNativeDiagnostics').timeout(const Duration(seconds: 4));
      if (res is Map) {
        return _normalizeMap(res);
      }
      return {'error': 'unexpected_response_type_${res.runtimeType}'};
    } catch (e) {
      return {'bridgeError': e.toString()};
    }
  }

  /// Force le ré-enregistrement APNs côté iOS et réapplique le token avec le type demandé.
  static Future<Map<String, dynamic>> reregisterAPNs({required String tokenType}) async {
    if (!isIOS) {
      return {'platform': defaultTargetPlatform.name, 'nativeBridgeSupported': false};
    }
    try {
      final res = await _channel.invokeMethod<dynamic>('reregisterAPNs', {
        'tokenType': tokenType,
      }).timeout(const Duration(seconds: 5));
      if (res is Map) {
        return _normalizeMap(res);
      }
      return {'error': 'unexpected_response_type_${res.runtimeType}'};
    } catch (e) {
      return {'bridgeError': e.toString()};
    }
  }

  /// Appelle directement `PhoneAuthProvider.provider().verifyPhoneNumber` en Swift
  /// avec un `AuthUIDelegate` compatible `UIScene`, en retournant les codes `NSError` bruts.
  static Future<Map<String, dynamic>> nativeVerifyPhoneNumber({
    required String phoneNumber,
    required bool useSceneUIDelegate,
    String? apnsTokenType,
  }) async {
    if (!isIOS) {
      return {'success': false, 'domain': 'UnsupportedPlatform', 'code': -1, 'message': 'iOS only'};
    }
    try {
      final res = await _channel.invokeMethod<dynamic>('nativeVerifyPhoneNumber', {
        'phoneNumber': phoneNumber,
        'useSceneUIDelegate': useSceneUIDelegate,
        if (apnsTokenType != null) 'apnsTokenType': apnsTokenType,
      }).timeout(const Duration(seconds: 30));
      if (res is Map) {
        return _normalizeMap(res);
      }
      return {'success': false, 'domain': 'MethodChannel', 'code': -2, 'message': 'Réponse native invalide: $res'};
    } on TimeoutException {
      return {'success': false, 'domain': 'Timeout', 'code': -408, 'message': 'Timeout 30s lors de verifyPhoneNumber natif Swift'};
    } catch (e) {
      return {'success': false, 'domain': 'MethodChannelError', 'code': -3, 'message': e.toString()};
    }
  }

  /// Vérifie côté serveur Google Identity Toolkit si la facturation Blaze (SMS) est active.
  /// Ne bloque jamais l'exécution (permet aux numéros de test Firebase de fonctionner).
  static Future<String> checkFirebaseBillingPreFlight(String formattedPhone, {http.Client? client}) async {
    final httpClient = client ?? http.Client();
    final bool ownsClient = client == null;
    try {
      final apiKey = _resolveApiKey();
      final uri = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode?key=$apiKey');
      final response = await httpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phoneNumber': formattedPhone}),
          )
          .timeout(const Duration(seconds: 8));

      final bodyText = response.body;
      String serverMessage = 'HTTP ${response.statusCode}';
      try {
        final decoded = jsonDecode(bodyText);
        if (decoded is Map && decoded['error'] is Map) {
          serverMessage = decoded['error']['message']?.toString() ?? serverMessage;
        }
      } catch (_) {}

      final upper = '${response.statusCode} $serverMessage $bodyText'.toUpperCase();
      if (upper.contains('BILLING_NOT_ENABLED')) {
        return 'BLOCKED: BILLING_NOT_ENABLED (Plan Spark actif - passer au plan Blaze requis pour les SMS réels)';
      }
      if (upper.contains('MISSING_CLIENT_IDENTIFIER') ||
          upper.contains('INVALID_APP_CREDENTIAL') ||
          upper.contains('RECAPTCHA')) {
        return 'OK: Billing/Blaze actif (réponse serveur attendue sans jeton app: $serverMessage)';
      }
      return 'HTTP ${response.statusCode}: $serverMessage';
    } catch (e) {
      return 'Pre-flight impossible (réseau): $e';
    } finally {
      if (ownsClient) {
        httpClient.close();
      }
    }
  }

  /// Analyse automatiquement les étapes et l'état natif pour identifier la cause racine exacte.
  static ({String code, String summary, String userMessage}) diagnoseReport(PhoneAuthDiagnosticReport report) {
    if (report.succeeded) {
      return (
        code: 'SUCCESS',
        summary: 'Code SMS envoyé via ${report.winningStrategy ?? "pipeline standard"}.',
        userMessage: 'Le code de validation SMS a été envoyé avec succès.',
      );
    }

    final native = report.nativeAfter.isNotEmpty ? report.nativeAfter : report.nativeBefore;
    final stepsJoined = report.steps
        .map((s) => '${s.status} ${s.errorCode ?? ""} ${s.errorMessage ?? ""} ${s.rawError ?? ""} ${s.details}')
        .join('\n');
    final upperSteps = stepsJoined.toUpperCase();
    final upperBilling = report.billingPreFlightStatus.toUpperCase();

    // 1. Erreur directe BILLING_NOT_ENABLED remontée par une étape
    if (upperSteps.contains('BILLING_NOT_ENABLED') || upperSteps.contains('BILLING-NOT-ENABLED')) {
      return (
        code: 'BILLING_NOT_ENABLED',
        summary: 'Firebase bloque les SMS réels car le projet est sur le plan gratuit Spark (BILLING_NOT_ENABLED).',
        userMessage:
            "Firebase bloque l'envoi de SMS réels car le projet « Open food app » est encore sur le plan gratuit Spark (BILLING_NOT_ENABLED).\n\n"
            "• Pour envoyer de vrais SMS : passez le projet au plan Blaze (Facturation à l'usage) dans la console Firebase.\n"
            "• Pour tester gratuitement : utilisez un « Numéro de téléphone de test » configuré dans Firebase Authentication.",
      );
    }

    // 2. Fichier GoogleService-Info.plist absent du bundle iOS
    if (native['hasGoogleServicePlistInBundle'] == false) {
      return (
        code: 'MISSING_GOOGLE_SERVICE_PLIST',
        summary: 'GoogleService-Info.plist est absent du bundle compilé (.ipa / Runner.app).',
        userMessage:
            "Le fichier GoogleService-Info.plist est absent de l'application iOS compilée. "
            "Vérifiez son inclusion dans Xcode (Copy Bundle Resources) puis relancez un build.",
      );
    }

    // 3. Conflit d'entitlements APNs (NSCocoaErrorDomain Code=3000)
    if (stepsJoined.contains('Code=3000') ||
        stepsJoined.contains('code=3000') ||
        upperSteps.contains("NO VALID 'APS-ENVIRONMENT'") ||
        '${native['apnsRegistrationError']}'.contains('3000')) {
      return (
        code: 'APNS_ENTITLEMENT_ERROR_3000',
        summary: "Conflit d'entitlements APNs Apple (NSCocoaErrorDomain Code=3000).",
        userMessage:
            "Apple rejette l'enregistrement des notifications push (erreur Code 3000 : aps-environment invalide pour ce profil de signature). "
            "Vérifiez la capacité Push Notifications dans Apple Developer / Codemagic.",
      );
    }

    // 4. Token / Clé APNs invalide ou mauvais environnement (17048 / invalid-app-credential)
    if (upperSteps.contains('INVALID_APP_CREDENTIAL') ||
        upperSteps.contains('INVALID-APP-CREDENTIAL') ||
        stepsJoined.contains('17048')) {
      return (
        code: 'INVALID_APP_CREDENTIAL_17048',
        summary: 'Jeton APNs refusé par Firebase (INVALID_APP_CREDENTIAL / code 17048).',
        userMessage:
            "Firebase a refusé le jeton de vérification APNs de l'appareil (erreur 17048 : INVALID_APP_CREDENTIAL). "
            "Vérifiez la clé .p8 APNs (Développement & Production) et le Team ID dans Firebase Console.",
      );
    }

    // 5. URL scheme manquant pour retour reCAPTCHA Safari
    if (upperSteps.contains('MISSING_CLIENT_IDENTIFIER') ||
        upperSteps.contains('MISSING-CLIENT-IDENTIFIER') ||
        upperSteps.contains('MISSING-URL-SCHEME') ||
        upperSteps.contains('URL SCHEME')) {
      return (
        code: 'MISSING_CLIENT_IDENTIFIER',
        summary: 'Identifiant client / URL Scheme manquant pour la validation reCAPTCHA.',
        userMessage:
            "La configuration de redirection reCAPTCHA iOS (URL Scheme ou jeton APNs) est manquante ou invalide.",
      );
    }

    // 6. Échec ou annulation reCAPTCHA
    if (upperSteps.contains('CAPTCHA_CHECK_FAILED') ||
        upperSteps.contains('CAPTCHA-CHECK-FAILED') ||
        upperSteps.contains('WEB-CONTEXT-CANCELLED') ||
        upperSteps.contains('WEB-INTERNAL-ERROR') ||
        upperSteps.contains('WEB-CONTEXT-ALREADY-PRESENTED')) {
      return (
        code: 'CAPTCHA_FAILED',
        summary: 'La vérification de sécurité reCAPTCHA (SFSafariViewController) a échoué ou été annulée.',
        userMessage:
            "La vérification de sécurité reCAPTCHA a été interrompue ou bloquée. Veuillez réessayer sans fermer la fenêtre de sécurité.",
      );
    }

    // 7. Bundle ID / API Key non autorisée
    if (upperSteps.contains('APP_NOT_AUTHORIZED') || upperSteps.contains('APP-NOT-AUTHORIZED')) {
      return (
        code: 'APP_NOT_AUTHORIZED',
        summary: 'Application non autorisée (Bundle ID ou clé API restreinte dans Google Cloud).',
        userMessage:
            "Cette application (openfood.app) n'est pas autorisée à utiliser l'API Firebase Authentication. Vérifiez les restrictions de clé API dans Google Cloud.",
      );
    }

    // 8. Quotas SMS dépassés
    if (upperSteps.contains('QUOTA_EXCEEDED') ||
        upperSteps.contains('QUOTA-EXCEEDED') ||
        upperSteps.contains('TOO_MANY_REQUESTS') ||
        upperSteps.contains('TOO-MANY-REQUESTS')) {
      return (
        code: 'QUOTA_OR_RATE_LIMIT',
        summary: 'Quota de SMS Firebase dépassé ou trop de tentatives rapprochées.',
        userMessage:
            "Trop de demandes de SMS ou quota journalier dépassé sur ce numéro/projet. Patientez quelques minutes ou utilisez un numéro de test Firebase.",
      );
    }

    // 9. Numéro invalide
    if (upperSteps.contains('INVALID_PHONE_NUMBER') || upperSteps.contains('INVALID-PHONE-NUMBER')) {
      return (
        code: 'INVALID_PHONE_NUMBER',
        summary: 'Format E.164 du numéro de téléphone refusé par Firebase.',
        userMessage:
            "Le format du numéro saisi (${report.formattedPhone}) n'est pas reconnu par Firebase. Vérifiez l'indicatif et les chiffres.",
      );
    }

    // 10. Région SMS bloquée ou méthode Téléphone désactivée
    if (upperSteps.contains('SMS_REGION_NOT_ALLOWED') ||
        upperSteps.contains('OPERATION_NOT_ALLOWED') ||
        upperSteps.contains('OPERATION-NOT-ALLOWED')) {
      return (
        code: 'REGION_OR_PROVIDER_DISABLED',
        summary: 'Région SMS non autorisée ou fournisseur Téléphone désactivé.',
        userMessage:
            "L'envoi de SMS est désactivé pour ce pays ou sur le projet Firebase.",
      );
    }

    // 11. Pré-check Billing indique clairement le plan Spark (même si le SDK iOS a renvoyé une erreur générique/timeout)
    if (upperBilling.contains('BILLING_NOT_ENABLED')) {
      return (
        code: 'BILLING_NOT_ENABLED',
        summary: 'Le serveur Firebase indique BILLING_NOT_ENABLED (plan Spark gratuit).',
        userMessage:
            "La pré-vérification serveur confirme que Firebase bloque les SMS réels (BILLING_NOT_ENABLED — plan Spark gratuit).\n\n"
            "Passez au plan Blaze dans la console Firebase pour envoyer de vrais SMS, ou testez avec un numéro de test configuré dans Firebase.",
      );
    }

    // 12. Timeout sans token APNs reçu côté iOS
    if (native['hasApnsToken'] == false &&
        (upperSteps.contains('TIMEOUT') || '${native['apnsRegistrationError']}' != 'none')) {
      return (
        code: 'APNS_TOKEN_MISSING_TIMEOUT',
        summary: "Aucun jeton APNs n'a été délivré par iOS et le reCAPTCHA a expiré (ou appareil simulateur).",
        userMessage:
            "iOS n'a pas reçu de jeton de notification APNs (indispensable hors Simulateur) et la vérification a expiré. "
            "Consultez le journal détaillé ci-dessous.",
      );
    }

    // 13. Fallback générique citant la dernière erreur observée
    final lastFailed = report.steps.lastWhere(
      (s) => s.status == 'FAILED',
      orElse: () => const PhoneAuthStepLog(
        stepNumber: 0,
        title: 'Inconnu',
        status: 'FAILED',
        durationMs: 0,
        details: 'Aucune erreur détaillée capturée',
      ),
    );
    final codeStr = lastFailed.errorCode ?? 'UNKNOWN';
    final msgStr = lastFailed.errorMessage ?? lastFailed.details;
    return (
      code: codeStr,
      summary: 'Échec sur [${lastFailed.title}] ($codeStr): $msgStr',
      userMessage: "Impossible d'envoyer le SMS ($codeStr) : $msgStr",
    );
  }

  /// Sauvegarde le rapport dans Firestore et l'envoie par e-mail à contact@cookingdata.fr.
  static Future<void> persistAndSendReport(PhoneAuthDiagnosticReport report) async {
    // 1. Enregistrement Firestore (avec fallback sur analytics_events si non authentifié)
    try {
      final db = FirebaseFirestore.instance;
      final payload = report.toFirestoreMap();
      try {
        await db.collection('phone_auth_logs').add(payload).timeout(const Duration(seconds: 5));
        report.firestoreSaved = true;
      } catch (primaryErr) {
        try {
          await db.collection('analytics_events').add({
            'type': 'phone_auth_diagnostic',
            ...payload,
          }).timeout(const Duration(seconds: 5));
          report.firestoreSaved = true;
          report.firestoreError = 'Fallback analytics_events (primary: $primaryErr)';
        } catch (fallbackErr) {
          report.firestoreSaved = false;
          report.firestoreError = 'primary=$primaryErr | fallback=$fallbackErr';
        }
      }
    } catch (e) {
      report.firestoreSaved = false;
      report.firestoreError = e.toString();
    }

    // 2. Envoi d'e-mail diagnostic via SMTP OVH
    try {
      final statusTag = report.succeeded ? 'SUCCÈS FALLBACK' : 'ÉCHEC (${report.detectedRootCauseCode})';
      await MailService.sendPhoneAuthDiagnosticEmail(
        subject: '[OpenFood PhoneAuth Diag] $statusTag — ${report.formattedPhone}',
        plainTextBody: report.toPlainText(),
        htmlBody: report.toHtml(),
      );
      report.emailSent = true;
    } catch (e) {
      report.emailSent = false;
      report.emailError = e.toString();
    }
  }

  /// Masque partiellement une clé API pour les journaux.
  static String maskApiKey(String? key) {
    if (key == null || key.isEmpty) return 'nil';
    if (key.length <= 10) return '${key.substring(0, 4)}***';
    return '${key.substring(0, 10)}***';
  }

  static String _resolveApiKey() {
    try {
      if (Firebase.apps.isNotEmpty) {
        final k = Firebase.app().options.apiKey;
        if (k.isNotEmpty) return k;
      }
    } catch (_) {}
    return DefaultFirebaseOptions.currentPlatform.apiKey;
  }

  static Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> raw) {
    final result = <String, dynamic>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final val = entry.value;
      if (val is Map) {
        result[key] = _normalizeMap(val);
      } else if (val is List) {
        result[key] = val.map((item) => item is Map ? _normalizeMap(item) : item).toList();
      } else {
        result[key] = val;
      }
    }
    return result;
  }
}
