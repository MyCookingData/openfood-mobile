import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:openfood_models/openfood_models.dart';

/// Utilitaire global pour garantir qu'aucun identifiant technique brut
/// (ex: NRApFNzTuiywlssVQrqs, hash Firestore, UUID) n'apparaisse aux yeux du client.
class RestaurantHelper {
  static final Map<String, String> _cache = {
    'escale_gourmande_lamentin': "L'Escale Gourmande",
    'open_food_fort_de_france': "Open Food Fort-de-France",
    'nrapfnztuiywlssvqrqs': "QG StreetFood",
    'iaxtt4qjfjdxqw7k3sb': "Rémy Pizza",
    'iaxctt4qjfjdxqw7k3sb': "Rémy Pizza",
    'jzonpofrkrwnihkym5o3': "OFYL Grill",
  };

  /// Enregistre une correspondance ID -> Nom lisible
  static void registerRestaurant(String? id, String? name) {
    if (id == null || name == null) return;
    final cleanId = id.split(' · ').first.trim();
    final cleanName = name.split(' · ').first.trim();
    if (cleanId.isNotEmpty && cleanName.isNotEmpty && !isRawId(cleanName)) {
      _cache[cleanId] = cleanName;
      _cache[cleanId.toLowerCase()] = cleanName;
    }
  }

  /// Détecte si une chaîne est un identifiant technique brut plutôt qu'un alias/nom lisible
  static bool isRawId(String? text) {
    if (text == null || text.trim().isEmpty) return true;
    final clean = text.split(' · ').first.trim();
    
    // Hash Firestore auto-généré (16 à 32 caractères alphanumériques sans espace)
    if (RegExp(r'^[a-zA-Z0-9]{16,32}$').hasMatch(clean)) return true;
    
    // UUID / GUID / Mongo ObjectId
    if (RegExp(r'^[a-fA-F0-9-]{24,36}$').hasMatch(clean)) return true;

    // Chaîne sans espace de plus de 15 caractères mêlant majuscules, minuscules et chiffres
    if (!clean.contains(' ') && clean.length > 15 && RegExp(r'[0-9]').hasMatch(clean) && RegExp(r'[A-Z]').hasMatch(clean) && RegExp(r'[a-z]').hasMatch(clean)) {
      return true;
    }

    return false;
  }

  /// Nettoie un nom ou retourne un alias propre sans JAMAIS renvoyer d'ID technique
  static String cleanRestaurantName(String? nameOrId, {String fallback = "Restaurant Partenaire"}) {
    if (nameOrId == null || nameOrId.trim().isEmpty) return fallback;
    final clean = nameOrId.split(' · ').first.trim();

    // 1. Vérification dans le cache mémoire
    if (_cache.containsKey(clean)) return _cache[clean]!;
    if (_cache.containsKey(clean.toLowerCase())) return _cache[clean.toLowerCase()]!;

    // 2. Si c'est un identifiant brut non répertorié
    if (isRawId(clean)) {
      return fallback;
    }

    // 3. Si c'est un slug (ex: "escale_gourmande")
    if (clean.contains('_')) {
      final words = clean.replaceAll('_', ' ').split(' ');
      return words
          .where((w) => w.isNotEmpty)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
          .join(' ');
    }

    return clean;
  }

  /// Résout de manière asynchrone le nom lisible depuis Firestore si nécessaire
  static Future<String> resolveRestaurantName(
    String? nameOrId, {
    String? preferredName,
    String fallback = "Restaurant Partenaire",
  }) async {
    // Si un nom préféré lisible est fourni, on le prend directement
    if (preferredName != null && preferredName.trim().isNotEmpty && !isRawId(preferredName)) {
      registerRestaurant(nameOrId, preferredName);
      return cleanRestaurantName(preferredName, fallback: fallback);
    }

    if (nameOrId == null || nameOrId.trim().isEmpty) return fallback;
    final clean = nameOrId.split(' · ').first.trim();

    if (_cache.containsKey(clean)) return _cache[clean]!;
    if (_cache.containsKey(clean.toLowerCase())) return _cache[clean.toLowerCase()]!;

    if (!isRawId(clean)) {
      return cleanRestaurantName(clean, fallback: fallback);
    }

    // Recherche Firestore par document ID
    try {
      final doc = await FirebaseFirestore.instance.collection('restaurants').doc(clean).get();
      if (doc.exists && doc.data() != null) {
        final name = doc.data()!['name']?.toString().trim();
        if (name != null && name.isNotEmpty && !isRawId(name)) {
          registerRestaurant(clean, name);
          return name;
        }
      }

      // Recherche Firestore par champ si le docId n'était pas la clé primaire
      final snap = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('restaurantId', isEqualTo: clean)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final name = snap.docs.first.data()['name']?.toString().trim();
        if (name != null && name.isNotEmpty && !isRawId(name)) {
          registerRestaurant(clean, name);
          return name;
        }
      }
    } catch (_) {}

    return fallback;
  }

  /// Récupère en direct le statut d'ouverture actuel du restaurant depuis Firestore.
  static Future<RestaurantOpenStatus> fetchRestaurantOpenStatus(String? restaurantIdOrName) async {
    const openFallback = RestaurantOpenStatus(
      isOpen: true,
      shortStatus: 'Ouvert',
      detailStatus: 'Ouvert',
    );
    if (restaurantIdOrName == null || restaurantIdOrName.trim().isEmpty) {
      return openFallback;
    }

    final clean = restaurantIdOrName.split(' · ').first.trim();
    if (clean.isEmpty) return openFallback;

    try {
      Map<String, dynamic>? data;
      final doc = await FirebaseFirestore.instance.collection('restaurants').doc(clean).get();
      if (doc.exists && doc.data() != null) {
        data = doc.data()!;
      } else {
        final snap = await FirebaseFirestore.instance
            .collection('restaurants')
            .where('name', isEqualTo: clean)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          data = snap.docs.first.data();
        }
      }

      if (data == null) return openFallback;

      Map<String, dynamic>? openingHours;
      if (data['openingHours'] is Map) {
        openingHours = Map<String, dynamic>.from(data['openingHours'] as Map);
      }
      final manualStatus = data['status']?.toString();
      return OpeningHoursHelper.getStatus(openingHours, manualStatus: manualStatus);
    } catch (e) {
      debugPrint('Erreur vérification horaires restaurant ($clean): $e');
      return openFallback;
    }
  }

  /// Formate un message utilisateur clair lorsqu'un restaurant est fermé.
  static String closedOrderMessage(String restaurantName, RestaurantOpenStatus status) {
    final trimmed = restaurantName.trim();
    final label = trimmed.isNotEmpty ? trimmed : 'Ce restaurant';
    final nextText = status.nextChangeText.trim();
    final suffix = nextText.isNotEmpty ? ' ($nextText)' : '';
    return "$label est actuellement fermé$suffix. Impossible de commander pour le moment.";
  }
}
