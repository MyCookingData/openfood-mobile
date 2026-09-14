import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class AcceptModalMobile extends StatefulWidget {
  final String orderId;
  final Function(String orderId, int newStatus, {int? prepTimeMinutes}) onAccept;

  const AcceptModalMobile({
    super.key,
    required this.orderId,
    required this.onAccept,
  });

  static void show(BuildContext context, String orderId, Function(String, int, {int? prepTimeMinutes}) onAccept) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AcceptModalMobile(orderId: orderId, onAccept: onAccept),
    );
  }

  @override
  State<AcceptModalMobile> createState() => _AcceptModalMobileState();
}

class _AcceptModalMobileState extends State<AcceptModalMobile> {
  int? _selectedTime;
  final TextEditingController _customTimeController = TextEditingController();

  void _confirm() {
    int prepTime = _selectedTime ?? 30; // 30 min par défaut
    if (_selectedTime == -1) {
      prepTime = int.tryParse(_customTimeController.text) ?? 30;
    }
    widget.onAccept(widget.orderId, 1, prepTimeMinutes: prepTime);
    Navigator.pop(context);
  }

  Widget _buildTimeOption(String label, int value) {
    bool isSelected = _selectedTime == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTime = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.greenXl.withValues(alpha: 0.15) : AppTheme.surface3,
          border: Border.all(color: isSelected ? AppTheme.greenXl : AppTheme.border2, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Bricolage Grotesque',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppTheme.greenXl : AppTheme.cream,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Accepter la commande",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.cream),
          ),
          const SizedBox(height: 8),
          const Text(
            "Indiquez le temps estimé pour préparer cette commande. Le client et le livreur seront notifiés.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(child: _buildTimeOption("15 min", 15)),
              const SizedBox(width: 10),
              Expanded(child: _buildTimeOption("30 min", 30)),
              const SizedBox(width: 10),
              Expanded(child: _buildTimeOption("45 min", 45)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTimeOption("Autre durée", -1),
          
          if (_selectedTime == -1) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customTimeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.cream, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surface3,
                hintText: "Minutes (ex: 60)",
                hintStyle: const TextStyle(color: AppTheme.muted2, fontWeight: FontWeight.normal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.greenXl,
              foregroundColor: AppTheme.bg,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _selectedTime == null ? null : _confirm,
            child: const Text("Confirmer l'acceptation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
