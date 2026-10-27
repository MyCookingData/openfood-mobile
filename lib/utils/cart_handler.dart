import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'package:openfood_models/openfood_models.dart';
import '../core/theme.dart';
import 'ui_feedback.dart';
import 'restaurant_helper.dart';

class CartHandler {
  static void addItem(BuildContext context, CartItem item, {VoidCallback? onSuccess}) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    try {
      cart.addItem(item);
      UiFeedback.showSuccess(
        context,
        "${item.name} ajouté au panier !",
        duration: const Duration(seconds: 2),
      );
      if (onSuccess != null) onSuccess();
    } catch (e) {
      if (e.toString().contains("DIFF_RESTAURANT")) {
        _showConflictDialog(context, cart, item, onSuccess);
      } else {
        UiFeedback.showError(context, e.toString());
      }
    }
  }

  static Future<void> _showConflictDialog(
    BuildContext context, 
    CartProvider cart, 
    CartItem newItem, 
    VoidCallback? onSuccess
  ) async {
    final firstCartItem = cart.items.values.isNotEmpty ? cart.items.values.first : null;

    // 1. Résolution propre du nom du restaurant actuel (jamais d'ID brut)
    String currentResto = await RestaurantHelper.resolveRestaurantName(
      firstCartItem?.restaurantId,
      preferredName: cart.restaurantName.isNotEmpty ? cart.restaurantName : firstCartItem?.restaurantName,
      fallback: "votre restaurant actuel",
    );

    // 2. Résolution propre du nom du nouveau restaurant (jamais d'ID brut)
    String newResto = await RestaurantHelper.resolveRestaurantName(
      newItem.restaurantId,
      preferredName: newItem.restaurantName,
      fallback: "ce restaurant",
    );

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppTheme.surface2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.border2)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.storefront_rounded, color: AppTheme.gold, size: 28),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Changer de restaurant ?",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: AppTheme.cream, fontSize: 14, height: 1.5),
                    children: [
                      const TextSpan(text: "Vous tentez d'ajouter un plat de "),
                      TextSpan(
                        text: "'$newResto'",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.greenXl),
                      ),
                      const TextSpan(text: " alors que votre panier contient déjà un plat de "),
                      TextSpan(
                        text: "'$currentResto'",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.greenXl),
                      ),
                      const TextSpan(text: ".\n\nVotre panier ne peut contenir que les plats d'un seul restaurant à la fois."),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    cart.clearCart();
                    cart.addItem(newItem);
                    UiFeedback.showSuccess(
                      context,
                      "${newItem.name} ajouté au panier !",
                      duration: const Duration(seconds: 2),
                    );
                    if (onSuccess != null) onSuccess();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    elevation: 0,
                  ),
                  child: Text(
                    "Commander chez $newResto",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.border2, width: 1.5),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: const Text(
                    "Conserver mon panier actuel",
                    style: TextStyle(color: AppTheme.muted2, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
