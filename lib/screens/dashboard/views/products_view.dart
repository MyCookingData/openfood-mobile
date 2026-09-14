import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../widgets/product_admin_modal.dart';

class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  String _filterCat = "Toutes les catégories";
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> products = [
    {
      "id": 1,
      "name": "Colombo de porc",
      "desc": "Porc mariné aux épices créoles, riz parfumé et légumes du jardin",
      "price": 13.90,
      "cat": "Viandes",
      "stock": "∞",
      "active": true,
      "imgGrad": const [Color(0xFF071408), Color(0xFF1A4020)],
      "ico": "🥩"
    },
    {
      "id": 2,
      "name": "Pasta Carbonara",
      "desc": "Pâtes maison, lardons fumés, sauce crémeuse, parmesan râpé",
      "price": 11.90,
      "cat": "Pasta",
      "stock": "∞",
      "active": true,
      "imgGrad": const [Color(0xFF0D0A07), Color(0xFF3A2010)],
      "ico": "🍝"
    },
    {
      "id": 3,
      "name": "Bowl créole",
      "desc": "Quinoa, légumes grillés, sauce créole maison, avocat",
      "price": 12.50,
      "cat": "Viandes",
      "stock": 8,
      "active": true,
      "imgGrad": const [Color(0xFF080D14), Color(0xFF1A2540)],
      "ico": "🥗"
    },
    {
      "id": 4,
      "name": "Brochettes bœuf",
      "desc": "Bœuf mariné, oignons, poivrons grillés",
      "price": 14.50,
      "cat": "Viandes",
      "stock": 2,
      "active": true,
      "imgGrad": const [Color(0xFF140A0A), Color(0xFF2A1010)],
      "ico": "🍖"
    },
    {
      "id": 5,
      "name": "Poulet boucané",
      "desc": "Poulet fumé à la boucane, sauce ti malice maison",
      "price": 12.90,
      "cat": "Viandes",
      "stock": "∞",
      "active": false,
      "imgGrad": const [Color(0xFF0A100A), Color(0xFF182518)],
      "ico": "🍗"
    },
    {
      "id": 6,
      "name": "Jus de fruit frais",
      "desc": "Maracuja, goyave ou ananas — fait maison",
      "price": 2.50,
      "cat": "Boissons",
      "stock": "∞",
      "active": true,
      "imgGrad": const [Color(0xFF0D0A14), Color(0xFF1E1830)],
      "ico": "🧃"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              width: 200,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: AppTheme.cream, fontSize: 13, fontFamily: 'Plus Jakarta Sans'),
                decoration: const InputDecoration(
                  icon: Text("🔍", style: TextStyle(fontSize: 14)),
                  hintText: "Rechercher...",
                  hintStyle: TextStyle(color: AppTheme.muted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filterCat,
                  dropdownColor: AppTheme.surface2,
                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.muted),
                  style: const TextStyle(color: AppTheme.cream, fontSize: 13, fontFamily: 'Plus Jakarta Sans'),
                  items: ["Toutes les catégories", "Viandes", "Pasta", "Poissons", "Boissons", "Desserts"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _filterCat = val);
                  },
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                ProductAdminModal.show(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text("+ Nouveau produit", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        
        // Grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              int cols = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
              
              var list = products.where((p) {
                if (_filterCat != "Toutes les catégories" && p["cat"] != _filterCat) return false;
                if (_searchCtrl.text.isNotEmpty && !p["name"].toString().toLowerCase().contains(_searchCtrl.text.toLowerCase())) return false;
                return true;
              }).toList();

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  return _buildProductCard(list[i]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    bool active = p["active"];
    String stockText = "";
    Color stockColor = AppTheme.greenXl;

    if (p["stock"] == "∞") {
      stockText = "∞ En stock";
    } else if (p["stock"] <= 0) {
      stockText = "Épuisé";
      stockColor = AppTheme.redL;
    } else if (p["stock"] <= 3) {
      stockText = "Plus que ${p["stock"]}";
      stockColor = const Color(0xFFFFB347);
    } else {
      stockText = "${p["stock"]} en stock";
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image/Header
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: p["imgGrad"]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Stack(
                children: [
                  Center(child: Text(p["ico"], style: const TextStyle(fontSize: 44))),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => p["active"] = !p["active"]);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 18,
                        decoration: BoxDecoration(
                          color: active ? AppTheme.green : AppTheme.surface3,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: active ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF080D09).withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(p["cat"], style: const TextStyle(color: AppTheme.muted2, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // Body
          Container(
            padding: const EdgeInsets.all(12),
            child: Opacity(
              opacity: active ? 1.0 : 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p["name"], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(p["desc"], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${(p["price"] as double).toStringAsFixed(2).replaceAll('.', ',')}€", style: const TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.greenXl)),
                      Text(stockText, style: TextStyle(color: stockColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(height: 1, color: AppTheme.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(border: Border.all(color: AppTheme.border2), borderRadius: BorderRadius.circular(7)),
                          child: const Center(child: Text("✏️ Modifier", style: TextStyle(color: AppTheme.muted2, fontSize: 12, fontWeight: FontWeight.w600))),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(border: Border.all(color: AppTheme.border2), borderRadius: BorderRadius.circular(7)),
                          child: const Center(child: Text("🗑 Supprimer", style: TextStyle(color: AppTheme.muted2, fontSize: 12, fontWeight: FontWeight.w600))),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
