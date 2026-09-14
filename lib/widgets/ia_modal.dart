import 'package:flutter/material.dart';
import 'package:openfood_models/openfood_models.dart';
import '../core/theme.dart';
import '../services/database_service.dart';
import 'perso_modal.dart';

class IAModal extends StatefulWidget {
  const IAModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const IAModal(),
    );
  }

  @override
  State<IAModal> createState() => _IAModalState();
}

class _IAModalState extends State<IAModal> {
  final Map<String, bool> _prefs = {
    "🥩 Viande": true,
    "🐟 Poisson": false,
    "🌶 Épicé": true,
    "🥗 Léger": false,
    "🍝 Pâtes": true,
    "🍔 Burger": false,
    "🥦 Végétarien": false,
    "⚡ Rapide": true,
  };

  bool _isLoading = false;
  Map<String, dynamic>? _result;

  void _generateChoice() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });
    
    // Extraction des mots-clés cliqués (Ex: ["Viande", "Pâtes", "Rapide"])
    final activeTags = _prefs.entries.where((e) => e.value).map((e) => e.key.split(' ').last).toList();

    // Attente artificielle pour l'effet psychologique "IA qui réfléchit"
    await Future.delayed(const Duration(milliseconds: 1300));
    final item = await DatabaseService.getRandomDish(activeTags);
    
    if (mounted) {
      setState(() {
        _result = item;
        _isLoading = false;
      });
    }
  }

  void _addFromIA() {
    if (_result != null) {
      // On ferme d'abord l'IAModal
      Navigator.of(context).pop();
      
      // On ouvre immédiatement PersoModal avec l'arbre d'options complet
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          final data = Map<String, dynamic>.from(_result!);
          // The database service should return the 'id' ideally, if not we fake one for IA
          if (!data.containsKey('id')) data['id'] = data['name'].toString().replaceAll(' ', '_');
          final product = ProductModel.fromJson(data);
          
          if (product.isAvailable) {
            PersoModal.show(
              context,
              product: product,
              emoji: "🤖",
            );
          }
        }
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 22, right: 22, top: 26, bottom: 44),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppTheme.border2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                color: AppTheme.surface3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          RichText(
            text: TextSpan(
              style: AppTheme.titleStyle.copyWith(fontSize: 23),
              children: const [
                TextSpan(text: "🎲 ", style: TextStyle(color: Colors.white)),
                TextSpan(text: "Surprends-moi !", style: TextStyle(color: AppTheme.greenXl)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text("Dis-moi tes envies, l'IA fait le reste", style: TextStyle(color: AppTheme.muted, fontSize: 13)),
          const SizedBox(height: 20),
          
          // Prefs
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _prefs.entries.map((e) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _prefs[e.key] = !e.value;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: e.value ? AppTheme.green.withValues(alpha: 0.15) : AppTheme.surface2,
                    border: Border.all(color: e.value ? AppTheme.green : AppTheme.border, width: 1.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    e.key,
                    style: TextStyle(
                      color: e.value ? AppTheme.greenXl : AppTheme.cream,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          
          ElevatedButton(
            onPressed: _isLoading ? null : _generateChoice,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(15),
              backgroundColor: AppTheme.greenL,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              shadowColor: AppTheme.green.withValues(alpha: 0.35),
              elevation: 8,
            ),
            child: Text(
              _isLoading ? "✦ Analyse en cours…" : (_result != null ? "🎲 Autre suggestion" : "🎲 Trouver mon repas idéal"),
              style: AppTheme.titleStyle.copyWith(fontSize: 16),
            ),
          ),
          
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                border: Border.all(color: AppTheme.border2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Text(_result!['ico'], style: const TextStyle(fontSize: 42)),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_result!['name'] ?? 'Plat mystère', style: AppTheme.titleStyle.copyWith(fontSize: 15, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text("${_result!['restaurantId'] ?? 'Restaurant'} · 25 min", style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                        const SizedBox(height: 3),
                        Text("${(((_result!['priceHT'] as num?)?.toDouble() ?? 10.0) * (1 + ((_result!['vatRate'] as num?)?.toDouble() ?? 2.1) / 100)).toStringAsFixed(2).replaceAll('.', ',')}€", style: const TextStyle(color: AppTheme.greenXl, fontSize: 14, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 11),
            ElevatedButton(
              onPressed: _addFromIA,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(13),
                backgroundColor: AppTheme.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text("+ Ajouter au panier", style: AppTheme.titleStyle.copyWith(fontSize: 14)),
            ),
          ],
          
          const SizedBox(height: 9),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(11),
              side: BorderSide(color: AppTheme.border2, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text("Fermer", style: TextStyle(color: AppTheme.muted2, fontWeight: FontWeight.w600, fontSize: 14)),
          )
        ],
      ),
    );
  }
}
