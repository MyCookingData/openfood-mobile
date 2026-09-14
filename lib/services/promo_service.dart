import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:openfood_models/openfood_models.dart';

class PromoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<PromoCodeModel?> validateAndGetPromo(String codeText, {String? cartRestaurantId}) async {
    final cleanCode = codeText.trim().toUpperCase();
    if (cleanCode.isEmpty) return null;

    try {
      final querySnapshot = await _firestore
          .collection('promo_codes')
          .where('code', isEqualTo: cleanCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception("Ce code promo n'existe pas ou est inactif.");
      }

      final data = querySnapshot.docs.first.data();
      final promo = PromoCodeModel.fromJson(data);

      if (!promo.isValid()) {
        throw Exception("Ce code promo est expiré ou le quota maximal a été atteint.");
      }

      // 1. Time validations
      final now = DateTime.now();
      if (promo.validDaysOfWeek != null && promo.validDaysOfWeek!.isNotEmpty) {
        if (!promo.validDaysOfWeek!.contains(now.weekday)) {
          throw Exception("Ce code n'est pas valable aujourd'hui.");
        }
      }
      
      if (promo.validTimeStart != null && promo.validTimeEnd != null) {
        final startTime = DateFormat('HH:mm').parse(promo.validTimeStart!);
        final endTime = DateFormat('HH:mm').parse(promo.validTimeEnd!);
        final nowTime = DateFormat('HH:mm').parse(DateFormat('HH:mm').format(now));
        
        if (nowTime.isBefore(startTime) || nowTime.isAfter(endTime)) {
          throw Exception("Ce code n'est valable qu'entre ${promo.validTimeStart} et ${promo.validTimeEnd}.");
        }
      }

      // 1.5 Restaurant Validation
      if (promo.requiredRestaurantId != null && cartRestaurantId != null) {
        if (promo.requiredRestaurantId != cartRestaurantId) {
          final restoDoc = await _firestore.collection('restaurants').doc(promo.requiredRestaurantId).get();
          if (restoDoc.exists) {
            final restoName = restoDoc.data()?['name'] as String?;
            if (restoName != cartRestaurantId) {
              throw Exception("Ce code promo n'est pas valable pour ce restaurant.");
            }
          } else {
             throw Exception("Ce code promo n'est pas valable pour ce restaurant.");
          }
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 2. First Order Validation
        if (promo.firstOrderOnly) {
          var query = _firestore.collection('orders').where('userId', isEqualTo: user.uid);
          if (promo.requiredRestaurantId != null) {
            query = query.where('restaurantId', isEqualTo: promo.requiredRestaurantId);
          }
          final pastOrdersQuery = await query.limit(1).get();
          
          if (pastOrdersQuery.docs.isNotEmpty) {
            if (promo.requiredRestaurantId != null) {
              throw Exception("Ce code est réservé à votre première commande dans ce restaurant.");
            } else {
              throw Exception("Ce code est réservé aux nouveaux clients pour leur première commande.");
            }
          }
        }

        // 3. Max Uses Per User Validation
        if (promo.maxUsesPerUser != null) {
          final pastPromoUses = await _firestore
              .collection('orders')
              .where('userId', isEqualTo: user.uid)
              .where('promoCodeId', isEqualTo: promo.id)
              .get();
              
          if (pastPromoUses.docs.length >= promo.maxUsesPerUser!) {
            throw Exception("Vous avez déjà atteint la limite d'utilisation pour ce code (${promo.maxUsesPerUser} fois).");
          }
        }
      }

      return promo;
    } catch (e) {
      // Retransmit exception for UI to display
      rethrow;
    }
  }
}
