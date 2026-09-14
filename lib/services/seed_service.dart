import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:openfood_models/openfood_models.dart';

class SeedService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> seedDatabase() async {
    try {
      debugPrint("🚀 Début du seeding de la base de données...");

      // 1. Delete existing data
      final collectionsToClear = [
        'products',
        'restaurants',
        'inventory',
        'orders',
        'users'
      ];
      for (var collection in collectionsToClear) {
        final collectionRef = _db.collection(collection);
        final snapshots = await collectionRef.get();
        if (snapshots.docs.isNotEmpty) {
          WriteBatch deleteBatch = _db.batch();
          for (var doc in snapshots.docs) {
            deleteBatch.delete(doc.reference);
          }
          await deleteBatch.commit();
        }
        debugPrint(
            "🗑️ Collection '' vidée (${snapshots.docs.length} supprimés).");
      }

      WriteBatch batch = _db.batch();

      // 2. Insert Restaurants
      final resto1 = RestaurantModel(
        id: 'open_food',
        name: 'Open Food',
        lat: 14.6158,
        lng: -61.0963,
        zone: 'Nord Caraïbe',
        rating: 4.8,
        imageUrl:
            'https://images.unsplash.com/photo-1544025162-8315ea07f440?q=80&w=1000',
        type: 'Rapide',
        status: 'actif',
      );
      batch.set(_db.collection('restaurants').doc(resto1.id), resto1.toJson());

      // 3. Insert Inventory Items for Options
      final invFrites = InventoryItemModel(
        id: 'inv_frites',
        name: 'Frites de patate douce',
        stockCount: 50,
        isAvailable: true,
        restaurantId: resto1.id,
      );
      final invSalade = InventoryItemModel(
        id: 'inv_salade',
        name: 'Salade verte',
        stockCount: 20,
        isAvailable: true,
        restaurantId: resto1.id,
      );
      final invCoca = InventoryItemModel(
        id: 'inv_coca',
        name: 'Coca-Cola',
        stockCount: 0,
        isAvailable: false,
        restaurantId: resto1.id,
      );
      final invEau = InventoryItemModel(
        id: 'inv_eau',
        name: 'Eau minérale',
        stockCount: 100,
        isAvailable: true,
        restaurantId: resto1.id,
      );

      batch.set(
          _db.collection('inventory').doc(invFrites.id), invFrites.toJson());
      batch.set(
          _db.collection('inventory').doc(invSalade.id), invSalade.toJson());
      batch.set(_db.collection('inventory').doc(invCoca.id), invCoca.toJson());
      batch.set(_db.collection('inventory').doc(invEau.id), invEau.toJson());

      // 4. Insert Products
      final p1 = ProductModel(
        id: 'menu_burger',
        restaurantId: resto1.id,
        name: 'Menu Burger Poulet',
        description:
            'Un délicieux burger au poulet frit avec son accompagnement et sa boisson.',
        priceHT: 12.00,
        vatRate: 2.1,
        category: 'Plat',
        image:
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=800',
        badgeText: '🔥 Bestseller',
        isAvailable: true,
        modifierGroups: [
          ProductModifierGroup(
              id: 'side_choice',
              name: "Choix de l'accompagnement",
              minSelections: 1,
              maxSelections: 1,
              options: [
                ProductModifierOption(
                  id: 'opt_frites',
                  name: 'Frites de patate douce',
                  extraPrice: 0.0,
                  isAvailable: true,
                  linkedInventoryItemId: invFrites.id,
                ),
                ProductModifierOption(
                  id: 'opt_salade',
                  name: 'Salade verte',
                  extraPrice: 0.0,
                  isAvailable: true,
                  linkedInventoryItemId: invSalade.id,
                ),
              ]),
          ProductModifierGroup(
              id: 'drink_choice',
              name: 'Choix de la boisson',
              minSelections: 1,
              maxSelections: 1,
              options: [
                ProductModifierOption(
                  id: 'opt_coca',
                  name: 'Coca-Cola',
                  extraPrice: 0.0,
                  isAvailable: false,
                  linkedInventoryItemId: invCoca.id,
                ),
                ProductModifierOption(
                  id: 'opt_eau',
                  name: 'Eau minérale',
                  extraPrice: 0.0,
                  isAvailable: true,
                  linkedInventoryItemId: invEau.id,
                ),
              ]),
          ProductModifierGroup(
              id: 'extra_sauce',
              name: 'Sauces supplémentaires (+0.50€)',
              minSelections: 0,
              maxSelections: 3,
              options: [
                ProductModifierOption(
                    id: 'sauce_ketchup',
                    name: 'Ketchup',
                    extraPrice: 0.50,
                    isAvailable: true),
                ProductModifierOption(
                    id: 'sauce_mayo',
                    name: 'Mayonnaise',
                    extraPrice: 0.50,
                    isAvailable: true),
                ProductModifierOption(
                    id: 'sauce_piment',
                    name: 'Piment',
                    extraPrice: 0.50,
                    isAvailable: true),
              ])
        ],
      );

      final p2 = ProductModel(
        id: 'colombo_poulet',
        restaurantId: resto1.id,
        name: 'Colombo de Poulet',
        description:
            'Recette traditionnelle au lait de coco, épices douces et riz.',
        priceHT: 14.50,
        vatRate: 2.1,
        category: 'Plat',
        image:
            'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?q=80&w=800',
        badgeText: 'Authentique',
        isAvailable: true,
        modifierGroups: [],
      );

      batch.set(_db.collection('products').doc(p1.id), p1.toJson());
      batch.set(_db.collection('products').doc(p2.id), p2.toJson());

      await batch.commit();
      debugPrint(
          "✅ Base de données initialisée avec de faux restaurants, inventaires et menus !");
    } catch (e) {
      debugPrint("❌ Erreur lors du seeding : $e");
      throw Exception("Erreur Seeding: $e");
    }
  }
}
