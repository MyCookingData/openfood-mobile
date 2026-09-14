import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'package:openfood_models/openfood_models.dart';
import '../../../services/order_service.dart';
import '../widgets/order_card_mobile.dart';

class OrdersMobileView extends StatefulWidget {
  const OrdersMobileView({super.key});

  @override
  State<OrdersMobileView> createState() => _OrdersMobileViewState();
}

class _OrdersMobileViewState extends State<OrdersMobileView> {
  // -1 = Toutes, 0 = Nouvelles, 1 = En prépa, 2 = Prêtes, 3 = Livrées
  int _activeFilter = -1;

  void _changeStatus(String orderId, int newStatus, {int? prepTimeMinutes}) {
    OrderService.updateOrderStatus(orderId, newStatus, prepTimeMinutes);
  }

  void _refuseOrder(String orderId) {
    OrderService.updateOrderStatus(orderId, 4); // 4 = Annulé / Refusé
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      // On récupère toutes les commandes pour ce pilote au lieu de filtrer par "Kay Dada"
      stream: OrderService.getAllOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.greenXl)));
        }

        final orders = snapshot.data ?? [];
        
        // Comptage dynamique
        int all = orders.where((o) => o.status != 4).length; // On n'affiche pas vraiment les annulées dans All
        int nouvelle = orders.where((o) => o.status == 0).length;
        int prep = orders.where((o) => o.status == 1).length;
        int prete = orders.where((o) => o.status == 2).length;
        int livree = orders.where((o) => o.status >= 3 && o.status != 4).length;
        
        var counts = {'all': all, 'nouvelle': nouvelle, 'preparation': prep, 'prete': prete, 'livree': livree};

        // Filtrage
        List<OrderModel> filteredOrders = [];
        if (_activeFilter == -1) {
          filteredOrders = orders.where((o) => o.status != 4).toList();
        } else if (_activeFilter >= 3) {
          filteredOrders = orders.where((o) => o.status >= 3 && o.status != 4).toList();
        } else {
          filteredOrders = orders.where((o) => o.status == _activeFilter).toList();
        }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Daily Summary
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.border2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("📊 Aujourd'hui · Vendredi 27 mars", style: TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDailyStat("347€", "Chiffre d'affaires", "↑ +18% vs hier", AppTheme.greenXl),
                    _buildDailyStat("24", "Commandes", "↑ +6 vs hier", AppTheme.gold),
                    _buildDailyStat("14,5€", "Panier moyen", "= stable", const Color(0xFFFFB347)),
                  ],
                ),
              ],
            ),
          ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterTab(-1, "Toutes", counts['all']!),
                _buildFilterTab(0, "🔴 Nouvelles", counts['nouvelle']!),
                _buildFilterTab(1, "🔵 En prépa", counts['preparation']!),
                _buildFilterTab(2, "🟢 Prêtes", counts['prete']!),
                _buildFilterTab(3, "✓ Liées/Livrées", counts['livree']!),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Orders List
          if (filteredOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Text("🎉", style: TextStyle(fontSize: 56)),
                  SizedBox(height: 4),
                  Text("Tout est à jour !", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text("Aucune commande dans cette catégorie pour le moment.", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.5)),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredOrders.length,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: OrderCardMobile(
                    order: filteredOrders[i],
                    onStatusChange: _changeStatus,
                    onRefuse: _refuseOrder,
                  ),
                );
              },
            ),
        ],
      ),
    );
    });
  }

  Widget _buildDailyStat(String val, String label, String trend, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 22, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(trend, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildFilterTab(int id, String label, int count) {
    bool active = _activeFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppTheme.green : AppTheme.surface,
          border: Border.all(color: active ? AppTheme.green : AppTheme.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: active ? Colors.white : AppTheme.muted2, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: active ? Colors.white.withValues(alpha: 0.2) : AppTheme.surface2,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(count.toString(), style: TextStyle(color: active ? Colors.white : AppTheme.muted2, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
