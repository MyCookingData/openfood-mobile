import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'core/theme.dart';
import 'main_wrapper.dart';
import 'screens/livreur/livreur_home_screen.dart';
import 'services/auth_service.dart';

import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/foundation.dart';
import 'providers/cart_provider.dart';
import 'providers/location_provider.dart';

import 'package:intl/date_symbol_data_local.dart';

bool isFirebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('fr', null);

  // Initialisation de Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseInitialized = true; // Succès

    // Migration silencieuse des tags Firestore en arrière-plan désactivée pour la perf
    // DatabaseService.runTagMigration().catchError((e) => debugPrint("Erreur migration tags: $e"));
  } catch (e) {
    debugPrint("Erreur d'initialisation Firebase : $e");
    isFirebaseInitialized = false; // Echec (flutterfire non lancé)
  }

  // Initialisation de Stripe (Uniquement sur appareils compatibles, évite le Crash Windows et Web)
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    // TODO (PRODUCTION): Remplacer la clé ci-dessous par votre clé PUBLIQUE de production Stripe (pk_live_...)
    Stripe.publishableKey = 'pk_test_51PWey5AQoI9u5VYqxFtORW8o57ByrPHgAAATtKE8udaQ35A1kDzi5BJdfi79FmiorDHD9fWMOmbxfAWHcuiYCybK00X8F5XKnE';
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProxyProvider<LocationProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, loc, cart) => cart!..updateLocation(loc.selectedAddress),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Openfood Caraîbe',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Si Firebase a planté (ex: flutterfire non configuré sur Windows),
    // on affiche directement un menu de test au lieu de faire planter l'app.
    if (!isFirebaseInitialized) {
      return _buildDevBypassScreen(context);
    }

    final authService = AuthService();

    return StreamBuilder<auth.User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.bg,
            body:
                Center(child: CircularProgressIndicator(color: AppTheme.green)),
          );
        }

        final auth.User? user = snapshot.data;

        if (user == null) {
          return const MainWrapper();
        }

        return FutureBuilder<UserRole?>(
          future: authService.getUserRole(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppTheme.bg,
                body: Center(
                    child: CircularProgressIndicator(color: AppTheme.green)),
              );
            }

            final role = roleSnapshot.data;

            if (role == UserRole.livreur) {
              return const LivreurHomeScreen();
            }

            return const MainWrapper();
          },
        );
      },
    );
  }

  // Écran de contournement pour les développeurs
  Widget _buildDevBypassScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.gold, size: 60),
              const SizedBox(height: 16),
              const Text(
                "Firebase Non Configuré",
                style: TextStyle(
                    fontFamily: 'Bricolage Grotesque',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.cream),
              ),
              const SizedBox(height: 10),
              const Text(
                "Le projet Flutter n'est pas encore relié à Firebase (flutterfire configure n'a pas été lancé).\n\nEn attendant, vous pouvez accéder directement aux maquettes avec les boutons ci-dessous :",
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 48),

              // Bouton App Client
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const MainWrapper())),
                icon: const Icon(Icons.shopping_bag_outlined,
                    color: Colors.white),
                label: const Text("Tester l'App Client (Resto)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton App Livreur
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LivreurHomeScreen())),
                icon: const Icon(Icons.motorcycle_outlined,
                    color: Color.fromRGBO(255, 255, 255, 1)),
                label: const Text("Tester l'App Livreur"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface3,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  side: BorderSide(color: AppTheme.border2, width: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
