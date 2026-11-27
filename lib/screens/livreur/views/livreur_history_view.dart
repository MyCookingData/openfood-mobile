import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:openfood_models/openfood_models.dart';
import '../../../core/theme.dart';
import '../../../utils/string_extensions.dart';
import 'package:intl/intl.dart';

class LivreurHistoryView extends StatefulWidget {
  const LivreurHistoryView({super.key});

  @override
  State<LivreurHistoryView> createState() => _LivreurHistoryViewState();
}

class _LivreurHistoryViewState extends State<LivreurHistoryView> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final driverId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_driver';
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Gains & Historique", style: TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Date Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppTheme.muted),
                  onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
                ),
                Text(
                  DateFormat('EEEE d MMMM yyyy', 'fr').format(_selectedDate).toUpperCase(),
                  style: const TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppTheme.muted),
                  onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('driverId', isEqualTo: driverId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.greenXl));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: AppTheme.red)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Aucune course pour cette date.", style: TextStyle(color: AppTheme.muted)));
                }

                final allDocs = snapshot.data!.docs;
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['status'] != 3) return false;
                  final time = (data['deliveredAt'] as Timestamp?) ?? (data['createdAt'] as Timestamp?);
                  if (time == null) return false;
                  final dt = time.toDate();
                  return !dt.isBefore(startOfDay) && dt.isBefore(endOfDay);
                }).toList();
                
                if (docs.isEmpty) {
                  return const Center(child: Text("Aucune course pour cette date.", style: TextStyle(color: AppTheme.muted)));
                }

                // Tri local par date décroissante
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = (aData['deliveredAt'] as Timestamp?) ?? (aData['createdAt'] as Timestamp?);
                  final bTime = (bData['deliveredAt'] as Timestamp?) ?? (bData['createdAt'] as Timestamp?);
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });
                
                final List<OrderModel> dayOrders = docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
                double totalGains = 0;
                int totalCourses = dayOrders.length;
                
                for (var order in dayOrders) {
                  totalGains += DriverPayoutHelper.resolveOrderPayout(order);
                }

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // KPIs
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(color: AppTheme.surface3, borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.all(24),
                              width: double.infinity,
                              child: Column(
                                children: [
                                  const Text("Gains du jour", style: TextStyle(color: AppTheme.muted, fontSize: 14)),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${totalGains.toStringAsFixed(2).replaceAll('.', ',')} €",
                                    style: const TextStyle(color: AppTheme.greenXl, fontSize: 40, fontWeight: FontWeight.bold, fontFamily: 'Bricolage Grotesque'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(color: AppTheme.surface3, borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.local_shipping_outlined, color: Color(0xFF0EA5E9), size: 28),
                                        const SizedBox(height: 8),
                                        Text("$totalCourses", style: const TextStyle(color: AppTheme.cream, fontSize: 24, fontWeight: FontWeight.bold)),
                                        const Text("Courses", style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(color: AppTheme.surface3, borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.timer_outlined, color: AppTheme.gold, size: 28),
                                        const SizedBox(height: 8),
                                        const Text("100%", style: TextStyle(color: AppTheme.cream, fontSize: 24, fontWeight: FontWeight.bold)),
                                        const Text("Taux accept.", style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Titre Historique
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Text("Historique des courses", style: TextStyle(color: AppTheme.cream, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    // Liste
                    docs.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: Text("Aucune course effectuée ce jour.", style: TextStyle(color: AppTheme.muted)),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final order = dayOrders[index];
                                final gain = DriverPayoutHelper.resolveOrderPayout(order);
                                final orderTime = DriverPayoutHelper.effectiveOrderDate(order);
                                
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.border2),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppTheme.surface3,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.check_circle, color: AppTheme.greenXl),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              order.restaurantName.formattedRestaurantName,
                                              style: const TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold, fontSize: 15),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat('HH:mm').format(orderTime),
                                              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "+${gain.toStringAsFixed(2).replaceAll('.', ',')} €",
                                        style: const TextStyle(color: AppTheme.greenXl, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              childCount: dayOrders.length,
                            ),
                          ),
                          
                    const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom Bar padding
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
