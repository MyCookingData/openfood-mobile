import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupère la liste des restaurants en temps réel
  Stream<List<Map<String, dynamic>>> getRestaurants() {
    return _firestore.collection('restaurants').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).where((data) => data['status'] != 'caché').toList();
    });
  }

  /// Récupère le menu d'un restaurant spécifique en temps réel
  Stream<List<Map<String, dynamic>>> getMenu(String restaurantId) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ajout de l'ID du document
        return data;
      }).toList();
    });
  }

  // --- IA & MIGRATION ---

  static List<String> _deriveTags(String text) {
    final lower = text.toLowerCase();
    final tags = <String>[];
    if (lower.contains('viande') ||
        lower.contains('boeuf') ||
        lower.contains('poulet') ||
        lower.contains('porc')) {
      tags.add('Viande');
    }
    if (lower.contains('poisson') ||
        lower.contains('morue') ||
        lower.contains('saumon') ||
        lower.contains('crevette')) {
      tags.add('Poisson');
    }
    if (lower.contains('épicé') ||
        lower.contains('piment') ||
        lower.contains('colombo') ||
        lower.contains('curry')) {
      tags.add('Épicé');
    }
    if (lower.contains('léger') ||
        lower.contains('salade') ||
        lower.contains('bowl') ||
        lower.contains('fruit')) {
      tags.add('Léger');
    }
    if (lower.contains('pâte') ||
        lower.contains('pasta') ||
        lower.contains('spaghetti') ||
        lower.contains('penne')) {
      tags.add('Pâtes');
    }
    if (lower.contains('burger') ||
        lower.contains('frite') ||
        lower.contains('snack')) {
      tags.add('Burger');
    }
    if (lower.contains('végétarien') ||
        lower.contains('légume') ||
        lower.contains('vegan')) {
      tags.add('Végétarien');
    }
    tags.add('Rapide'); // Toujours ajouté par défaut
    return tags.toSet().toList();
  }

  static Future<void> runTagMigration() async {
    final firestore = FirebaseFirestore.instance;
    final products = await firestore.collection('products').get();

    for (var mDoc in products.docs) {
      final data = mDoc.data();
      final name = data['name']?.toString() ?? '';
      final desc = data['description']?.toString() ?? '';
      final currentTags = data['tags'];
      final cat = data['category']?.toString() ?? '';

      final tags = currentTags != null
          ? List<String>.from(currentTags)
          : _deriveTags('$name $desc');

      List<Map<String, dynamic>> tree = [];

      if (cat.contains('Plat')) {
        if (tags.contains('Viande') || tags.contains('Burger')) {
          tree.add({
            "title": "Choix de Cuisson",
            "required": true,
            "max": 1,
            "choices": [
              {"name": "Saignant", "priceHT": 0.0},
              {"name": "À point", "priceHT": 0.0},
              {"name": "Bien cuit", "priceHT": 0.0}
            ]
          });
        }

        tree.add({
          "title": "Choix de l'Accompagnement",
          "required": true,
          "max": 1,
          "choices": [
            {"name": "Riz madras", "priceHT": 0.0},
            {"name": "Frites de patate douce", "priceHT": 1.5},
            {"name": "Salade verte tropicale", "priceHT": 0.0},
            {"name": "Légumes pays", "priceHT": 2.0}
          ]
        });
      } else if (cat.contains('Entrée')) {
        tree.add({
          "title": "Sauce d'accompagnement",
          "required": false,
          "max": 1,
          "choices": [
            {"name": "Sauce chien maison", "priceHT": 0.5},
            {"name": "Sauce aigre-douce", "priceHT": 0.5},
            {"name": "Sauce piquante extra", "priceHT": 0.3}
          ]
        });
      } else if (cat.contains('Boisson')) {
        tree.add({
          "title": "Format",
          "required": true,
          "max": 1,
          "choices": [
            {"name": "Standard (33 cl)", "priceHT": 0.0},
            {"name": "Grand format (50 cl)", "priceHT": 1.5}
          ]
        });
        tree.add({
          "title": "Préférence",
          "required": false,
          "max": 2,
          "choices": [
            {"name": "Très frais (Glaçons)", "priceHT": 0.0},
            {"name": "Tranche de citron vert", "priceHT": 0.0}
          ]
        });
      } else if (cat.contains('Dessert')) {
        tree.add({
          "title": "Gourmandise",
          "required": false,
          "max": 2,
          "choices": [
            {"name": "Boule de glace Vanille-Pécan", "priceHT": 2.5},
            {"name": "Nappage Chocolat chaud", "priceHT": 1.0},
            {"name": "Chantilly maison", "priceHT": 0.8}
          ]
        });
      }

      // Suppléments génériques sur Plats et Entrées
      if (cat.contains('Plat') || cat.contains('Entrée')) {
        tree.add({
          "title": "Extras",
          "required": false,
          "max": 3,
          "choices": [
            {"name": "Couverts jetables", "priceHT": 0.0},
            {"name": "Extra Pickles", "priceHT": 0.5},
          ]
        });
      }

      // Toujours écraser pendant cette phase de débuggage
      await mDoc.reference.update({'tags': tags, 'optionsTree': tree});
    }
  }

  static Future<Map<String, dynamic>?> getRandomDish(
      List<String> activeTags) async {
    final firestore = FirebaseFirestore.instance;
    final tagsToSearch =
        activeTags.isEmpty ? ['Rapide'] : activeTags.take(10).toList();

    List<QueryDocumentSnapshot<Map<String, dynamic>>> validDocs = [];

    try {
      var menus = await firestore
          .collection('products')
          .where('tags', arrayContainsAny: tagsToSearch)
          .get();
      validDocs = menus.docs;
    } catch (e) {
      var allMenus = await firestore.collection('products').get();
      validDocs = allMenus.docs.where((doc) {
        final dTags = List<String>.from(doc.data()['tags'] ?? []);
        return dTags.any((t) => tagsToSearch.contains(t));
      }).toList();
    }

    if (validDocs.isEmpty) {
      var allMenus = await firestore.collection('products').get();
      validDocs = allMenus.docs;
      if (validDocs.isEmpty) return null;
    }

    final docs = validDocs.toList()..shuffle();
    final selectedDoc = docs.first;

    // Le restaurantId est maintenant directement dans le doc "products" et n'est plus un ID de collection parent (voir screenshot BDD)
    String restaurantName =
        selectedDoc.data()['restaurantId'] ?? "Restaurant Inconnu";

    final data = selectedDoc.data();
    data['id'] = selectedDoc.id;
    data['restaurantId'] = restaurantName;

    // Icône dynamique
    String ico = '🍲';
    if (data['tags'] != null) {
      final t = List<String>.from(data['tags']);
      if (t.contains('Viande')) ico = '🥩';
      if (t.contains('Poisson')) ico = '🐟';
      if (t.contains('Burger')) ico = '🍔';
      if (t.contains('Pâtes')) ico = '🍝';
      if (t.contains('Léger')) ico = '🥗';
    }
    data['ico'] = ico;

    return data;
  }
}
