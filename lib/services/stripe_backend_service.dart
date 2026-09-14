import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

class StripeBackendService {
  
  /// Débloque (capture) l'emprunte pour prendre l'argent et passe la commande en 'Préparation' (statut 1)
  static Future<bool> capturePaymentIntent(String orderId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('captureOrderPayment');
      final response = await callable.call({'orderId': orderId});
      
      if (response.data['success'] == true) {
        debugPrint('✅ Paiement capturé avec succès (Cloud Function)');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Exception Stripe Capture (Cloud Function): $e');
      return false;
    }
  }

  /// Annule complètement l'empreinte sans prendre l'argent et passe la commande en 'Annulé' (statut 4)
  static Future<bool> cancelPaymentIntent(String orderId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('cancelOrderPayment');
      final response = await callable.call({'orderId': orderId});
      
      if (response.data['success'] == true) {
        debugPrint('🚫 Paiement annulé avec succès (Cloud Function)');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Exception Stripe Cancel (Cloud Function): $e');
      return false;
    }
  }
}
