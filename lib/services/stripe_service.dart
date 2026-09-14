import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  // Singleton
  static final StripeService instance = StripeService._internal();
  StripeService._internal();

  /// Initialisation et configuration du PaymentSheet (One-Time ou One-Click)
  Future<void> initPaymentSheet({
    required String paymentIntentClientSecret,
    String? customerId,
    String? customerEphemeralKeySecret,
    String? setupIntentClientSecret, // Clé requise pour le One-Click via setup_future_usage: off_session côté API
  }) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) return;
    try {
      // Configuration vitale pour Apple Pay afin d'éviter l'Assertion Error
      Stripe.merchantIdentifier = 'merchant.com.openfood';
      Stripe.urlScheme = 'openfood'; // Optionnel pour le fallback 3D Secure iOS
      
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          // Infos d'identification du paiement en cours
          paymentIntentClientSecret: paymentIntentClientSecret,
          // Infos Client (pour rattacher la carte)
          customerId: customerId,
          customerEphemeralKeySecret: customerEphemeralKeySecret,
          // Intention de sauvegarde (SetupIntent) généré par setup_future_usage: 'off_session' via le backend
          setupIntentClientSecret: setupIntentClientSecret,
          
          merchantDisplayName: 'OpenFood',
          style: ThemeMode.dark, // Correspond à notre thème sombre actuel
          
          // Activation Apple Pay
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'FR', 
            // le paramètre applePayMerchantIdentifier est généralement défini dans Stripe.publishableKey à l'initialisation globale
          ),
          
          // Activation Google Pay
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'FR',
            testEnv: true, // Passer à false en prod
          ),
        ),
      );
    } catch (e) {
      throw Exception("Erreur d'initialisation Stripe : $e");
    }
  }

  /// Présentation de la feuille de paiement native avec gestion automatique du 3D Secure
  Future<bool> presentPaymentSheet() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) return true;
    try {
      // Le 3D Secure est géré de manière native et automatique par l'UI de Stripe
      await Stripe.instance.presentPaymentSheet();
      debugPrint("✅ Paiement validé avec succès (3D Secure validé si requis)");
      return true;
    } on StripeException catch (e) {
      debugPrint("❌ Paiement échoué ou annulé (StripeException) : ${e.error.localizedMessage}");
      return false;
    } catch (e) {
      debugPrint("❌ Erreur inattendue : $e");
      return false;
    }
  }

  /// Abonnement au programme de fidélité récurrent (OpenFood Pass)
  /// Note: La création ferme de l'abonnement récurrent (Subscription) se fait CÔTÉ BACKEND 
  /// (Firebase Cloud Functions). Cette fonction pilote le PaymentSheet pour la récurrence.
  Future<void> createOpenFoodPassSubscription({
    required String priceId,
    required String customerId,
  }) async {
    try {
      // 1. Appel HTTP/Firebase Functions vers votre backend pour créer l'Abonnement avec ce priceId
      // Exemple : Le backend créé l'abonnement en mode "incomplete" et renvoie le clientSecret
      const String fetchedClientSecret = "simulated_secret_from_backend"; // <- A remplacer
      
      // 2. On configure le PaymentSheet avec intention de setup la carte pour les prélèvements futurs
      await initPaymentSheet(
        paymentIntentClientSecret: fetchedClientSecret,
        customerId: customerId,
      );

      // 3. Demander au client de confirmer son abonnement via l'UI native, qui gérera le 3D Secure si sa banque le demande
      final bool success = await presentPaymentSheet();

      if (success) {
        debugPrint("✅ Abonnement au PriceID: $priceId réussi pour le client $customerId !");
      } else {
        throw Exception("Abandon ou échec du 3D Secure lors de la souscription.");
      }

    } catch (e) {
      throw Exception("Impossible de finaliser l'abonnement : $e");
    }
  }
}
