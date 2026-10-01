import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'package:openfood_models/openfood_models.dart';
import '../core/theme.dart';
import 'ui_feedback.dart';

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

  static void _showConflictDialog(BuildContext context, CartProvider cart, CartItem newItem, VoidCallback? onSuccess) {
    final currentResto = cart.items.values.first.restaurantId.split(' · ').first;
    final newResto = newItem.restaurantId.split(' · ').first;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppTheme.surface2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.border2)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Attention",
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: AppTheme.cream, fontSize: 14, height: 1.5),
                    children: [
                      const TextSpan(text: "Vous tentez d'ajouter un plat de "),
                      TextSpan(text: "'$newResto'", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: " alors que votre panier contient déjà un plat de "),
                      TextSpan(text: "'$currentResto'", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: "."),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                OutlinedButton(
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
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.green, width: 2),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text("Continuer avec $newResto", style: const TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.green, width: 2),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: const Text("Conserver mon panier actuel", style: TextStyle(color: AppTheme.greenXl, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
