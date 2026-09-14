import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Upgrade Alert
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7B2FBE).withValues(alpha: 0.15),
                  const Color(0xFFA855F7).withValues(alpha: 0.08)
                ],
              ),
              border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("🚀", style: TextStyle(fontSize: 28)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Vos ventes ont augmenté de +18% ce mois !",
                            style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFA855F7)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Les restaurants Élite gagnent en moyenne 340€/mois de plus. Passez à Élite pour 79€/mois et débloquez les push géolocalisés, 5 POS et des campagnes marketing.",
                            style: TextStyle(color: AppTheme.muted2, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF7B2FBE), Color(0xFFA855F7)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("Passer à Élite →", style: TextStyle(color: Colors.white, fontFamily: 'Bricolage Grotesque', fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),

          // Stat Grid
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = constraints.maxWidth > 900 ? 4 : 2;
              double ratio = constraints.maxWidth > 900 ? 1.8 : (constraints.maxWidth < 450 ? 0.75 : 1.1);
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: ratio,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                children: const [
                  _StatCard(ico: "💰", val: "2 847€", label: "CA ce mois", trend: "↑ +18% vs mois dernier", color: AppTheme.greenXl),
                  _StatCard(ico: "📦", val: "196", label: "Commandes ce mois", trend: "↑ +24 vs mois dernier", color: AppTheme.gold),
                  _StatCard(ico: "🛒", val: "14,5€", label: "Panier moyen", trend: "= Stable", color: Color(0xFFF5820A), isNeutral: true),
                  _StatCard(ico: "⭐", val: "4.8", label: "Note moyenne", trend: "↑ +0.2 ce mois", color: Color(0xFFA855F7)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Charts & Bestsellers
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 900;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isWide ? 2 : 0,
                    child: Container(
                      height: 320,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Chiffre d'affaires", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 15, fontWeight: FontWeight.w700)),
                          const Text("Évolution sur la période", style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _buildPeriodTab("7 jours", true),
                              _buildPeriodTab("30 jours", false),
                              _buildPeriodTab("3 mois", false),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Expanded(child: _RevenueChart()),
                        ],
                      ),
                    ),
                  ),
                  if (isWide) const SizedBox(width: 14),
                  if (!isWide) const SizedBox(height: 14),
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("⭐ Bestsellers", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 15, fontWeight: FontWeight.w700)),
                          Text("Ce mois · par commandes", style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                          SizedBox(height: 18),
                          _BestsellerRow(rank: 1, ico: "🥩", name: "Colombo de porc", orders: 47, rev: "654,30€", pct: 1.0, color: AppTheme.gold),
                          _BestsellerRow(rank: 2, ico: "🍝", name: "Pasta Carbonara", orders: 31, rev: "368,90€", pct: 0.66, color: AppTheme.muted2),
                          _BestsellerRow(rank: 3, ico: "🥗", name: "Bowl créole", orders: 22, rev: "275,00€", pct: 0.47, color: Color(0xFFFFB347)),
                          _BestsellerRow(rank: 4, ico: "🍖", name: "Brochettes bœuf", orders: 18, rev: "261,00€", pct: 0.38, color: AppTheme.muted),
                          _BestsellerRow(rank: 5, ico: "🍗", name: "Poulet boucané", orders: 14, rev: "180,60€", pct: 0.30, color: AppTheme.muted),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Commandes récentes
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppTheme.greenXl, shape: BoxShape.circle), margin: const EdgeInsets.only(right: 6)),
                      const Text("Commandes en cours", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface2,
                      border: Border.all(color: AppTheme.border2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("Voir toutes →", style: TextStyle(color: AppTheme.cream, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String text, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppTheme.green : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: active ? Colors.white : AppTheme.muted2, fontSize: 12, fontWeight: FontWeight.w600)),
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
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: actionColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(action, style: TextStyle(color: actionColor == AppTheme.surface3 ? AppTheme.muted : Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String ico;
  final String val;
  final String label;
  final String trend;
  final Color color;
  final bool isNeutral;

  const _StatCard({required this.ico, required this.val, required this.label, required this.trend, required this.color, this.isNeutral = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.06), shape: BoxShape.circle),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ico, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(trend, textAlign: TextAlign.right, style: TextStyle(color: isNeutral ? AppTheme.muted2 : color, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Spacer(),
              Text(val, style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 26, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
              const SizedBox(height: 3),
              Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BestsellerRow extends StatelessWidget {
  final int rank;
  final String ico;
  final String name;
  final int orders;
  final String rev;
  final double pct;
  final Color color;

  const _BestsellerRow({required this.rank, required this.ico, required this.name, required this.orders, required this.rev, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(rank.toString(), textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ),
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(ico, style: const TextStyle(fontSize: 22))),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text("$orders commandes", style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 80,
                height: 4,
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: AppTheme.surface3,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.greenXl),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text("${(pct*100).toInt()}%", style: const TextStyle(color: AppTheme.greenXl, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text(rev, style: const TextStyle(color: AppTheme.cream, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Graphique fl_chart basique
class _RevenueChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: AppTheme.muted, fontSize: 10, fontFamily: 'Plus Jakarta Sans');
                String text = '';
                switch (value.toInt()) {
                  case 0: text = 'Lun'; break;
                  case 1: text = 'Mar'; break;
                  case 2: text = 'Mer'; break;
                  case 3: text = 'Jeu'; break;
                  case 4: text = 'Ven'; break;
                  case 5: text = 'Sam'; break;
                  case 6: text = 'Dim'; break;
                }
                return SideTitleWidget(meta: meta, space: 10, child: Text(text, style: style));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 100,
        maxY: 450,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 180),
              FlSpot(1, 240),
              FlSpot(2, 195),
              FlSpot(3, 310),
              FlSpot(4, 347),
              FlSpot(5, 420),
              FlSpot(6, 290),
            ],
            isCurved: false, // Polyline selon le design
            color: AppTheme.greenXl,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: AppTheme.greenXl,
                strokeWidth: 2,
                strokeColor: AppTheme.bg,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AppTheme.greenXl.withValues(alpha: 0.25), AppTheme.greenXl.withValues(alpha: 0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
