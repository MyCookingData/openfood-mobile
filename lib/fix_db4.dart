import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyA49Q5B4nF8K2OZtDoxUsmELpAb0zZUZbc',
      appId: '1:178517740611:web:09dfba077107c07f59d8f6',
      messagingSenderId: '178517740611',
      projectId: 'app-openfood',
      authDomain: 'app-openfood.firebaseapp.com',
      storageBucket: 'app-openfood.firebasestorage.app',
    ),
  );

  print('--- PROMO CODES ---');
  final snap = await FirebaseFirestore.instance.collection('promo_codes').get();
  
  // Find "Open Food" actual ID
  final restoSnap = await FirebaseFirestore.instance.collection('restaurants').where('name', isEqualTo: 'Open Food').get();
  String? realId;
  if (restoSnap.docs.isNotEmpty) {
    realId = restoSnap.docs.first.id;
    print('Real Open Food ID: \$realId');
  }

  for (var doc in snap.docs) {
    final rid = doc.data()['requiredRestaurantId'];
    if (rid == 'open_food' || rid == 'Open Food') {
      if (realId != null) {
        await doc.reference.update({'requiredRestaurantId': realId});
        print('Fixed promo code \${doc.id} -> new requiredRestaurantId: \$realId');
      } else {
        await doc.reference.update({'requiredRestaurantId': null});
        print('Fixed promo code \${doc.id} -> new requiredRestaurantId: null (resto not found)');
      }
    }
  }
  
  print('--- DONE ---');
}
