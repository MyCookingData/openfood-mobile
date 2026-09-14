import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'widgets/sidebar.dart';
import 'views/dashboard_view.dart';
import 'views/orders_view.dart';
import 'views/products_view.dart';

class DashboardLayout extends StatefulWidget {
  const DashboardLayout({super.key});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  String _activePage = "dashboard";
  bool _isOpen = true; // Status Ouvert/Fermé
  
  void _changePage(String pageId) {
    setState(() => _activePage = pageId);
  }

  Widget _buildActiveView() {
    switch (_activePage) {
      case "dashboard":
        return const DashboardView();
      case "commandes":
        return const OrdersView();
      case "produits":
        return const ProductsView();
      case "categories":
        return const Center(child: Text("Page Catégories", style: TextStyle(color: Colors.white)));
      case "pub":
        return const Center(child: Text("Page Régie Pub", style: TextStyle(color: Colors.white)));
      case "settings":
        return const Center(child: Text("Paramètres", style: TextStyle(color: Colors.white)));
      default:
        return const DashboardView();
    }
  }

  String get _pageTitle {
    Map<String, String> titles = {
      'dashboard': 'Dashboard',
      'commandes': 'Commandes',
      'produits': 'Produits',
      'categories': 'Catégories',
      'pub': 'Régie pub',
      'settings': 'Paramètres'
    };
    return titles[_activePage] ?? _activePage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isCompact = constraints.maxWidth < 800;
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sidebar
              DashboardSidebar(
                activePage: _activePage,
                onPageChanged: _changePage,
                isCompact: isCompact,
              ),
              
              // Main content
              Expanded(
                child: Column(
                  children: [
                    // Topbar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        border: Border(bottom: BorderSide(color: AppTheme.border)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_pageTitle, style: AppTheme.titleStyle.copyWith(fontSize: 20)),
                                const SizedBox(height: 2),
                                const Text(
                                  "Ven 27 mars · MAJ 2 min",
                                  style: TextStyle(color: AppTheme.muted, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _isOpen = !_isOpen),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _isOpen ? const Color(0xFF1E8B3A).withValues(alpha: 0.12) : AppTheme.redL.withValues(alpha: 0.12),
                                    border: Border.all(color: _isOpen ? const Color(0xFF1E8B3A).withValues(alpha: 0.25) : AppTheme.redL.withValues(alpha: 0.25)),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: _isOpen ? AppTheme.greenXl : AppTheme.redL,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isOpen ? "Ouvert" : "Fermé",
                                        style: TextStyle(color: _isOpen ? AppTheme.greenXl : AppTheme.redL, fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  // Naviguer retour vers l'app cliente pour démonstration
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface2,
                                    border: Border.all(color: AppTheme.border2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text("Retour App Client", style: TextStyle(color: AppTheme.cream, fontSize: 13, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Main View
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                        color: AppTheme.bg,
                        child: _buildActiveView(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
