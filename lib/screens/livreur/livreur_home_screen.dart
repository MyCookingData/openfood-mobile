import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'views/livreur_dashboard_view.dart';
import 'views/livreur_history_view.dart';
import 'views/livreur_profile_view.dart';
import 'views/livreur_map_view.dart';

class LivreurHomeScreen extends StatefulWidget {
  const LivreurHomeScreen({super.key});

  @override
  State<LivreurHomeScreen> createState() => _LivreurHomeScreenState();
}

class _LivreurHomeScreenState extends State<LivreurHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const LivreurDashboardView(),
    const LivreurMapView(),
    const LivreurHistoryView(),
    const LivreurProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF080D09).withValues(alpha: 0.97),
          border: Border(top: BorderSide(color: AppTheme.border2)),
        ),
        padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, "📋", "Courses"),
            _buildNavItem(1, "🗺️", "Carte"),
            _buildNavItem(2, "💰", "Gains"),
            _buildNavItem(3, "👤", "Profil"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: 22, color: isSelected ? AppTheme.greenXl : AppTheme.muted)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppTheme.greenXl : AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}
