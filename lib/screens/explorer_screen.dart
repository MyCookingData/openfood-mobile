import 'package:flutter/material.dart';
import 'package:openfood_models/openfood_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../widgets/dish_card.dart';
import '../widgets/perso_modal.dart';
import 'search_modal.dart';

class ExplorerScreen extends StatelessWidget {
  final String category;

  const ExplorerScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    // Dynamic Query based on category
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('products');
    if (category != "Tout") {
      query = query.where('category', isEqualTo: category);
    }
    
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          category == "Tout" ? "Explorer" : category,
          style: AppTheme.titleStyle.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => SearchModal.show(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.greenXl));
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Erreur de chargement", style: TextStyle(color: AppTheme.redL)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("🍽️", style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 16),
                  Text(
                    "Aucun plat trouvé !",
                    style: AppTheme.titleStyle.copyWith(color: AppTheme.muted, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              final product = ProductModel.fromJson(data);
              final priceTTC = product.priceHT * (1 + product.vatRate / 100);

              return GestureDetector(
                onTap: product.isAvailable ? () {
                  PersoModal.show(
                    context,
                    product: product,
                    emoji: "🍔",
                  );
                } : () {},
                child: DishCard(
                  title: product.name,
                  restaurant: product.restaurantName ?? product.restaurantId,
                  price: priceTTC,
                  emoji: "🍔",
                  badgeText: "NOUVEAU",
                  isAvailable: product.isAvailable,
                  imageGradient: const [Color(0xFF080D14), Color(0xFF141E30)],
                  imageUrl: product.image,
                  onAdd: product.isAvailable ? () => PersoModal.show(context, product: product, emoji: "??") : null,
                ),
              ).animate().fade(duration: 400.ms, delay: (index * 50).ms).slideY(begin: 0.1, curve: Curves.easeOutQuad);
            },
          );
        },
      ),
    );
  }
}
