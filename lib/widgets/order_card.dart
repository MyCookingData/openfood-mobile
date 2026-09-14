import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../utils/string_extensions.dart';

enum OrderStatus { pending, preparing, delivering, completed, cancelled }

class OrderCard extends StatelessWidget {
  final String orderId;
  final String restaurantName;
  final String date;
  final double totalAmount;
  final OrderStatus status;
  final List<String> itemsSummary;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.restaurantName,
    required this.date,
    required this.totalAmount,
    required this.status,
    required this.itemsSummary,
    this.onTap,
  });

  String _getStatusText() {
    switch (status) {
      case OrderStatus.pending: return "En attente du restaurant";
      case OrderStatus.preparing: return "En cuisine";
      case OrderStatus.delivering: return "En route vers vous";
      case OrderStatus.completed: return "Livrée";
      case OrderStatus.cancelled: return "Annulée";
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case OrderStatus.pending: return AppTheme.gold;
      case OrderStatus.preparing: return const Color(0xFFF2994A); // Orange
      case OrderStatus.delivering: return AppTheme.greenXl;
      case OrderStatus.completed: return AppTheme.muted2;
      case OrderStatus.cancelled: return AppTheme.red;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case OrderStatus.pending: return Icons.schedule;
      case OrderStatus.preparing: return Icons.restaurant;
      case OrderStatus.delivering: return Icons.moped;
      case OrderStatus.completed: return Icons.check_circle;
      case OrderStatus.cancelled: return Icons.cancel;
    }
  }

  double _getProgress() {
    switch (status) {
      case OrderStatus.pending: return 0.2;
      case OrderStatus.preparing: return 0.5;
      case OrderStatus.delivering: return 0.8;
      case OrderStatus.completed: return 1.0;
      case OrderStatus.cancelled: return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOngoing = status != OrderStatus.completed && status != OrderStatus.cancelled;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOngoing ? AppTheme.green.withValues(alpha: 0.3) : AppTheme.border2,
            width: isOngoing ? 1.5 : 1.0,
          ),
          boxShadow: isOngoing
              ? [BoxShadow(color: AppTheme.green.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isOngoing ? AppTheme.green.withValues(alpha: 0.05) : AppTheme.surface2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(_getStatusIcon(), color: _getStatusColor(), size: 18),
                  const SizedBox(width: 8),
                  Text(_getStatusText(), style: TextStyle(color: _getStatusColor(), fontSize: 13, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(date, style: const TextStyle(color: AppTheme.muted2, fontSize: 12)),
                ],
              ),
            ),
            
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Restaurant Placeholder
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surface3,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text("🍽️", style: TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(restaurantName.formattedRestaurantName, style: const TextStyle(color: AppTheme.cream, fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(itemsSummary.take(2).join(" • ") + (itemsSummary.length > 2 ? " ..." : ""), 
                          style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text("${totalAmount.toStringAsFixed(2).replaceAll('.', ',')} €", style: const TextStyle(color: AppTheme.cream, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  
                  // Chevron
                  const Icon(Icons.chevron_right, color: AppTheme.muted),
                ],
              ),
            ),

            // Progress Bar if ongoing
            if (isOngoing)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _getProgress(),
                        backgroundColor: AppTheme.surface3,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.green),
                        minHeight: 6,
                      ),
                    ),
                    if (status == OrderStatus.delivering)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(6)),
                                  child: const Icon(Icons.directions_car, color: AppTheme.muted, size: 14),
                                ),
                                const SizedBox(width: 8),
                                const Text("Livraison en voiture", style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                              child: const Text("~15 min", style: TextStyle(color: AppTheme.greenXl, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // Button Recommander if past
            if (!isOngoing)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surface3,
                    foregroundColor: AppTheme.cream,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    // TODO: Ré-ajouter au panier
                  },
                  child: const Text("Recommander", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
