import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_screen.dart';
import 'screens/cart_screen.dart';
import 'core/theme.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'screens/profile_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/search_modal.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';

class MainWrapper extends StatefulWidget {
  final int initialIndex;
  const MainWrapper({super.key, this.initialIndex = 0});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    
    // Initialiser les notifications locales et démarrer l'écoute des statuts
    NotificationService.instance.initialize().then((_) {
      NotificationService.instance.startListeningToOrders();
    });
  }

  @override
  void dispose() {
    NotificationService.instance.stopListening();
    super.dispose();
  }

  List<Widget> get _pages => [
    const HomeScreen(),
    const Center(
        child: Text("Explorer", style: TextStyle(color: AppTheme.cream))),
    const Center(
        child: Text("Panier", style: TextStyle(color: AppTheme.cream))),
    OrdersScreen(onBackToHome: () => setState(() => _currentIndex = 0)),
    ProfileScreen(onBackToHome: () => setState(() => _currentIndex = 0)),
  ];

// listeners removed

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cart.totalQuantity > 0)
            GestureDetector(
              onTap: () {
                AnalyticsService.logNavigation("Panier");
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.greenXl,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppTheme.greenXl.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${cart.totalQuantity} article${cart.totalQuantity > 1 ? 's' : ''}", style: const TextStyle(color: AppTheme.bg, fontWeight: FontWeight.bold, fontSize: 13)),
                    const Text(
                      "Voir le panier →", 
                      style: TextStyle(color: AppTheme.bg, fontWeight: FontWeight.w900, fontSize: 14)
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 1, curve: Curves.easeOutBack, duration: 400.ms),
          // Custom Bottom Nav Bar
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF080D09)
                  .withValues(alpha: 0.97), // Effet blur simulé
              border: Border(top: BorderSide(color: AppTheme.border2)),
            ),
            padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, "🏠", "Accueil"),
                _buildNavItem(1, "🔍", "Explorer"), // Ouvre le SearchModal
                _buildCartItem(cart),
                _buildNavItem(3, "📋", "Commandes"),
                _buildNavItem(4, "👤", "Profil"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        AnalyticsService.logNavigation(label);
        if (index == 1) {
          SearchModal.show(context);
        } else {
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon,
              style: TextStyle(
                  fontSize: 20,
                  color: isSelected ? AppTheme.greenXl : AppTheme.muted)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppTheme.greenXl : AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartProvider cart) {
    final count = cart.totalQuantity;
    return GestureDetector(
      onTap: () {
        AnalyticsService.logNavigation("Panier");
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.green, AppTheme.greenXl],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E8B3A).withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                      child: Text("🛒", style: TextStyle(fontSize: 21))),
                ),
                if (count > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 15),
                      decoration: BoxDecoration(
                        color: AppTheme.redL,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppTheme.bg, width: 2),
                      ),
                      child: Text(
                        count.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -12),
            child: const Text(
              "Panier",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
