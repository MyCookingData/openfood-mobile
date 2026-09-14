import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class RefuseModalMobile extends StatefulWidget {
  final String orderId;
  final Function(String) onConfirm;

  const RefuseModalMobile({super.key, required this.orderId, required this.onConfirm});

  static Future<void> show(BuildContext context, String orderId, Function(String) onConfirm) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RefuseModalMobile(orderId: orderId, onConfirm: onConfirm),
    );
  }

  @override
  State<RefuseModalMobile> createState() => _RefuseModalMobileState();
}

class _RefuseModalMobileState extends State<RefuseModalMobile> {
  String? _selectedReason;
  
  final List<String> _reasons = [
    "🚫 Rupture de stock",
    "⏰ Trop de commandes en cours",
    "🔒 Restaurant fermé",
    "⚠️ Problème technique"
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.border2),
      ),
      padding: EdgeInsets.fromLTRB(22, 22, 22, MediaQuery.of(context).padding.bottom + 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AppTheme.surface3, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text("Refuser la commande", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.redL)),
          const SizedBox(height: 4),
          const Text("Le client sera remboursé automatiquement. Choisissez une raison :", style: TextStyle(color: AppTheme.muted, fontSize: 13)),
          const SizedBox(height: 18),
          
          ..._reasons.map((r) {
            bool isSel = _selectedReason == r;
            return GestureDetector(
              onTap: () => setState(() => _selectedReason = r),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: isSel ? AppTheme.redL.withValues(alpha: 0.10) : AppTheme.surface2,
                  border: Border.all(color: isSel ? AppTheme.redL : AppTheme.border, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(r, style: TextStyle(color: isSel ? AppTheme.redL : AppTheme.cream, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            );
          }),
          
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              if (_selectedReason == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez choisir une raison"), backgroundColor: Color(0xFFFFB347)));
                return;
              }
              widget.onConfirm(widget.orderId);
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: AppTheme.red, borderRadius: BorderRadius.circular(18)),
              child: const Center(child: Text("Confirmer le refus", style: TextStyle(fontFamily: 'Bricolage Grotesque', color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border2, width: 1.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(child: Text("Annuler", style: TextStyle(color: AppTheme.muted2, fontSize: 14, fontWeight: FontWeight.w600))),
            ),
          ),
        ],
      ),
    );
  }
}
