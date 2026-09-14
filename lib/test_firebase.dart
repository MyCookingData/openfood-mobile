import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final rests = await FirebaseFirestore.instance.collection('restaurants').limit(2).get();
  for (var r in rests.docs) {
    print('REST: id=${r.id}, name=${r.data()['name']}');
  }
  
  final prods = await FirebaseFirestore.instance.collection('products').limit(2).get();
  for (var p in prods.docs) {
    print('PROD: id=${p.id}, restaurantId=${p.data()['restaurantId']}, name=${p.data()['name']}');
  }
}
