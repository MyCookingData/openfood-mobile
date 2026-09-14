import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../widgets/order_card.dart';
import 'package:openfood_models/openfood_models.dart';
import '../services/order_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersScreen extends StatelessWidget {
  final VoidCallback? onBackToHome;
  const OrdersScreen({super.key, this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent, // Background handled by MainWrapper
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Mes Commandes", style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_downward, color: AppTheme.cream),
              onPressed: () {
                if (onBackToHome != null) {
                  onBackToHome!();
                } else {
                  Navigator.of(context).pop();
                }
              },
            )
          ],
          bottom: const TabBar(
            indicatorColor: AppTheme.greenXl,
            labelColor: AppTheme.greenXl,
            unselectedLabelColor: AppTheme.muted2,
            indicatorWeight: 3,
            tabs: [
               Tab(text: "En cours"),
               Tab(text: "Historique"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Tab: En Cours
            _OngoingOrdersView(),
            
            // Tab: Historique
            _HistoricalOrdersView(),
          ],
        ),
      ),
    );
  }
}


class _OngoingOrdersView extends StatelessWidget {
  const _OngoingOrdersView();

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Center(child: Text("Merci de vous connecter pour voir vos commandes.", style: TextStyle(color: AppTheme.muted2)));
    }
  
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.getUserOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.green));
        }
        
        final ongoingOrders = (snapshot.data ?? []).where((o) => o.status < 3).toList();
        if (ongoingOrders.isEmpty) return const Center(child: Text("Aucune commande en cours.", style: TextStyle(color: AppTheme.muted2)));
        
        return _OrdersScreenStateMixin()._buildList(ongoingOrders);
      },
    );
  }
}

class _HistoricalOrdersView extends StatelessWidget {
  const _HistoricalOrdersView();

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Center(child: Text("Merci de vous connecter pour voir votre historique.", style: TextStyle(color: AppTheme.muted2)));
    }

    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.getUserOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator(color: AppTheme.green));
        }
        
        final historicalOrders = (snapshot.data ?? []).where((o) => o.status >= 3).toList();
        if (historicalOrders.isEmpty) return const Center(child: Text("Votre historique est vide.", style: TextStyle(color: AppTheme.muted2)));

        return _OrdersScreenStateMixin()._buildList(historicalOrders);
      },
    );
  }
}

class _OrdersScreenStateMixin {
  OrderStatus _mapStatus(int statusInt) {
    switch (statusInt) {
      case 0: return OrderStatus.pending;
      case 1: return OrderStatus.preparing;
      case 2: return OrderStatus.delivering;
      case 3: return OrderStatus.completed;
      case 4: return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      // Formatted "Aujourd'hui, 19:40"
      return "Aujourd'hui, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Widget _buildList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Text("Aucune commande", style: TextStyle(color: AppTheme.muted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final summary = order.items.map((e) => "${e['quantity']}x ${e['name']}").toList();

        return OrderCard(
          orderId: order.id,
          restaurantName: order.restaurantName,
          date: _formatDate(order.createdAt),
          totalAmount: order.totalAmount,
          status: _mapStatus(order.status),
          itemsSummary: summary,
        ).animate().fade(duration: 400.ms, delay: (index * 50).ms).slideY(begin: 0.1, curve: Curves.easeOut);
      },
    );
  }
}
