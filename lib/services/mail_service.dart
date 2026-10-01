import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class MailService {
  static final SmtpServer _smtpServer = SmtpServer(
    'ssl0.ovh.net',
    port: 465,
    ssl: true,
    username: 'noreply@openfood.fr',
    password: 'Open97222@',
  );

  /// Génère le modèle HTML OpenFood élégant et sécurisé
  static String buildVerificationHtml({
    required String name,
    required String verificationLink,
  }) {
    final String greeting = name.isNotEmpty ? 'Bonjour <strong>$name</strong>,' : 'Bonjour,';
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Validation de votre compte OpenFood</title>
</head>
<body style="margin:0; padding:0; background-color:#F4F6F8; font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color:#1A1A1A;">
  <table width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color:#F4F6F8; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table width="100%" max-width="580" border="0" cellspacing="0" cellpadding="0" style="max-width:580px; background-color:#FFFFFF; border-radius:16px; overflow:hidden; box-shadow:0 4px 20px rgba(0,0,0,0.06);">
          <!-- Header -->
          <tr>
            <td style="background-color:#111A13; padding:32px 24px; text-align:center;">
              <h1 style="color:#FFFFFF; font-size:26px; font-weight:800; margin:0; letter-spacing:0.5px;">OpenFood</h1>
              <p style="color:#A3B899; font-size:13px; margin:6px 0 0 0; text-transform:uppercase; letter-spacing:1px;">La gastronomie livrée chez vous</p>
            </td>
          </tr>
          
          <!-- Body -->
          <tr>
            <td style="padding:36px 32px 28px 32px;">
              <p style="font-size:17px; line-height:26px; margin:0 0 16px 0; color:#1A1A1A;">
                $greeting
              </p>
              <p style="font-size:15px; line-height:24px; margin:0 0 24px 0; color:#4A5568;">
                Bienvenue sur <strong>OpenFood</strong>. Pour finaliser la création de votre compte et accéder à toutes nos fonctionnalités, veuillez confirmer votre adresse e-mail en cliquant sur le bouton ci-dessous :
              </p>
              
              <!-- Bouton d'action -->
              <div style="text-align:center; margin:32px 0 36px 0;">
                <a href="$verificationLink" style="background-color:#2E7D32; color:#FFFFFF; font-size:16px; font-weight:700; text-decoration:none; padding:14px 32px; border-radius:10px; display:inline-block;">
                  Confirmer mon adresse e-mail
                </a>
              </div>
              
              <p style="font-size:13px; line-height:20px; color:#718096; margin:0 0 8px 0;">
                Si vous n'êtes pas à l'origine de cette inscription, vous pouvez ignorer cet e-mail en toute sécurité.
              </p>
              <p style="font-size:14px; line-height:22px; color:#1A1A1A; margin:20px 0 0 0; font-weight:600;">
                À très bientôt,<br>
                <span style="font-weight:400; color:#4A5568;">L'équipe OpenFood</span>
              </p>
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td style="background-color:#F8FAFC; border-top:1px solid #EDF2F7; padding:20px 32px; text-align:center;">
              <p style="font-size:12px; line-height:18px; color:#A0AEC0; margin:0;">
                OpenFood — Martinique & Caraïbes<br>
                Une question ? Contactez-nous à <a href="mailto:contact@openfood.fr" style="color:#2E7D32; text-decoration:none;">contact@openfood.fr</a>
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }

  /// Envoie l'e-mail de confirmation avec le template HTML personnalisé
  static Future<void> sendVerificationEmail({
    required String toEmail,
    required String displayName,
    required String actionUrl,
  }) async {
    final String htmlContent = buildVerificationHtml(
      name: displayName,
      verificationLink: actionUrl,
    );

    final message = Message()
      ..from = const Address('noreply@openfood.fr', 'OpenFood')
      ..recipients.add(toEmail)
      ..subject = 'Bienvenue sur OpenFood - Confirmez votre adresse e-mail'
      ..text = 'Bonjour $displayName,\n\nBienvenue sur OpenFood ! Pour confirmer votre adresse e-mail, cliquez sur le lien suivant :\n$actionUrl\n\nL\'équipe OpenFood'
      ..html = htmlContent;

    await send(message, _smtpServer);
  }
}
