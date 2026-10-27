import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';

class AppVersionService {
  static const String currentVersion = "1.0.0";
  static const int currentBuildNumber = 1;

  /// Vérifie si une mise à jour obligatoire est requise et affiche le dialogue bloquant si nécessaire
  static Future<void> checkVersion(BuildContext context) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('app_config').get();
      
      // Si le document n'existe pas encore, on le crée avec les valeurs par défaut
      if (!doc.exists) {
        await FirebaseFirestore.instance.collection('settings').doc('app_config').set({
          'min_required_version': '1.0.0',
          'min_required_build': 1,
          'latest_version': '1.0.0',
          'force_update_enabled': false,
          'update_title': 'Mise à jour requise',
          'update_message': 'Une nouvelle version d\'OpenFood est disponible. Veuillez mettre à jour votre application pour continuer à commander en toute sécurité.',
          'play_store_url': 'https://play.google.com/store/apps/details?id=openfood.app',
          'app_store_url': 'https://apps.apple.com/app/openfood/id6737152431',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }

      final data = doc.data() ?? {};
      final minVersion = (data['min_required_version'] as String?) ?? '1.0.0';
      final minBuild = (data['min_required_build'] as int?) ?? 1;
      final forceUpdateEnabled = (data['force_update_enabled'] as bool?) ?? false;

      final bool isVersionOutdated = _isVersionLower(currentVersion, minVersion);
      final bool isBuildOutdated = currentBuildNumber < minBuild;

      if ((forceUpdateEnabled && (isVersionOutdated || isBuildOutdated)) || isVersionOutdated) {
        if (!context.mounted) return;
        _showForceUpdateDialog(
          context,
          title: data['update_title'] as String? ?? 'Mise à jour requise',
          message: data['update_message'] as String? ??
              'Une nouvelle version d\'OpenFood est disponible sur le store. Veuillez mettre à jour votre application pour continuer.',
          playStoreUrl: data['play_store_url'] as String? ?? 'https://play.google.com/store/apps/details?id=openfood.app',
          appStoreUrl: data['app_store_url'] as String? ?? 'https://apps.apple.com/app/openfood/id6737152431',
        );
      }
    } catch (e) {
      debugPrint("Info: Vérification de version passée ($e)");
    }
  }

  /// Compare deux chaînes sémantiques (ex: "1.0.0" et "1.0.1")
  static bool _isVersionLower(String current, String required) {
    try {
      final curParts = current.split('.').map(int.parse).toList();
      final reqParts = required.split('.').map(int.parse).toList();

      for (int i = 0; i < reqParts.length; i++) {
        final cur = i < curParts.length ? curParts[i] : 0;
        final req = reqParts[i];
        if (cur < req) return true;
        if (cur > req) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Affiche la modale bloquante de mise à jour (non-fermable)
  static void _showForceUpdateDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String playStoreUrl,
    required String appStoreUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // Bloque la fermeture en touchant l'arrière-plan
      builder: (ctx) => PopScope(
        canPop: false, // Empêche le retour arrière Android
        child: AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppTheme.greenXl.withValues(alpha: 0.4), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Icône
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.greenXl.withValues(alpha: 0.15),
                  border: Border.all(color: AppTheme.greenXl.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: AppTheme.greenXl, size: 36),
              ),
              const SizedBox(height: 20),

              // Titre
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.cream,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                "Version actuelle : v$currentVersion",
                style: TextStyle(
                  color: AppTheme.muted2,
                  fontSize: 11.5,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 24),

              // Bouton d'action vers le store
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.greenXl,
                    foregroundColor: Colors.black,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 20, color: Colors.black),
                  label: Text(
                    defaultTargetPlatform == TargetPlatform.iOS ? "Mettre à jour sur l'App Store" : "Mettre à jour sur Google Play",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () async {
                    final targetUrl = defaultTargetPlatform == TargetPlatform.iOS ? appStoreUrl : playStoreUrl;
                    final uri = Uri.parse(targetUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
