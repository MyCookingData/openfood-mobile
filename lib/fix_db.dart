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
  for (var doc in snap.docs) {
    print('${doc.id} -> requiredRestaurantId: ${doc.data()['requiredRestaurantId']}');
    // Si requiredRestaurantId n'est pas un ID valide, on peut le voir ici.
    
    // CORRECTION si c'est "Open Food"
    if (doc.data()['requiredRestaurantId'] == 'Open Food') {
      print('FOUND CORRUPT PROMO CODE! fixing...');
      // Find the real ID of Open Food
      final restoSnap = await FirebaseFirestore.instance.collection('restaurants').where('name', isEqualTo: 'Open Food').get();
      if (restoSnap.docs.isNotEmpty) {
        final realId = restoSnap.docs.first.id;
        await doc.reference.update({'requiredRestaurantId': realId});
        print('Fixed promo code ${doc.id} -> new requiredRestaurantId: $realId');
      }
    }
  }
  
  print('--- DONE ---');
}
