import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/stripe_service.dart';
import '../../services/stripe_backend_service.dart';
import '../../services/stripe_backend_service.dart';
import '../../services/order_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'order_success_screen.dart';
import '../services/analytics_service.dart';
import '../services/promo_service.dart';
import 'address_picker_screen.dart';
import 'profile_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _saveCard = false;
  bool _isProcessing = false;
  final DateTime _enteredAt = DateTime.now();


  Future<void> _applyPromo(CartProvider cart) async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      cart.applyPromotion(null);
      return;
    }

    try {
      String? cartRestoId;
      if (cart.items.isNotEmpty) {
        cartRestoId = cart.items.values.first.restaurantId;
      }
      final promo = await PromoService().validateAndGetPromo(code, cartRestaurantId: cartRestoId);
      if (!mounted) return;
      if (promo != null) {
        cart.applyPromotion(promo);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(promo.successMessage?.isNotEmpty == true ? promo.successMessage! : 'Promo "${promo.code}" appliquée !'), 
            backgroundColor: AppTheme.greenXl,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      cart.applyPromotion(null); // clear
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.red),
      );
    }
  }

  Future<void> _processPayment(CartProvider cart) async {
    HapticFeedback.lightImpact();
    if (cart.items.isEmpty) return;

    final loc = Provider.of<LocationProvider>(context, listen: false);
    
    if (!cart.isClickAndCollect) {
      if (loc.addresses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("🚨 Ajoutez une adresse de livraison avant de commander.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppTheme.redL,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "Y ALLER",
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressPickerScreen()));
            },
          ),
        ));
        return;
      }
      
      if (cart.distanceKm > 14.0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("🚨 Vous êtes à plus de 14km de ce restaurant. Livraison impossible.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppTheme.redL,
          duration: Duration(seconds: 4),
        ));
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final phoneNumber = prefs.getString('phoneNumber') ?? '';
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text("📲 Renseignez un numéro de téléphone pour le livreur.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppTheme.redL,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: "MON PROFIL",
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          },
        ),
      ));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // --- BYPASS POUR WINDOWS ET WEB ---
      // Stripe natif crashe sur environnement non-mobile
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
        await Future.delayed(const Duration(seconds: 2)); // Simulation délai bancaire
        if (!mounted) return;
        await OrderService.createOrder(
          cart,
          customerPhone: prefs.getString('phoneNumber'),
          deliveryAddress: cart.isClickAndCollect ? "À emporter" : loc.selectedAddress?.addressName,
          customerLat: cart.isClickAndCollect ? null : loc.selectedAddress?.latitude,
          customerLng: cart.isClickAndCollect ? null : loc.selectedAddress?.longitude,
          stripePaymentIntentId: "pi_mock_123456", // Mock pour tester l'admin
          promoCodeId: cart.activePromotion?.id,
          discountAmount: cart.calculateDiscount(),
        );
        cart.clearCart();
        AnalyticsService.logCheckoutFunnel(
          "checkout_completed", 
          DateTime.now().difference(_enteredAt).inSeconds,
          extraData: {"stripe_used": false}
        );
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrderSuccessScreen()));
        return;
      }
      // ----------------------------------

      // Appel API Cloud Function pour créer le PaymentIntent (mode Empreinte)
      final restaurantIdRaw = cart.items.values.first.restaurantId;
      bool success = false;
      String? paymentIntentId;
      
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('createOrderPaymentIntent');
        final result = await callable.call({
          'restaurantId': restaurantIdRaw,
          'amount': cart.totalFinal,
        });
        
        final intentData = result.data;
        
        if (intentData == null || intentData['clientSecret'] == null) {
          throw Exception("Impossible de créer la transaction sécurisée.");
        }
        
        paymentIntentId = intentData['paymentIntentId'];

        // Initialisation du PaymentSheet native iOS/Android
        await StripeService.instance.initPaymentSheet(
          paymentIntentClientSecret: intentData['clientSecret'],
          customerId: null,
          setupIntentClientSecret: null,
        );

        // Affichage de la modale de paiement native !
        success = await StripeService.instance.presentPaymentSheet();
      } catch (e) {
        // En mode MVP / Test, si la fonction n'est pas déployée, on simule un succès
        if (e.toString().contains('NOT_FOUND') || e.toString().contains('not-found')) {
          debugPrint("⚠️ Cloud Function non trouvée, simulation du paiement (Mode Test)");
          await Future.delayed(const Duration(seconds: 1)); // Simuler la modale
          success = true;
          paymentIntentId = "pi_test_simulated_${DateTime.now().millisecondsSinceEpoch}";
        } else {
          rethrow;
        }
      }

      if (success) {
        // L'utilisateur approuve le paiement sur mobile
        if (!mounted) return;
        // 1. Enregistrer la vraie commande dans Firebase
        await OrderService.createOrder(
          cart,
          customerPhone: prefs.getString('phoneNumber'),
          deliveryAddress: cart.isClickAndCollect ? "À emporter" : loc.selectedAddress?.addressName,
          customerLat: cart.isClickAndCollect ? null : loc.selectedAddress?.latitude,
          customerLng: cart.isClickAndCollect ? null : loc.selectedAddress?.longitude,
          stripePaymentIntentId: paymentIntentId,
          promoCodeId: cart.activePromotion?.id,
          discountAmount: cart.calculateDiscount(),
        );
        
        // 2. Vider le panier
        cart.clearCart();
        
        AnalyticsService.logCheckoutFunnel(
          "checkout_completed", 
          DateTime.now().difference(_enteredAt).inSeconds,
          extraData: {"stripe_used": true}
        );
        
        if (!mounted) return;
        // 3. Navigation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

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

    return Stack(
      alignment: Alignment.center,
      children: [
        Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text("Paiement", style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w800)),
        backgroundColor: AppTheme.bg,
        elevation: 0,
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text("Votre panier est vide", style: TextStyle(color: AppTheme.muted)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sélecteur de méthode de réception
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => cart.setClickAndCollect(false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !cart.isClickAndCollect ? AppTheme.green : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text("🛵 Livraison", style: TextStyle(color: !cart.isClickAndCollect ? Colors.white : AppTheme.muted, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => cart.setClickAndCollect(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: cart.isClickAndCollect ? AppTheme.green : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text("🛍️ À emporter", style: TextStyle(color: cart.isClickAndCollect ? Colors.white : AppTheme.muted, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Récapitulatif de commande", style: TextStyle(color: AppTheme.cream, fontSize: 16, fontWeight: FontWeight.bold)),
                      if (cart.items.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.surface3, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppTheme.border2)),
                          child: Text("📍 ${cart.items.values.first.restaurantId.split(' · ').first}", style: const TextStyle(color: AppTheme.muted2, fontSize: 12, fontWeight: FontWeight.w600)),
                        )
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cart.items.length,
                    separatorBuilder: (context, index) => Divider(color: AppTheme.border),
                    itemBuilder: (context, index) {
                      final item = cart.items.values.elementAt(index);
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.cream, fontSize: 14)),
                                Text("${item.price.toStringAsFixed(2).replaceAll('.', ',')} € / unité", style: const TextStyle(color: AppTheme.muted2, fontSize: 12)),
                              ],
                            ),
                          ),
                          // Modification Quantité
                          Container(
                            decoration: BoxDecoration(color: AppTheme.surface3, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16, color: AppTheme.cream),
                                  onPressed: () => cart.decrementQuantity(item.id),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Text('${item.quantity}', style: const TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16, color: AppTheme.cream),
                                  onPressed: () => cart.incrementQuantity(item.id),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // 2. Zone Promo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promoController,
                            enabled: cart.activePromotion == null,
                            style: const TextStyle(color: AppTheme.cream),
                            decoration: InputDecoration(
                              hintText: "Code promo (ex: OPEN10)",
                              hintStyle: const TextStyle(color: AppTheme.muted2, fontSize: 13),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: AppTheme.surface3,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (cart.activePromotion != null) {
                              _promoController.clear();
                              cart.applyPromotion(null);
                            } else {
                              _applyPromo(cart);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: cart.activePromotion != null ? AppTheme.red : AppTheme.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: Text(cart.activePromotion != null ? "Retirer" : "Appliquer", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Ticket de Caisse Détaillé
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border2, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        _buildTicketRow("Sous-total produits (HT)", cart.subtotalHT),
                        _buildTicketRow("TVA calculée", cart.totalVat),
                          if (cart.activePromotion != null)
                            _buildTicketRow('Code "${cart.activePromotion!.code}"', -cart.calculateDiscount(), isAccent: true),
                        if (!cart.isClickAndCollect) _buildTicketRow("Frais de livraison", cart.deliveryFee),
                        _buildTicketRow("Frais de service", cart.managementFee),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Colors.white24, height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("TOTAL À PAYER", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                            Text("${cart.totalFinal.toStringAsFixed(2).replaceAll('.', ',')} €", style: const TextStyle(color: AppTheme.greenXl, fontSize: 20, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Checkbox de sauvegarde de carte
                  Theme(
                    data: ThemeData(unselectedWidgetColor: AppTheme.muted2),
                    child: CheckboxListTile(
                      value: _saveCard,
                      onChanged: (val) => setState(() => _saveCard = val ?? false),
                      title: const Text("Mémoriser ma carte pour la prochaine fois", style: TextStyle(color: AppTheme.cream, fontSize: 13, fontWeight: FontWeight.w600)),
                      activeColor: AppTheme.greenXl,
                      checkColor: Colors.black,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Action de paiement
                  ElevatedButton(
                    onPressed: _isProcessing ? null : () => _processPayment(cart),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.green,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 8,
                      shadowColor: AppTheme.green.withValues(alpha: 0.5),
                    ),
                    child: _isProcessing
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.apple, color: Colors.white),
                              Icon(Icons.g_mobiledata, color: Colors.white, size: 30),
                              SizedBox(width: 8),
                              Text("PAYER MAINTENANT", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                            ],
                          ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
        ),
      ],
    );
  }

  Widget _buildTicketRow(String label, double amount, {bool isAccent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isAccent ? AppTheme.gold : AppTheme.muted2, fontSize: 13, fontWeight: isAccent ? FontWeight.w600 : FontWeight.normal)),
          Text(
            "${amount > 0 && !isAccent ? '' : amount < 0 ? '-' : ''}${amount.abs().toStringAsFixed(2).replaceAll('.', ',')} €",
            style: TextStyle(color: isAccent ? AppTheme.gold : AppTheme.cream, fontSize: 14, fontWeight: isAccent ? FontWeight.w700 : FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
