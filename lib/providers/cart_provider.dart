import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:openfood_models/openfood_models.dart';
import '../services/analytics_service.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  PromoCodeModel? _activePromotion;

  double _distanceKm = 4.5; // Simulate distance
  bool _isClickAndCollect = false;
  double? _freeDeliveryThreshold;
  
  double get distanceKm => _distanceKm;

  void updateLocation(AddressModel? address) {
    if (address != null) {
      updateRealDistance(address.latitude, address.longitude);
    }
  }
  bool get isClickAndCollect => _isClickAndCollect;
  double? get freeDeliveryThreshold => _freeDeliveryThreshold;

  void setDistanceKm(double val) {
    _distanceKm = val;
    notifyListeners();
  }

  void setClickAndCollect(bool val) {
    _isClickAndCollect = val;
    notifyListeners();
  }

  /// Recalcule la distance réelle entre le client et le restaurant actuel du panier
  Future<void> updateRealDistance(double userLat, double userLng) async {
    if (_items.isEmpty) return;
    
    try {
      // Dans notre MVP, l'ID du restaurant est souvent son nom ou présent dans l'objet
      String restoId = _items.values.first.restaurantId;
      
      // On cherche d'abord par ID (le plus fiable)
      var doc = await FirebaseFirestore.instance.collection('restaurants').doc(restoId).get();
      Map<String, dynamic>? data;

      if (doc.exists) {
        data = doc.data();
      } else {
        // Sinon on cherche par nom
        final snapshot = await FirebaseFirestore.instance
            .collection('restaurants')
            .where('name', isEqualTo: restoId)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          data = snapshot.docs.first.data();
        }
      }

      if (data != null) {
        if (data.containsKey('lat') && data.containsKey('lng')) {
          double restoLat = (data['lat'] as num).toDouble();
          double restoLng = (data['lng'] as num).toDouble();
          
          const distance = Distance();
          final double km = distance.as(
            LengthUnit.Kilometer,
            LatLng(userLat, userLng),
            LatLng(restoLat, restoLng)
          );
          
          if (data.containsKey('freeDeliveryThreshold') && data['freeDeliveryThreshold'] != null) {
            _freeDeliveryThreshold = (data['freeDeliveryThreshold'] as num).toDouble();
          } else {
            _freeDeliveryThreshold = null;
          }
          
          setDistanceKm(km);
        }
      }
    } catch (e) {
      debugPrint("Erreur lors du calcul GPS Restaurant: $e");
    }
  }

  double get deliveryFee {
    if (_isClickAndCollect) return 0.0;
    if (_freeDeliveryThreshold != null && subtotalAmount >= _freeDeliveryThreshold!) return 0.0;
    if (_distanceKm > 14.0) return -1.0; // Indique UI error
    
    if (_distanceKm <= 2.0) return 2.50;
    
    double fee = 2.50;
    double remaining = _distanceKm - 2.0;

    // 2km à 5km (+0.80€/km)
    if (remaining > 0) {
      double tier = remaining > 3.0 ? 3.0 : remaining;
      fee += tier * 0.80;
      remaining -= tier;
    }

    // 5km à 10km (+0.70€/km)
    if (remaining > 0) {
      double tier = remaining > 5.0 ? 5.0 : remaining;
      fee += tier * 0.70;
      remaining -= tier;
    }

    // 10km à 14km (+0.60€/km)
    if (remaining > 0) {
      fee += remaining * 0.60;
    }

    return double.parse(fee.toStringAsFixed(2));
  }

  /// Frais de gestion/service : 5% du sous-total
  double get managementFee {
    return double.parse((subtotalAmount * 0.05).toStringAsFixed(2));
  }

  CartProvider() {
    _loadCartFromPrefs();
  }

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  int get totalQuantity {
    var total = 0;
    _items.forEach((key, item) {
      total += item.quantity;
    });
    return total;
  }

  /// Somme brute des articles TTC
  double get subtotalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.subtotal;
    });
    return double.parse(total.toStringAsFixed(2));
  }

  /// Somme brute des articles HT
  double get subtotalHT {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.subtotalHT;
    });
    return double.parse(total.toStringAsFixed(2));
  }

  /// Montant total de la TVA de tous les articles
  double get totalVat {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.totalVatAmount;
    });
    return double.parse(total.toStringAsFixed(2));
  }

  /// Total après remise, livraison et gestion
  double get totalFinal {
    if (_items.isEmpty) return 0.0;
    
    double discountedSubtotal = subtotalAmount - calculateDiscount();
    if (discountedSubtotal < 0) discountedSubtotal = 0; // Sécurité

    double finalAmt = discountedSubtotal + (deliveryFee > 0 ? deliveryFee : 0) + managementFee;
    return double.parse(finalAmt.toStringAsFixed(2));
  }

  /// Applique explicitement un code promo
  void applyPromotion(PromoCodeModel? promo) {
    _activePromotion = promo;
    notifyListeners();
  }

  PromoCodeModel? get activePromotion => _activePromotion;

  /// Calcule le montant total de la remise en fonction des règles
  double calculateDiscount() {
    if (_activePromotion == null) return 0.0;

    double discount = 0.0;

    // Vérification du seuil en euros (sous-total des produits)
    if (_activePromotion!.minAmount != null && subtotalAmount < _activePromotion!.minAmount!) {
      return 0.0; // Seuil non atteint
    }

    // Vérification de la quantité d'articles minimum
    if (_activePromotion!.minQuantity != null && totalQuantity < _activePromotion!.minQuantity!) {
      return 0.0; // Volume non atteint
    }

    // Calcul de la base sur laquelle s'applique la réduction
    double discountBase = 0.0;

    List<CartItem> applicableItems = _items.values.toList();
    // Filtre par restaurant est géré en amont lors de la validation du code promo.

    // Filtre par produits applicables
    if (_activePromotion!.applicableProductIds != null && _activePromotion!.applicableProductIds!.isNotEmpty) {
      applicableItems = applicableItems.where((item) => 
        _activePromotion!.applicableProductIds!.contains(item.id.split('_').first) // item.id may have option signatures
      ).toList();

      if (applicableItems.isEmpty) return 0.0; // Aucun produit applicable dans le panier
    }

    switch (_activePromotion!.discountTarget) {
      case PromoTarget.cart_subtotal:
        discountBase = subtotalAmount;
        break;
      case PromoTarget.selected_products:
        discountBase = applicableItems.fold(0.0, (acc, item) => acc + (item.priceHT * (1 + item.vatRate / 100)) * item.quantity);
        break;
      case PromoTarget.most_expensive:
        if (applicableItems.isNotEmpty) {
          applicableItems.sort((a, b) => (b.priceHT * (1 + b.vatRate / 100)).compareTo((a.priceHT * (1 + a.vatRate / 100))));
          discountBase = applicableItems.first.priceHT * (1 + applicableItems.first.vatRate / 100);
        }
        break;
      case PromoTarget.least_expensive:
        if (applicableItems.isNotEmpty) {
          applicableItems.sort((a, b) => (a.priceHT * (1 + a.vatRate / 100)).compareTo((b.priceHT * (1 + b.vatRate / 100))));
          discountBase = applicableItems.first.priceHT * (1 + applicableItems.first.vatRate / 100);
        }
        break;
      case PromoTarget.delivery_fee:
        discountBase = deliveryFee;
        break;
    }

    // Calcul de la réduction finale
    if (_activePromotion!.type == PromotionType.fixed) {
      discount = _activePromotion!.value;
      if (discount > discountBase) discount = discountBase; // Ne peut pas dépasser la base de réduction
    } else if (_activePromotion!.type == PromotionType.percentage) {
      discount = discountBase * (_activePromotion!.value / 100);
    }

    return double.parse(discount.toStringAsFixed(2));
  }

  /// Ajout d'un produit (bloque si restaurantId diffère)
  void addItem(CartItem newItem) {
    if (_items.isNotEmpty) {
      final currentRestoId = _items.values.first.restaurantId.split(' Â· ').first;
      final newRestoId = newItem.restaurantId.split(' Â· ').first;
      if (currentRestoId != newRestoId) {
        throw Exception("DIFF_RESTAURANT"); // Rattrapé par l'UI pour proposer de vider
      }
    }

    if (_items.containsKey(newItem.id)) {
      _items.update(
        newItem.id,
        (existingItem) {
          existingItem.quantity += newItem.quantity;
          return existingItem;
        },
      );
    } else {
      _items.putIfAbsent(newItem.id, () => newItem);
    }
    
    AnalyticsService.logCartAction("added", newItem.name, newItem.priceHT);

    _saveCartToPrefs();
    notifyListeners();
  }

  /// Incrémenter manuellement
  void incrementQuantity(String productId) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingItem) {
          existingItem.quantity += 1;
          return existingItem;
        },
      );
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  /// Décrémenter manuellement
  void decrementQuantity(String productId) {
    if (!_items.containsKey(productId)) return;

    if (!_items.containsKey(productId)) return; // Safety logic
    
    final itemName = _items[productId]!.name;
    final itemPrice = _items[productId]!.priceHT;
    
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingItem) {
          existingItem.quantity -= 1;
          return existingItem;
        },
      );
      AnalyticsService.logCartAction("decreased", itemName, itemPrice);
    } else {
      _items.remove(productId);
      AnalyticsService.logCartAction("removed", itemName, itemPrice);
    }
    
    // Si on vide le panier, on enlève aussi la promo active
    if (_items.isEmpty) {
      _activePromotion = null;
    }

    _saveCartToPrefs();
    notifyListeners();
  }

  /// Vider le panier
  void clearCart() {
    _items.clear();
    _activePromotion = null;
    _saveCartToPrefs();
    notifyListeners();
  }

  /// Persistance: Chargement
  Future<void> _loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartDataStr = prefs.getString('cart_data');
    if (cartDataStr != null) {
      try {
        final decodedData = json.decode(cartDataStr) as Map<String, dynamic>;
        _items = decodedData.map((key, value) => MapEntry(key, CartItem.fromJson(value)));
        notifyListeners();
      } catch (e) {
        // Fallback en cas de changement de structure
        _items = {};
      }
    }
  }

  /// Persistance: Sauvegarde
  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedData = json.encode(
      _items.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString('cart_data', encodedData);
  }
}
