import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'package:openfood_models/openfood_models.dart';
import '../utils/cart_handler.dart';

class UpsellModal extends StatefulWidget {
  final String productName;
  final String restaurantId;
  final String? restaurantName;

  const UpsellModal({super.key, required this.productName, this.restaurantId = 'Open Food · 30 min', this.restaurantName});

  static void show(BuildContext context, {required String productName, String restaurantId = 'Open Food · 30 min', String? restaurantName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpsellModal(productName: productName, restaurantId: restaurantId, restaurantName: restaurantName),
    );
  }

  @override
  State<UpsellModal> createState() => _UpsellModalState();
}

class _UpsellModalState extends State<UpsellModal> {
  final List<Map<String, dynamic>> _upsells = [
    {'ico': '🧃', 'name': 'Jus de fruit frais', 'price': 2.50, 'added': false},
    {'ico': '🍟', 'name': 'Frites maison', 'price': 3.00, 'added': false},
    {'ico': '🍮', 'name': 'Dessert du jour', 'price': 2.00, 'added': false},
  ];

  void _addUpsell(int index) {
    if (_upsells[index]['added']) return; // already added
    
    setState(() {
      _upsells[index]['added'] = true;
    });
    
    CartHandler.addItem(
      context,
      CartItem(
        id: _upsells[index]['name'].toString().replaceAll(' ', '_').toLowerCase(),
        name: _upsells[index]['name'],
        priceHT: (_upsells[index]['price'] is double ? _upsells[index]['price'] : (_upsells[index]['price'] as int).toDouble()) / 1.021,
        category: 'Extra',
        restaurantId: widget.restaurantId, 
        restaurantName: widget.restaurantName,
      ),
      onSuccess: () {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            Navigator.pop(context); // Auto-close
          }
        });
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 44),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.border2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppTheme.surface3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          RichText(
            text: TextSpan(
              style: AppTheme.titleStyle.copyWith(fontSize: 17),
              children: [
                const TextSpan(text: "🤝 Souvent commandé avec "),
                TextSpan(text: widget.productName, style: const TextStyle(color: AppTheme.greenXl)),
              ],
            ),
          ),
          const SizedBox(height: 3),
          const Text("Ajoutez quelque chose ?", style: TextStyle(color: AppTheme.muted, fontSize: 12)),
          const SizedBox(height: 16),
          
          ...List.generate(_upsells.length, (index) {
            final u = _upsells[index];
            bool added = u['added'];
            return GestureDetector(
              onTap: () => _addUpsell(index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: added ? AppTheme.border2 : AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(u['ico'], style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 10),
                        Text(u['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      children: [
                        Text("${u['price'].toStringAsFixed(2).replaceAll('.', ',')}€", style: const TextStyle(color: AppTheme.greenXl, fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 10),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: added ? const Color(0xFF2ECC71) : AppTheme.green,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: added
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : const Text("+", style: TextStyle(color: Colors.white, fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(12),
              side: BorderSide(color: AppTheme.border2, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text("Non merci, continuer", style: TextStyle(color: AppTheme.muted2, fontWeight: FontWeight.w600, fontSize: 14)),
          )
        ],
      ),
    );
  }
}
