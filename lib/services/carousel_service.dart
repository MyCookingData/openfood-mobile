import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:openfood_models/openfood_models.dart';

class CarouselService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<CarouselModel>> getValidCarousels({
    CarouselPlacement placement = CarouselPlacement.home,
    String? restaurantId,
  }) async {
    final query = await _firestore
        .collection('carousels')
        .where('placement', isEqualTo: placement.name)
        .get();

    var allCarousels = query.docs.map((doc) => CarouselModel.fromFirestore(doc))
        .where((c) => c.isActive == true)
        .toList();
    allCarousels.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final List<CarouselModel> validCarousels = [];

    for (var carousel in allCarousels) {
      if (placement == CarouselPlacement.restaurant) {
        if (carousel.targetRestaurantId != null && carousel.targetRestaurantId!.isNotEmpty) {
          if (carousel.targetRestaurantId != restaurantId) continue;
        }
      }

      if (await _isValidForCurrentUser(carousel)) {
        validCarousels.add(carousel);
      }
    }

    return validCarousels;
  }

  Future<bool> _isValidForCurrentUser(CarouselModel carousel) async {
    final now = DateTime.now();

    // 1. Validation du jour de la semaine
    if (carousel.validDaysOfWeek != null && carousel.validDaysOfWeek!.isNotEmpty) {
      if (!carousel.validDaysOfWeek!.contains(now.weekday)) {
        return false;
      }
    }

    // 2. Validation de l'heure
    if (carousel.validTimeStart != null && carousel.validTimeEnd != null) {
      final startParts = carousel.validTimeStart!.split(':');
      final endParts = carousel.validTimeEnd!.split(':');
      
      final startHour = int.parse(startParts[0]);
      final startMin = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMin = int.parse(endParts[1]);

      final currentTime = now.hour * 60 + now.minute;
      final startTime = startHour * 60 + startMin;
      final endTime = endHour * 60 + endMin;

      if (currentTime < startTime || currentTime > endTime) {
        return false;
      }
    }

    // 3. Validation de l'historique utilisateur (Commandes / Dépenses)
    final needsHistoryCheck = carousel.minOrders != null || 
                              carousel.maxOrders != null || 
                              carousel.minTotalSpent != null || 
                              carousel.maxTotalSpent != null;

    if (needsHistoryCheck) {
      final user = _auth.currentUser;
      if (user == null) {
        // Utilisateur non connecté : s'il faut des commandes minimum, c'est mort.
        // S'il faut un max, 0 est valide.
        if (carousel.minOrders != null && carousel.minOrders! > 0) return false;
        if (carousel.minTotalSpent != null && carousel.minTotalSpent! > 0) return false;
      } else {
        var query = _firestore.collection('orders').where('userId', isEqualTo: user.uid);
        
        if (carousel.targetRestaurantId != null && carousel.targetRestaurantId!.isNotEmpty) {
          query = query.where('restaurantId', isEqualTo: carousel.targetRestaurantId);
        }
        
        final ordersSnapshot = await query.get();
        final int orderCount = ordersSnapshot.docs.length;
        
        double totalSpent = 0.0;
        for (var doc in ordersSnapshot.docs) {
          final data = doc.data();
          final amount = data['totalAmount'] ?? data['subtotal'] ?? 0.0;
          totalSpent += (amount as num).toDouble();
        }

        // Vérifications
        if (carousel.minOrders != null && orderCount < carousel.minOrders!) return false;
        if (carousel.maxOrders != null && orderCount > carousel.maxOrders!) return false;
        if (carousel.minTotalSpent != null && totalSpent < carousel.minTotalSpent!) return false;
        if (carousel.maxTotalSpent != null && totalSpent > carousel.maxTotalSpent!) return false;
      }
    }

    return true;
  }
}
