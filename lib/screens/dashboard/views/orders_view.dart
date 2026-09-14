import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  String _filter = "Tous les statuts";

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppTheme.greenXl, shape: BoxShape.circle), margin: const EdgeInsets.only(right: 6)),
                const Text("Toutes les commandes", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filter,
                  dropdownColor: AppTheme.surface2,
                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.muted),
                  style: const TextStyle(color: AppTheme.cream, fontSize: 13, fontFamily: 'Plus Jakarta Sans'),
                  items: ["Tous les statuts", "Nouvelles", "En préparation", "Prêtes", "Livrées"]
                      .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (String? val) {
                    if (val != null) setState(() => _filter = val);
                  },
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.7),
                child: DataTable(
                  columnSpacing: 30,
                  headingRowColor: WidgetStateProperty.all(AppTheme.surface2),
                  columns: const [
                    DataColumn(label: Text("N°", style: TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700))),
                    DataColumn(label: Text("Client", style: TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700))),
                    DataColumn(label: Text("Statut", style: TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700))),
                    DataColumn(label: Text("Montant", style: TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700))),
                    DataColumn(label: Text("Heure", style: TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700))),
                    DataColumn(label: Text("Action", style: TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700))),
                  ],
                  rows: [
                    _buildOrderRow("#042", "Evans M.", "Colombo x1, Jus x2", "Nouvelle", const Color(0xFFFFB347), 30.80, "Il y a 2 min", "Accepter", AppTheme.green),
                    _buildOrderRow("#041", "Marie C.", "Bowl créole x1", "En préparation", const Color(0xFF2E8FE8), 14.00, "Il y a 14 min", "Prête", const Color(0xFF2E8FE8)),
                    _buildOrderRow("#040", "Jean-Louis P.", "Brochettes x2, Jus x1", "Prête", AppTheme.greenXl, 31.50, "Il y a 28 min", "Livrée", AppTheme.surface3),
                    _buildOrderRow("#039", "Sophie R.", "Poulet boucané x1", "Livrée", AppTheme.surface3, 12.90, "Il y a 45 min", "Terminée", Colors.transparent),
                    _buildOrderRow("#038", "Lucas V.", "Pasta Carbonara x2", "Livrée", AppTheme.surface3, 23.80, "Il y a 1h", "Terminée", Colors.transparent),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildOrderRow(String id, String name, String items, String status, Color statusColor, double amount, String time, String action, Color actionColor) {
    return DataRow(
      cells: [
        DataCell(Text(id, style: const TextStyle(fontFamily: 'Bricolage Grotesque', fontWeight: FontWeight.w700))),
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(items, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
          ],
        )),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
        )),
        DataCell(Text("${amount.toStringAsFixed(2).replaceAll('.', ',')}€", style: const TextStyle(fontFamily: 'Bricolage Grotesque', color: AppTheme.greenXl, fontWeight: FontWeight.w700))),
        DataCell(Text(time, style: const TextStyle(color: AppTheme.muted, fontSize: 12))),
        DataCell(
          action == "Terminée"
              ? const Text("Terminée", style: TextStyle(color: AppTheme.muted, fontSize: 11))
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: actionColor, borderRadius: BorderRadius.circular(6)),
                  child: Text(action, style: TextStyle(color: actionColor == AppTheme.surface3 ? AppTheme.muted : Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
        ),
      ],
    );
  }
}
