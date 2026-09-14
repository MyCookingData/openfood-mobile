import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/cart_provider.dart';
import '../providers/location_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'auth/login_screen.dart';
import '../services/analytics_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final DateTime _enteredCartAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = Provider.of<LocationProvider>(context, listen: false);
      final cart = Provider.of<CartProvider>(context, listen: false);
      if (loc.selectedAddress != null) {
        cart.updateRealDistance(loc.selectedAddress!.latitude, loc.selectedAddress!.longitude);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final items = cart.items.values.toList();

    return Stack(
      alignment: Alignment.center,
      children: [
        Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Mon Panier",
          style: AppTheme.titleStyle.copyWith(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.cream),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () {
                // Demande de confirmation avant de vider le panier
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    title: const Text("Vider le panier ?", style: TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold)),
                    content: const Text("Êtes-vous sûr de vouloir supprimer tous les articles de votre panier ?", style: TextStyle(color: AppTheme.muted)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Annuler", style: TextStyle(color: AppTheme.muted2)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          cart.clearCart();
                        },
                        child: const Text("Vider", style: TextStyle(color: AppTheme.redL, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
              child: const Text("Vider", style: TextStyle(color: AppTheme.redL, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: items.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: AppTheme.surface3, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border2)),
                      child: Row(
                          children: [
                            const Text("📍 Commande chez", style: TextStyle(color: AppTheme.muted2, fontSize: 13, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(
                              (items.first.restaurantName ?? items.first.restaurantId)
                                  .split(' · ').first
                                  .replaceAll('_', ' ')
                                  .split(' ')
                                  .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
                                  .join(' '), 
                              style: const TextStyle(color: AppTheme.cream, fontSize: 14, fontWeight: FontWeight.bold)
                            ),
                          ],
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return _buildCartItemLine(context, cart, item);
                    },
                  ),
                ),
                _buildBottomSummary(context, cart),
              ],
            ),
        ),
      ],
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(color: AppTheme.surface2, shape: BoxShape.circle),
            child: const Center(child: Text("🛒", style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 24),
          Text("Votre panier est vide", style: AppTheme.titleStyle.copyWith(fontSize: 22)),
          const SizedBox(height: 10),
          const Text("Parcourez nos superbes restaurants pour y ajouter des plats appétissants.", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.muted, fontSize: 14)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.greenXl,
              foregroundColor: AppTheme.bg,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            child: const Text("Trouver à manger"),
          )
        ],
      ),
    );
  }

  Widget _buildCartItemLine(BuildContext context, CartProvider cart, dynamic item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Titre et Prix de l'article (TTC total pour cette ligne)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(color: AppTheme.cream, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (item.selectedOptions != null && item.selectedOptions!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.selectedOptions!.map((o) => "${o['name']}").join(", "),
                    style: const TextStyle(color: AppTheme.muted, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  "${item.priceHT.toStringAsFixed(2)} € HT l'unité (+ TVA ${item.vatRate}%)",
                  style: const TextStyle(color: AppTheme.muted2, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  "${item.subtotal.toStringAsFixed(2)} € TTC",
                  style: const TextStyle(color: AppTheme.greenXl, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          // Boutons + / -
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.border2),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: AppTheme.cream, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    cart.decrementQuantity(item.id);
                  },
                ),
                Text(
                  "${item.quantity}",
                  style: const TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: AppTheme.greenXl, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    try {
                      cart.incrementQuantity(item.id);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("⛔ Impossible d'ajouter plus de 20 articles pour une commande."),
                          backgroundColor: AppTheme.redL,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomSummary(BuildContext context, CartProvider cart) {
    // Calcul du sous-total TTC des articles avant frais de service
    double subTotal = 0;
    for (var item in cart.items.values) {
      subTotal += item.subtotal;
    }

    return Container(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 40),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, -10),
            blurRadius: 30,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Résumé de la commande", style: AppTheme.titleStyle.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          // Sous-total HT
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Sous-total (HT)", style: TextStyle(color: AppTheme.muted, fontSize: 13)),
              Text("${cart.subtotalHT.toStringAsFixed(2)} €", style: const TextStyle(color: AppTheme.cream, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          // TVA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TVA", style: TextStyle(color: AppTheme.muted, fontSize: 13)),
              Text("${cart.totalVat.toStringAsFixed(2)} €", style: const TextStyle(color: AppTheme.cream, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          // Sous-total TTC
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Sous-total (TTC)", style: TextStyle(color: AppTheme.muted, fontSize: 14)),
              Text("${subTotal.toStringAsFixed(2)} €", style: const TextStyle(color: AppTheme.cream, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          // Frais
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Frais (Livraison & Gestion)", style: TextStyle(color: AppTheme.muted, fontSize: 14)),
              Text(
                cart.deliveryFee < 0 
                  ? "Non disponible" 
                  : "${(cart.deliveryFee + cart.managementFee).toStringAsFixed(2)} €", 
                style: TextStyle(color: cart.deliveryFee < 0 ? AppTheme.red : AppTheme.cream, fontSize: 14, fontWeight: FontWeight.w600)
              ),
            ],
          ),
          if (cart.deliveryFee < 0) ...[
            const SizedBox(height: 8),
            const Text(
              "Désolé, vous êtes trop loin de ce restaurant (plus de 14km) pour être livré.", 
              style: TextStyle(color: AppTheme.red, fontSize: 13, fontWeight: FontWeight.bold)
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: AppTheme.surface3, thickness: 1),
          const SizedBox(height: 16),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Total à payer", style: TextStyle(color: AppTheme.cream, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                cart.deliveryFee < 0 ? "-- €" : "${cart.totalFinal.toStringAsFixed(2)} €",
                style: const TextStyle(color: AppTheme.greenXl, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Bricolage Grotesque'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // CTA
          ElevatedButton(
            onPressed: cart.deliveryFee < 0 ? null : () {
              HapticFeedback.lightImpact();
              if (cart.items.isNotEmpty) {
                if (FirebaseAuth.instance.currentUser == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Vous devez vous connecter ou créer un compte pour passer commande."),
                      backgroundColor: AppTheme.surface3,
                    ),
                  );
                } else {
                  AnalyticsService.logCheckoutFunnel(
                    "cart_reviewed", 
                    DateTime.now().difference(_enteredCartAt).inSeconds
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("⛔ Votre panier est vide."),
                    backgroundColor: AppTheme.redL,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: AppTheme.green.withValues(alpha: 0.5),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Passer au paiement", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          )
        ],
      ),
    );
  }
}
