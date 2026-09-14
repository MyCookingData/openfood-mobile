import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:openfood_models/openfood_models.dart';

class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> logEvent({
    required String eventType, 
    required String eventAction, 
    Map<String, dynamic>? eventData,
  }) async {
    try {
      final user = _auth.currentUser;
      final event = AnalyticsEvent(
        id: const Uuid().v4(),
        userId: user?.uid,
        eventType: eventType,
        eventAction: eventAction,
        eventData: eventData ?? {},
        timestamp: DateTime.now(),
      );

      await _firestore.collection('analytics_events').doc(event.id).set(event.toJson());
    } catch (e) {
      // Fail silently to not disrupt the user experience
      print("Analytics Error: $e");
    }
  }

  // --- Helpers ---
  static void logNavigation(String tabName) {
    logEvent(
      eventType: "navigation",
      eventAction: "tab_clicked",
      eventData: {"tab": tabName},
    );
  }

  static void logFilter(String filterName) {
    logEvent(
      eventType: "filter",
      eventAction: "filter_selected",
      eventData: {"filter": filterName},
    );
  }

  static void logSearch(String query) {
    logEvent(
      eventType: "search",
      eventAction: "search_executed",
      eventData: {"query": query},
    );
  }

  static void logCartAction(String action, String productName, double price) {
    logEvent(
      eventType: "cart",
      eventAction: action,
      eventData: {
        "product_name": productName,
        "price": price,
      },
    );
  }

  static void logCheckoutFunnel(String step, int durationInSeconds, {Map<String, dynamic>? extraData}) {
    logEvent(
      eventType: "funnel",
      eventAction: step, // ex: 'entered_cart', 'checkout_completed'
      eventData: {
        "duration_seconds": durationInSeconds,
        ...?extraData,
      },
    );
  }
}
