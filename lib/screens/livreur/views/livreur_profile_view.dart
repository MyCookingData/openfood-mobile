import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';
import '../../auth/login_screen.dart';

class LivreurProfileView extends StatelessWidget {
  const LivreurProfileView({super.key});

  void _showRatingInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: AppTheme.gold, size: 32),
                SizedBox(width: 12),
                Text("Votre Note Globale", style: TextStyle(color: AppTheme.cream, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Cette note est une moyenne calculée automatiquement sur vos 100 dernières livraisons.\n\n"
              "Elle prend en compte :\n"
              "• La rapidité de livraison par rapport au temps estimé\n"
              "• L'évaluation laissée par les clients\n"
              "• Le soin apporté aux commandes\n\n"
              "Maintenez une note supérieure à 4.5 pour accéder aux courses prioritaires !",
              style: TextStyle(color: AppTheme.muted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.greenXl,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Compris", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editVehicle(BuildContext context, String currentVehicle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Changer de véhicule", style: TextStyle(color: AppTheme.cream, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...['Scooter', 'Vélo', 'Voiture'].map((v) => ListTile(
              title: Text(v, style: TextStyle(color: v == currentVehicle ? AppTheme.greenXl : AppTheme.cream, fontWeight: FontWeight.bold)),
              trailing: v == currentVehicle ? const Icon(Icons.check, color: AppTheme.greenXl) : null,
              onTap: () {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  FirebaseFirestore.instance.collection('users').doc(uid).update({'vehicleType': v});
                }
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _editName(BuildContext context, String currentName) {
    final TextEditingController controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Modifier le nom", style: TextStyle(color: AppTheme.cream)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppTheme.cream),
          decoration: InputDecoration(
            hintText: "Votre nom",
            hintStyle: TextStyle(color: AppTheme.muted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.border2)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.greenXl)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler", style: TextStyle(color: AppTheme.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenXl),
            onPressed: () {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null && controller.text.trim().isNotEmpty) {
                FirebaseFirestore.instance.collection('users').doc(uid).update({'name': controller.text.trim()});
              }
              Navigator.pop(context);
            },
            child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Non connecté", style: TextStyle(color: AppTheme.cream)));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.greenXl));
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final displayName = userData['name'] ?? user.displayName ?? "Livreur";
        final vehicleType = userData['vehicleType'] ?? "Scooter";
        final rating = userData['rating'] ?? 4.9;

        return Scaffold(
          backgroundColor: AppTheme.bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text("Mon Profil", style: TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold)),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // En-tête profil
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'L',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(color: AppTheme.cream, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.muted, size: 20),
                      onPressed: () => _editName(context, displayName),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(user.email ?? "", style: const TextStyle(color: AppTheme.muted, fontSize: 14)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Color(0xFF0EA5E9), size: 16),
                      SizedBox(width: 6),
                      Text("Livreur Indépendant Vérifié", style: TextStyle(color: Color(0xFF0EA5E9), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Indicateurs (Note / Véhicule)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showRatingInfo(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppTheme.surface3, borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.star, color: AppTheme.gold, size: 28),
                                    const SizedBox(width: 8),
                                    Text(rating.toStringAsFixed(1), style: const TextStyle(color: AppTheme.cream, fontSize: 24, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text("Note Globale", style: TextStyle(color: AppTheme.cream.withValues(alpha: 0.6), fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _editVehicle(context, vehicleType),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppTheme.surface3, borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                const Icon(Icons.two_wheeler, color: Color(0xFF0EA5E9), size: 28),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(vehicleType, style: const TextStyle(color: AppTheme.cream, fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down, color: AppTheme.muted, size: 16),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text("Véhicule", style: TextStyle(color: AppTheme.cream.withValues(alpha: 0.6), fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                
                // --- Paramètres ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: const Text("Paramètres", style: TextStyle(color: AppTheme.cream, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.surface3, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.map_outlined, color: AppTheme.cream),
                        ),
                        title: const Text("Préférences de Navigation", style: TextStyle(color: AppTheme.cream)),
                        trailing: const Icon(Icons.chevron_right, color: AppTheme.muted),
                        onTap: () {},
                      ),
                      Divider(color: AppTheme.border2, height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.surface3, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.notifications_none, color: AppTheme.cream),
                        ),
                        title: const Text("Notifications", style: TextStyle(color: AppTheme.cream)),
                        trailing: const Icon(Icons.chevron_right, color: AppTheme.muted),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // --- Déconnexion ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.logout, color: AppTheme.red),
                      label: const Text("Se Déconnecter", style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (Route<dynamic> route) => false,
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      }
    );
  }
}
