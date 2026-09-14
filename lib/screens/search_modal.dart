import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../utils/string_extensions.dart';
import 'resto/resto_screen.dart';
import '../services/analytics_service.dart';

class SearchModal extends StatefulWidget {
  const SearchModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SearchModal(),
    );
  }

  @override
  State<SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends State<SearchModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = "";

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              onChanged: (val) {
                setState(() {
                  _query = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Plat, restaurant, cuisine...",
                hintStyle: const TextStyle(color: AppTheme.muted),
                prefixIcon: const Icon(Icons.search, color: AppTheme.muted),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.muted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = "");
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: AppTheme.border2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: AppTheme.border2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: AppTheme.greenXl),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: _query.isEmpty
                ? _buildEmptyState()
                : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("🔍", style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text("Qu'est-ce qui vous fait envie ?", style: AppTheme.titleStyle.copyWith(color: AppTheme.muted)),
        ],
      ).animate().fade(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.greenXl));
        }

        final allDocs = snapshot.data!.docs;
        // Simple client-side search simulation for demonstration
        final results = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final restaurantName = (data['restaurantId'] ?? '').toString().toLowerCase();
          final category = (data['category'] ?? '').toString().toLowerCase();
          
          return name.contains(_query) || restaurantName.contains(_query) || category.contains(_query);
        }).toList();

        if (results.isEmpty) {
          return Center(
            child: Text("Aucun résultat pour '$_query'", style: const TextStyle(color: AppTheme.muted)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white24, height: 24),
          itemBuilder: (context, index) {
            final doc = results[index].data() as Map<String, dynamic>;
            final title = doc['name'] ?? 'Inconnu';
            final resto = doc['restaurantId'] ?? '';
            final priceHT = (doc['priceHT'] as num?)?.toDouble() ?? 10.0;
            final vatRate = (doc['vatRate'] as num?)?.toDouble() ?? 2.1;
            final priceTTC = priceHT * (1 + vatRate / 100);

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text("🍽️", style: TextStyle(fontSize: 20))),
              ),
              title: Text(title, style: AppTheme.titleStyle.copyWith(fontSize: 15)),
              subtitle: Text(resto.formattedRestaurantName, style: const TextStyle(color: AppTheme.greenXl, fontSize: 13, fontWeight: FontWeight.w600)),
              trailing: Text("${priceTTC.toStringAsFixed(2).replaceAll('.', ',')}€", style: AppTheme.titleStyle.copyWith(fontSize: 14)),
              onTap: () {
                AnalyticsService.logSearch(_query);
                AnalyticsService.logEvent(
                  eventType: "search",
                  eventAction: "result_clicked",
                  eventData: {"title": title, "restaurant": resto},
                );
                // Navegate to the restaurant passing the exact name so RestoScreen dynamically filters
                Navigator.pop(context); // close modal
                Navigator.push(context, MaterialPageRoute(builder: (_) => RestoScreen(restaurantName: resto)));
              },
            ).animate().fade(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.1, curve: Curves.easeOut);
          },
        );
      },
    );
  }
}
