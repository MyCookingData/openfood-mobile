import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  NotificationService._internal();

  Future<void> initialize() async {
    // Demande de permission pour FCM
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('FCM Authorization status: ${settings.authorizationStatus}');

    // Configuration de flutter_local_notifications (pour Android en premier plan)
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("🔔 Notification tapée : ${response.payload}");
      },
    );

    // Demander les permissions Android 13+ si nécessaire
    if (!kIsWeb) {
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }

    // Gérer les notifications en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Notification reçue en premier plan: ${message.messageId}');
      if (message.notification != null) {
        _showNotification(
          id: message.hashCode,
          title: message.notification!.title ?? 'Nouvelle notification',
          body: message.notification!.body ?? '',
        );
      }
    });

    // Sauvegarder le token FCM
    await _saveFCMToken();

    // Mettre à jour le token si l'utilisateur change ou si le token est rafraîchi
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });
  }

  Future<void> _saveFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint("Erreur lors de la récupération du token FCM: $e");
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
        debugPrint("Token FCM sauvegardé: $token");
      } catch (e) {
        debugPrint("Erreur lors de la sauvegarde du token: $e");
      }
    }
  }

  Future<void> _showNotification({required int id, required String title, required String body, String? payload}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'openfood_channel',
      'OpenFood Notifications',
      channelDescription: 'Notifications de statut de commande OpenFood',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2E8B57),
    );
    
    const DarwinNotificationDetails darwinPlatformChannelSpecifics = DarwinNotificationDetails();
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );
    
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Ces méthodes étaient utilisées pour l'ancienne logique locale
  void startListeningToOrders() {
    debugPrint("La méthode startListeningToOrders() est maintenant gérée par Cloud Functions.");
  }

  void stopListening() {
    debugPrint("Arrêt de l'écoute des notifications locales.");
  }
}
