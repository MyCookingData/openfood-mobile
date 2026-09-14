import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/seed_service.dart';
import '../providers/location_provider.dart';
import '../providers/cart_provider.dart';
import '../services/notification_service.dart';
import 'address_picker_screen.dart';
import 'auth/login_screen.dart' as auth_screen;

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  const ProfileScreen({super.key, this.onBackToHome});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isPhoneValidated = false;

  @override
  void initState() {
    super.initState();
    _loadPhoneState();
  }

  Future<void> _loadPhoneState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPhoneValidated = prefs.getBool('isPhoneValidated') ?? false;
      _phoneController.text = prefs.getString('phoneNumber') ?? "+596 ";
    });
  }

  Future<void> _validatePhone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPhoneValidated', true);
    await prefs.setString('phoneNumber', _phoneController.text);
    setState(() => _isPhoneValidated = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("SMS envoyé ! Téléphone validé."),
          backgroundColor: AppTheme.greenXl));
    }
  }

  Future<void> _runSeeder() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ ATTENTION"),
        content: const Text(
            "Voulez-vous vraiment effacer TOUTE la base de données et la recréer avec de fausses données de test ? Cette action est irréversible."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redL),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("OUI, PURGER",
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Purge & Seeding en cours..."),
            backgroundColor: AppTheme.gold));
      }
      await SeedService.seedDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Base de données parfaitement recréée !"),
            backgroundColor: AppTheme.greenXl));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Erreur: $e"), backgroundColor: AppTheme.redL));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme
          .bg, // Fix: AppTheme.bg au lieu de Colors.transparent pour l'affichage hors MainWrapper
      appBar: AppBar(
        title: const Text("Mon Compte",
            style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
                color: AppTheme.cream)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_downward,
                color: AppTheme.cream), // Flèche orientée vers le menu du bas
            onPressed: () {
              if (widget.onBackToHome != null) {
                widget.onBackToHome!();
              } else {
                Navigator.of(context).pop();
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Header Profil ---
            StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  return Row(
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        backgroundColor: AppTheme.surface3,
                        child: Text("ðŸ”", style: TextStyle(fontSize: 36)),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.email?.split('@').first ?? "Client",
                              style: const TextStyle(
                                  color: AppTheme.cream,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          Text(user?.email ?? "Non connecté",
                              style: TextStyle(
                                  color: AppTheme.green.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ).animate().fade(duration: 400.ms).slideY(begin: 0.1);
                }),

            // --- Section Localisation ---
            const Text("ðŸ“ CARNET D'ADRESSES",
                    style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2))
                .animate()
                .fade(delay: 100.ms),
            const SizedBox(height: 12),

            Consumer<LocationProvider>(builder: (context, loc, _) {
              return Column(
                children: [
                  if (loc.addresses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border2)),
                      child: const Text("Aucune adresse enregistrée",
                          style: TextStyle(color: AppTheme.muted),
                          textAlign: TextAlign.center),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: loc.addresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = loc.addresses[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border2),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                                backgroundColor: AppTheme.surface3,
                                child: Icon(Icons.location_on,
                                    color: AppTheme.muted, size: 20)),
                            title: Text(item.label,
                                style: const TextStyle(
                                    color: AppTheme.cream,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(item.addressName,
                                style: const TextStyle(
                                    color: AppTheme.muted, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppTheme.redL),
                              onPressed: () => loc.removeAddress(item.id),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.cream,
                        side: BorderSide(color: AppTheme.border2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add, color: AppTheme.greenL),
                      label: const Text("Ajouter une nouvelle adresse"),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddressPickerScreen())),
                    ),
                  ),
                ],
              );
            })
                .animate()
                .fade(duration: 400.ms, delay: 150.ms)
                .slideX(begin: 0.05),

            const SizedBox(height: 32),

            StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- Section Téléphone ---
                        const Text("📱 SÉCURITÉ & CONTACT",
                                style: TextStyle(
                                    color: AppTheme.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2))
                            .animate()
                            .fade(delay: 200.ms),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.border2)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Numéro de téléphone",
                                      style: TextStyle(
                                          color: AppTheme.cream, fontSize: 14)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _isPhoneValidated
                                          ? AppTheme.green
                                              .withValues(alpha: 0.2)
                                          : AppTheme.redL
                                              .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _isPhoneValidated
                                          ? "Vérifié"
                                          : "Non vérifié",
                                      style: TextStyle(
                                          color: _isPhoneValidated
                                              ? AppTheme.green
                                              : AppTheme.redL,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      style: const TextStyle(
                                          color: AppTheme.cream,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.5),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: AppTheme.surface3,
                                        prefixIcon: const Icon(Icons.phone,
                                            color: AppTheme.muted2, size: 20),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 14),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide.none),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (!_isPhoneValidated)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.surface3,
                                    foregroundColor: AppTheme.cream,
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onPressed: _validatePhone,
                                  child: const Text(
                                      "Valider ce numéro par SMS",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        )
                            .animate()
                            .fade(duration: 400.ms, delay: 250.ms)
                            .slideX(begin: 0.05),

                        const SizedBox(height: 48),

                        // --- Bouton Déconnexion ---
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppTheme.redL.withValues(alpha: 0.1),
                            foregroundColor: AppTheme.redL,
                            minimumSize: const Size(double.infinity, 54),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                  color: AppTheme.redL, width: 2),
                            ),
                          ),
                          onPressed: () async {
                            // Clean up cache for the current user
                            Provider.of<CartProvider>(context, listen: false)
                                .clearCart();
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('isPhoneValidated');
                            await prefs.remove('phoneNumber');
                            // Stop global services
                            NotificationService.instance.stopListening();

                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context, rootNavigator: true)
                                  .popUntil((route) => route.isFirst);
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text("Déconnexion",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ).animate().fade(delay: 300.ms),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        const SizedBox(height: 32),
                        // --- Bouton Connexion ---
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppTheme.greenXl.withValues(alpha: 0.1),
                            foregroundColor: AppTheme.greenXl,
                            minimumSize: const Size(double.infinity, 54),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                  color: AppTheme.greenXl, width: 2),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const auth_screen.LoginScreen()));
                          },
                          icon: const Icon(Icons.login),
                          label: const Text("Se connecter / S'inscrire",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ).animate().fade().slideY(begin: 0.1),
                      ],
                    );
                  }
                }),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.redL.withValues(alpha: 0.1),
                foregroundColor: AppTheme.redL,
                minimumSize: const Size(double.infinity, 54),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.redL, width: 2),
                ),
              ),
              onPressed: _runSeeder,
              icon: const Icon(Icons.delete_forever),
              label: const Text("Purger et Réinitialiser la BDD",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ).animate().fade(),
            const SizedBox(height: 120), // Espace pour BottomNavBar
          ],
        ),
      ),
    );
  }
}
