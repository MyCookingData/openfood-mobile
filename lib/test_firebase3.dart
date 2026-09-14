import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final rests = await FirebaseFirestore.instance.collection('restaurants').get();
  print('--- RESTAURANTS ---');
  for (var r in rests.docs) {
    print('id=${r.id}, name=${r.data()['name']}');
  }
  
  final prods = await FirebaseFirestore.instance.collection('products').get();
  print('--- PRODUCTS ---');
  for (var p in prods.docs) {
    print('id=${p.id}, restaurantId=${p.data()['restaurantId']}, name=${p.data()['name']}');
  }
}
