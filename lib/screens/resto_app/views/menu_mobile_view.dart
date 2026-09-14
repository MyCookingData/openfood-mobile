import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';

class MenuMobileView extends StatelessWidget {
  const MenuMobileView({super.key});

  Future<void> _toggleAvailability(String docId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(docId).update({
        'isAvailable': !currentStatus,
      });
    } catch (e) {
      debugPrint("Erreur lors de la maj du produit: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // En-tête du Menu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Gestion du Menu", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.cream)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.surface3, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                child: const Text("Tous les restos", style: TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.greenXl));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("Aucun produit trouvé dans Firebase.", style: TextStyle(color: AppTheme.muted2)),
                );
              }

              final products = snapshot.data!.docs;

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                physics: const BouncingScrollPhysics(),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = products[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Inconnu';
                  final resto = data['restaurantId'] ?? 'Sans Nom';
                  
                  // Par défaut : disponible if 'isAvailable' is missing
                  final bool isAvailable = data.containsKey('isAvailable') ? data['isAvailable'] : true;
                  
                  final vHT = (data['priceHT'] as num?)?.toDouble() ?? 10.0;
                  final vRate = (data['vatRate'] as num?)?.toDouble() ?? 2.1;
                  final vTTC = vHT * (1 + vRate / 100);

                  return Container(
                    decoration: BoxDecoration(
                      color: isAvailable ? AppTheme.surface : AppTheme.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isAvailable ? AppTheme.border : AppTheme.redL.withValues(alpha: 0.3)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Image Mockup
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.surface3,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                             child: Text("🔥", style: TextStyle(fontSize: 20, color: isAvailable ? Colors.white : Colors.white.withValues(alpha: 0.3))),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Détails
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(color: isAvailable ? AppTheme.cream : AppTheme.muted2, fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("$resto  •  ${vTTC.toStringAsFixed(2).replaceAll('.', ',')} €", style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        // Switch Dispo
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Switch(
                              value: isAvailable,
                              activeTrackColor: AppTheme.greenXl,
                              inactiveThumbColor: AppTheme.red,
                              inactiveTrackColor: AppTheme.red.withValues(alpha: 0.3),
                              onChanged: (val) => _toggleAvailability(doc.id, isAvailable),
                            ),
                            Text(isAvailable ? "En stock" : "Rupture", style: TextStyle(color: isAvailable ? AppTheme.green : AppTheme.redL, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
