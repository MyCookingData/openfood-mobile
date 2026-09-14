import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'views/orders_mobile_view.dart';
import 'widgets/new_order_alert.dart';
import 'views/menu_mobile_view.dart';

class RestoAppScreen extends StatefulWidget {
  const RestoAppScreen({super.key});

  @override
  State<RestoAppScreen> createState() => _RestoAppScreenState();
}

class _RestoAppScreenState extends State<RestoAppScreen> {
  int _currentIndex = 0;
  bool _isOpen = true;

  @override
  void initState() {
    super.initState();
    // Simulate a new order coming in after 5 seconds to show the animated top alert
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        NewOrderAlert.show(context, orderNum: "#043", amount: "15,40€");
      }
    });
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const OrdersMobileView();
      case 1:
        return const MenuMobileView();
      case 2:
        return const Center(child: Text("Stats - En cours", style: TextStyle(color: Colors.white)));
      case 3:
        return const Center(child: Text("Paramètres - En cours", style: TextStyle(color: Colors.white)));
      default:
        return const OrdersMobileView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // Topbar
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.bg, AppTheme.bg.withValues(alpha: 0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.78, 1.0],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                        children: [
                          TextSpan(text: "Open", style: TextStyle(color: AppTheme.cream)),
                          TextSpan(text: "Food", style: TextStyle(color: AppTheme.greenXl)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text("· Espace Resto", style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isOpen = !_isOpen),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          border: Border.all(color: AppTheme.border2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: _isOpen ? AppTheme.greenXl : AppTheme.redL, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 7),
                            Text(_isOpen ? "Ouvert" : "Fermé", style: TextStyle(color: _isOpen ? AppTheme.greenXl : AppTheme.redL, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Back to client app
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.border2), shape: BoxShape.circle),
                            child: const Center(child: Text("🔔", style: TextStyle(fontSize: 16))),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: AppTheme.redL, shape: BoxShape.circle, border: Border.all(color: AppTheme.bg, width: 2)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Main content
          Expanded(child: _buildBody()),
        ],
      ),
      
      // Bottom Nav
      extendBody: true,
      bottomNavigationBar: Container(
        height: 64 + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: const Color(0xFF080D09).withValues(alpha: 0.97),
          border: Border(top: BorderSide(color: AppTheme.border2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, "📋", "Commandes", badge: "2"),
            _buildNavItem(1, "🛍️", "Menu"),
            _buildNavItem(2, "📊", "Stats"),
            _buildNavItem(3, "⚙️", "Paramètres"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String icon, String label, {String? badge}) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  icon,
                  style: TextStyle(
                    fontSize: 20,
                    shadows: isSelected ? [const Shadow(color: Color(0x803DC962), blurRadius: 6)] : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: isSelected ? AppTheme.greenXl : AppTheme.muted, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -4,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.redL,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.bg, width: 2),
                  ),
                  child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
