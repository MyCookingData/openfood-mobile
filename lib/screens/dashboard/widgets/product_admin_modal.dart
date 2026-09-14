import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class ProductAdminModal extends StatefulWidget {
  const ProductAdminModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: const Color(0xFF040805).withValues(alpha: 0.92),
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(24),
        child: ProductAdminModal(),
      ),
    );
  }

  @override
  State<ProductAdminModal> createState() => _ProductAdminModalState();
}

class _ProductAdminModalState extends State<ProductAdminModal> {
  int _stock = -1; // -1 = infini
  bool _limitStock = false;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 680,
      constraints: const BoxConstraints(maxHeight: 800),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Nouveau produit", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 18, fontWeight: FontWeight.w800)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: AppTheme.surface2, shape: BoxShape.circle),
                    child: const Center(child: Text("×", style: TextStyle(color: AppTheme.muted2, fontSize: 18, fontWeight: FontWeight.bold))),
                  ),
                ),
              ],
            ),
          ),
          
          // Body (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo
                  _buildSectionTitle("Photo"),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border2, style: BorderStyle.none), // Custom dashed border needed in real app
                      borderRadius: BorderRadius.circular(10),
                    ),
                    // Simulated dashed border via CustomPaint or simple border for prototype
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: const Column(
                        children: [
                          Text("📷", style: TextStyle(fontSize: 28)),
                          SizedBox(height: 8),
                          Text("Cliquez pour uploader ou glissez une image ici", style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Infos
                  _buildSectionTitle("Informations"),
                  Row(
                    children: [
                      Expanded(child: _buildInput("Nom du produit *", "Ex : Colombo de porc")),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInput("Description", "Décrivez le plat...", maxLines: 3),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInput("Prix de base (€) *", "0,00")),
                      const SizedBox(width: 16),
                      // Mock Dropdown for Category
                      Expanded(child: _buildInput("Catégorie *", "Viandes", isDropdown: true)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stock
                  _buildSectionTitle("Stock disponible"),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_limitStock && _stock > 0) setState(() => _stock--);
                        },
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: AppTheme.surface2, border: Border.all(color: AppTheme.border2), shape: BoxShape.circle),
                          child: const Center(child: Text("−", style: TextStyle(color: AppTheme.cream, fontSize: 18))),
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(_limitStock ? _stock.toString() : "∞", textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_limitStock) setState(() => _stock++);
                        },
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: AppTheme.surface2, border: Border.all(color: AppTheme.border2), shape: BoxShape.circle),
                          child: const Center(child: Text("+", style: TextStyle(color: AppTheme.cream, fontSize: 18))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text("Laissez ∞ pour illimité", style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _limitStock,
                        activeColor: AppTheme.greenXl,
                        onChanged: (v) {
                          setState(() {
                            _limitStock = v ?? false;
                            if (_limitStock && _stock == -1) _stock = 10;
                          });
                        },
                      ),
                      const Text("Activer la limite de stock", style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("Annuler", style: TextStyle(color: AppTheme.muted2, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.green, Color(0xFF145C26)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("💾 Enregistrer le produit", style: TextStyle(fontFamily: 'Bricolage Grotesque', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: AppTheme.border)),
        ],
      ),
    );
  }

  Widget _buildInput(String label, String hint, {int maxLines = 1, bool isDropdown = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppTheme.muted2, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.surface2,
            border: Border.all(color: AppTheme.border2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isDropdown
              ? DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: hint,
                    isExpanded: true,
                    dropdownColor: AppTheme.surface3,
                    style: const TextStyle(color: AppTheme.cream, fontSize: 13, fontFamily: 'Plus Jakarta Sans'),
                    items: [hint].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) {},
                  ),
                )
              : TextField(
                  maxLines: maxLines,
                  style: const TextStyle(color: AppTheme.cream, fontSize: 13, fontFamily: 'Plus Jakarta Sans'),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: AppTheme.muted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
        ),
      ],
    );
  }
}
