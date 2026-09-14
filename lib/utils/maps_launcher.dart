import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsLauncher {
  /// Ouvre l'application GPS native ou le navigateur vers les coordonnées spécifiées
  static Future<void> openMaps({required double lat, required double lng}) async {
    // Schéma universel Cross-Platform
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final Uri googleMapsUri = Uri.parse(googleMapsUrl);

    try {
      if (kIsWeb) {
        // En mode web, on force l'ouverture d'un nouvel onglet via le constructeur universel
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Sur mobile natif, url_launcher détectera si l'app Google Maps est présente
        // sinon il ouvrira Map/Safari/Chrome.
        if (await canLaunchUrl(googleMapsUri)) {
          await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        } else {
          debugPrint("❌ Impossible d'ouvrir Google Maps.");
        }
      }
    } catch (e) {
      debugPrint("❌ Erreur au lancement du GPS: $e");
    }
  }
}
