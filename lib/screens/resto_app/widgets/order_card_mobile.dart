import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'package:openfood_models/openfood_models.dart';
import 'refuse_modal_mobile.dart';
import 'accept_modal_mobile.dart';

class OrderCardMobile extends StatefulWidget {
  final OrderModel order;
  final Function(String orderId, int newStatus, {int? prepTimeMinutes}) onStatusChange;
  final Function(String) onRefuse;

  const OrderCardMobile({
    super.key,
    required this.order,
    required this.onStatusChange,
    required this.onRefuse,
  });

  @override
  State<OrderCardMobile> createState() => _OrderCardMobileState();
}

class _OrderCardMobileState extends State<OrderCardMobile> {
  late Timer _timer;
  late int _elapsedSeconds;
  
  @override
  void initState() {
    super.initState();
    // Start timing from createdAt
    _elapsedSeconds = DateTime.now().difference(widget.order.createdAt).inSeconds;
    
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (widget.order.status < 3) {
        if (mounted) {
           setState(() {
              _elapsedSeconds = DateTime.now().difference(widget.order.createdAt).inSeconds;
           });
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.order.status) {
      case 0: return const Color(0xFFF5820A).withValues(alpha: 0.5); // Nouvelle
      case 1: return const Color(0xFF1A6EBF).withValues(alpha: 0.3); // Préparation
      case 2: return const Color(0xFF1E8B3A).withValues(alpha: 0.4); // Prête
      case 3: return AppTheme.border; // En route / livrée
      default: return AppTheme.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    int elapsedMins = _elapsedSeconds ~/ 60;
    
    // Si prepTimeMinutes est renseigné, on l'utilise, sinon 35 min par défaut.
    double maxSeconds = (widget.order.prepTimeMinutes ?? 35) * 60.0; 
    double pct = (_elapsedSeconds / maxSeconds).clamp(0.0, 1.0);
    
    // Timer colors
    Color timerColor;
    LinearGradient timerGrad;
    if (elapsedMins < 20) {
      timerColor = AppTheme.greenXl;
      timerGrad = const LinearGradient(colors: [AppTheme.green, AppTheme.greenXl]);
    } else if (elapsedMins < 30) {
      timerColor = const Color(0xFFFFB347);
      timerGrad = const LinearGradient(colors: [Color(0xFFF5820A), Color(0xFFFFB347)]);
    } else {
      timerColor = AppTheme.redL;
      timerGrad = const LinearGradient(colors: [AppTheme.red, AppTheme.redL]);
    }

    // Status Badge
    String badgeLabel = "";
    Color badgeColor = Colors.transparent;
    switch (widget.order.status) {
      case 0: badgeLabel = "🔴 Nouvelle"; badgeColor = const Color(0xFFFFB347); break;
      case 1: badgeLabel = "🔵 En préparation"; badgeColor = const Color(0xFF2E8FE8); break;
      case 2: badgeLabel = "🟢 Prête au retrait"; badgeColor = AppTheme.greenXl; break;
      case 3: badgeLabel = "✓ En livraison"; badgeColor = AppTheme.muted; break;
      case 4: badgeLabel = "✓ Livrée"; badgeColor = AppTheme.muted; break;
    }

    // On force 'delivery' pour le MVP
    // Pas de ternaires pour éviter le Dead Code Lint

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: _getStatusColor(), width: widget.order.status == 0 ? 1.5 : 1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Commande #${widget.order.id.substring(0, 5).toUpperCase()}", style: const TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text("Il y a $elapsedMins min", style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E8B3A).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text("🛵 Livraison", style: TextStyle(color: AppTheme.greenXl, fontSize: 10, fontWeight: FontWeight.w700)),
                        )
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.order.status >= 3 ? AppTheme.surface2 : badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(badgeLabel, style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w700)),
                )
              ],
            ),
          ),

          // Timer Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Stack(
                        children: [
                          Container(color: AppTheme.surface3),
                          AnimatedContainer(
                            duration: const Duration(seconds: 1),
                            curve: Curves.linear,
                            width: MediaQuery.of(context).size.width * pct, // Roughly percentage of screen since Expanded
                            decoration: BoxDecoration(gradient: timerGrad, borderRadius: BorderRadius.circular(99)),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Text("$elapsedMins min", textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 13, fontWeight: FontWeight.w700, color: timerColor)),
                )
              ],
            ),
          ),

          // Client
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border))),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.green, Color(0xFF145C26)]),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text("C", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 14, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Client (ID: ${widget.order.userId.substring(0,4)})", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(widget.order.deliveryAddress ?? "Sur place", style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                    ],
                  ),
                ),
                const Text("📞", style: TextStyle(fontSize: 20)),
              ],
            ),
          ),

          if (widget.order.driverId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border))),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: const BoxDecoration(
                      color: AppTheme.surface3,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: Text("🛵", style: TextStyle(fontSize: 16))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.order.driverName ?? "Livreur", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text(widget.order.driverPhone ?? "Téléphone inconnu", style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.phone, color: AppTheme.muted2, size: 20),
                ],
              ),
            ),

          // Items
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border))),
            child: Column(
              children: widget.order.items.map((it) {
                final num qty = it['qty'] ?? 1;
                final num price = it['price'] ?? it['priceHT'] ?? 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(6)),
                        child: Center(child: Text("$qty", style: const TextStyle(color: AppTheme.greenXl, fontSize: 11, fontWeight: FontWeight.w800))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: AppTheme.cream, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Plus Jakarta Sans'),
                            children: [
                              TextSpan(text: it['name'] ?? 'Produit inconnu'),
                            ],
                          ),
                        ),
                      ),
                      Text("${(price * qty).toStringAsFixed(2).replaceAll('.', ',')}€", style: const TextStyle(color: AppTheme.muted2, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E8B3A).withValues(alpha: 0.04),
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total commande", style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                Text("${widget.order.totalAmount.toStringAsFixed(2).replaceAll('.', ',')}€", style: const TextStyle(fontFamily: 'Bricolage Grotesque', color: AppTheme.greenXl, fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),

          // Actions
          if (widget.order.status < 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border))),
              child: _buildActionsRow(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionsRow() {
    int status = widget.order.status;

    if (status == 0) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                AcceptModalMobile.show(context, widget.order.id, widget.onStatusChange);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.green, Color(0xFF145C26)]), borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text("✓ Accepter", style: TextStyle(fontFamily: 'Bricolage Grotesque', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              RefuseModalMobile.show(context, widget.order.id, widget.onRefuse);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
              decoration: BoxDecoration(border: Border.all(color: AppTheme.border2, width: 1.5), borderRadius: BorderRadius.circular(14)),
              child: const Text("✕ Refuser", style: TextStyle(fontFamily: 'Bricolage Grotesque', color: AppTheme.redL, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    } else if (status == 1) {
      return GestureDetector(
        onTap: () => widget.onStatusChange(widget.order.id, 2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A6EBF), Color(0xFF2E8FE8)]), borderRadius: BorderRadius.circular(14)),
          child: const Center(child: Text("🛎️ Marquer comme prête", style: TextStyle(fontFamily: 'Bricolage Grotesque', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
        ),
      );
    } else if (status == 2) {
      bool hasDriver = widget.order.driverId != null;
      return GestureDetector(
        onTap: hasDriver ? () => widget.onStatusChange(widget.order.id, 3) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: hasDriver ? const LinearGradient(colors: [Color(0xFF1A6EBF), Color(0xFF2E8FE8)]) : null,
            color: hasDriver ? null : AppTheme.surface2, 
            borderRadius: BorderRadius.circular(14)
          ),
          child: Center(
            child: Text(
              hasDriver ? "🚚 Remettre au livreur" : "En attente d'un livreur", 
              style: TextStyle(
                fontFamily: 'Bricolage Grotesque', 
                color: hasDriver ? Colors.white : AppTheme.muted2, 
                fontSize: 14, 
                fontWeight: FontWeight.w700
              )
            )
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
