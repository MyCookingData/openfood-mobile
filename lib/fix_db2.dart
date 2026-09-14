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

  print('--- RESTAURANTS ---');
  final snap = await FirebaseFirestore.instance.collection('restaurants').get();
  for (var doc in snap.docs) {
    print('${doc.id} -> name: ${doc.data()['name']}');
  }
  print('--- DONE ---');
}
