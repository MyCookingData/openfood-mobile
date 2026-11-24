import 'package:flutter_test/flutter_test.dart';
import 'package:openfood_mobile/services/auth_service.dart';
import 'package:openfood_mobile/services/phone_auth_diagnostic_service.dart';

PhoneAuthDiagnosticReport _makeBaseReport({
  bool succeeded = false,
  String? winningStrategy,
  String billingPreFlightStatus = 'OK: Billing/Blaze actif',
  Map<String, dynamic>? nativeAfter,
  List<PhoneAuthStepLog>? steps,
}) {
  return PhoneAuthDiagnosticReport(
    runId: 'diag_test_001',
    startedAt: DateTime.utc(2026, 11, 24, 12, 0, 0),
    platform: 'iOS',
    buildMode: 'release',
    rawPhone: '0696 12 34 56',
    formattedPhone: '+596696123456',
    userId: 'uid_test_123',
    userEmail: 'test@openfood.fr',
    billingPreFlightStatus: billingPreFlightStatus,
    nativeAfter: nativeAfter ?? {'hasGoogleServicePlistInBundle': true, 'hasApnsToken': true},
    steps: steps ?? const [],
    succeeded: succeeded,
    winningStrategy: winningStrategy,
  );
}

void main() {
  group('PhoneAuthDiagnosticService.diagnoseReport Tests', () {
    test('detects BILLING_NOT_ENABLED in step error', () {
      final report = _makeBaseReport(
        billingPreFlightStatus: 'BLOCKED: BILLING_NOT_ENABLED',
        steps: const [
          PhoneAuthStepLog(
            stepNumber: 2,
            title: 'Solution 1',
            status: 'FAILED',
            durationMs: 320,
            details: 'Échec bloquant',
            errorCode: 'billing-not-enabled',
            errorMessage: 'BILLING_NOT_ENABLED',
          ),
        ],
      );
      final diag = PhoneAuthDiagnosticService.diagnoseReport(report);
      expect(diag.code, 'BILLING_NOT_ENABLED');
      expect(diag.summary, contains('Spark'));
      expect(diag.userMessage, contains('Blaze'));
    });

    test('detects BILLING_NOT_ENABLED via preflight when SDK wraps error as timeout', () {
      final report = _makeBaseReport(
        billingPreFlightStatus: 'BLOCKED: BILLING_NOT_ENABLED (Plan Spark)',
        steps: const [
          PhoneAuthStepLog(
            stepNumber: 2,
            title: 'Solution 1',
            status: 'FAILED',
            durationMs: 25000,
            details: 'Timeout',
            errorCode: 'timeout',
            errorMessage: 'Délai dépassé',
          ),
        ],
      );
      final diag = PhoneAuthDiagnosticService.diagnoseReport(report);
      expect(diag.code, 'BILLING_NOT_ENABLED');
      expect(diag.userMessage, contains('BILLING_NOT_ENABLED'));
    });

    test('detects invalid-app-credential (17048)', () {
      final report = _makeBaseReport(
        steps: const [
          PhoneAuthStepLog(
            stepNumber: 4,
            title: 'Solution 3',
            status: 'FAILED',
            durationMs: 410,
            details: 'NSError 17048',
            errorCode: 'FIRAuthErrorDomain:17048',
            errorMessage: 'INVALID_APP_CREDENTIAL: Invalid token',
          ),
        ],
      );
      final diag = PhoneAuthDiagnosticService.diagnoseReport(report);
      expect(diag.code, 'INVALID_APP_CREDENTIAL_17048');
      expect(diag.userMessage, contains('17048'));
    });

    test('detects NSCocoaErrorDomain Code=3000 entitlement error', () {
      final report = _makeBaseReport(
        nativeAfter: {
          'hasGoogleServicePlistInBundle': true,
          'hasApnsToken': false,
          'apnsRegistrationError': 'domain=NSCocoaErrorDomain, code=3000',
        },
        steps: const [
          PhoneAuthStepLog(
            stepNumber: 3,
            title: 'Solution 2',
            status: 'FAILED',
            durationMs: 1200,
            details: "Error Domain=NSCocoaErrorDomain Code=3000 \"no valid 'aps-environment'\"",
            errorCode: 'app-verification-failed',
          ),
        ],
      );
      final diag = PhoneAuthDiagnosticService.diagnoseReport(report);
      expect(diag.code, 'APNS_ENTITLEMENT_ERROR_3000');
      expect(diag.userMessage, contains('Code 3000'));
    });

    test('detects missing GoogleService-Info.plist in bundle', () {
      final report = _makeBaseReport(
        nativeAfter: {'hasGoogleServicePlistInBundle': false, 'hasApnsToken': false},
        steps: const [
          PhoneAuthStepLog(
            stepNumber: 2,
            title: 'Solution 1',
            status: 'FAILED',
            durationMs: 200,
            details: 'init failed',
            errorCode: 'internal-error',
          ),
        ],
      );
      final diag = PhoneAuthDiagnosticService.diagnoseReport(report);
      expect(diag.code, 'MISSING_GOOGLE_SERVICE_PLIST');
      expect(diag.userMessage, contains('GoogleService-Info.plist'));
    });

    test('detects timeout when APNs token is missing', () {
      final report = _makeBaseReport(
        nativeAfter: {
          'hasGoogleServicePlistInBundle': true,
          'hasApnsToken': false,
          'apnsRegistrationError': 'none',
        },
        steps: const [
          PhoneAuthStepLog(
            stepNumber: 2,
            title: 'Solution 1',
            status: 'FAILED',
            durationMs: 25000,
            details: 'Timeout 25s',
            errorCode: 'timeout',
          ),
        ],
      );
      final diag = PhoneAuthDiagnosticService.diagnoseReport(report);
      expect(diag.code, 'APNS_TOKEN_MISSING_TIMEOUT');
      expect(diag.userMessage, contains('APNs'));
    });

    test('detects quota-exceeded', () {
      final report = _makeBaseReport(
        steps: const [
          PhoneAuthStepLog(
            stepNumber: 2,
            title: 'Solution 1',
            status: 'FAILED',
            durationMs: 310,
            details: 'quota hit',
            errorCode: 'quota-exceeded',
            errorMessage: 'SMS quota exceeded',
          ),
        ],
      );
      final diag = PhoneAuthDiagnosticService.diagnoseReport(report);
      expect(diag.code, 'QUOTA_OR_RATE_LIMIT');
    });

    test('falls back cleanly for unknown generic error', () {
      final report = _makeBaseReport(
        steps: const [
          PhoneAuthStepLog(
            stepNumber: 2,
            title: 'Solution 1',
            status: 'FAILED',
            durationMs: 500,
            details: 'mystery failure',
            errorCode: 'weird-custom-code',
            errorMessage: 'Unexpected backend glitch',
          ),
        ],
      );
      final diag = PhoneAuthDiagnosticService.diagnoseReport(report);
      expect(diag.code, 'weird-custom-code');
      expect(diag.userMessage, contains('Unexpected backend glitch'));
    });
  });

  group('PhoneAuthDiagnosticReport serialization Tests', () {
    test('toPlainText, toHtml (with escaping), and toFirestoreMap include steps', () {
      final report = _makeBaseReport(
        billingPreFlightStatus: 'BLOCKED: <BILLING_NOT_ENABLED>',
        steps: const [
          PhoneAuthStepLog(
            stepNumber: 0,
            title: 'Diagnostic iOS',
            status: 'OK',
            durationMs: 42,
            details: 'plist=true & <tag>',
          ),
          PhoneAuthStepLog(
            stepNumber: 2,
            title: 'Solution 1',
            status: 'FAILED',
            durationMs: 300,
            details: 'Rejet serveur',
            errorCode: 'billing-not-enabled',
            errorMessage: 'BILLING_NOT_ENABLED',
          ),
        ],
      );
      report.detectedRootCauseCode = 'BILLING_NOT_ENABLED';
      report.detectedRootCauseSummary = 'Plan Spark actif';

      final plain = report.toPlainText();
      expect(plain, contains('diag_test_001'));
      expect(plain, contains('+596696123456'));
      expect(plain, contains('Étape 0'));
      expect(plain, contains('BILLING_NOT_ENABLED'));

      final html = report.toHtml();
      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('&lt;tag&gt;'));
      expect(html, contains('&lt;BILLING_NOT_ENABLED&gt;'));

      final fsMap = report.toFirestoreMap();
      expect(fsMap['runId'], 'diag_test_001');
      expect(fsMap['formattedPhone'], '+596696123456');
      expect((fsMap['steps'] as List).length, 2);
      expect(fsMap['createdAt'], isNotNull);
    });
  });

  group('AuthService.formatPhoneNumber Tests', () {
    test('normalizes Martinique, Guadeloupe, Guyane, and France numbers', () {
      expect(AuthService.formatPhoneNumber('0696 12 34 56'), '+596696123456');
      expect(AuthService.formatPhoneNumber('+596 0696 12 34 56'), '+596696123456');
      expect(AuthService.formatPhoneNumber('0690 11 22 33'), '+590690112233');
      expect(AuthService.formatPhoneNumber('0694 44 55 66'), '+594694445566');
      expect(AuthService.formatPhoneNumber('06 12 34 56 78'), '+33612345678');
    });
  });
}
