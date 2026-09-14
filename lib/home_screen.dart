import 'package:flutter/material.dart';
import 'package:openfood_models/openfood_models.dart';
import 'core/theme.dart';
import 'widgets/restaurant_card.dart';
import 'widgets/dish_card.dart';
import 'widgets/category_icon.dart';
import 'widgets/banner_card.dart';
import 'screens/resto/resto_screen.dart';
import 'screens/dashboard/dashboard_layout.dart' as dashboard;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/search_modal.dart';
import 'widgets/perso_modal.dart';
import 'services/analytics_service.dart';

import 'screens/profile_screen.dart';
import 'widgets/address_selector_modal.dart';
import 'screens/cart_screen.dart';
import 'screens/livreur/views/livreur_dashboard_view.dart';
import 'services/database_service.dart';
import 'providers/cart_provider.dart';
import 'providers/location_provider.dart';
import 'package:latlong2/latlong.dart';

import 'services/carousel_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/explorer_screen.dart';
import 'screens/filter_modal.dart';
import 'widgets/home_carousel_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _restaurantFilter = "Tout";
  final String userEmail = "contact@example.com"; // Mock de l'email client

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = Provider.of<LocationProvider>(context, listen: false);
      if (loc.selectedAddress == null) {
        AddressSelectorModal.show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialLetter = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : "?";

    return Scaffold(
      backgroundColor: Colors
          .transparent, // Car le parent MainWrapper gère le fond / Scaffold global
      body: Stack(
        children: [
          // Effet glow arrière-plan (pseudo radial-gradient)
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1E8B3A).withValues(alpha: 0.09),
                    Colors.transparent
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                  bottom:
                      150), // Pour ne pas cacher le contenu avec BottomBar+Jauge
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Custom Header ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Location
                        GestureDetector(
                          onTap: () {
                            AddressSelectorModal.show(context);
                          },
                          child: Consumer<LocationProvider>(
                            builder: (context, loc, child) {
                              if (loc.selectedAddress == null) {
                                return Container(
                                  constraints: const BoxConstraints(maxWidth: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: AppTheme.redL.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: AppTheme.redL, size: 16),
                                      SizedBox(width: 6),
                                      Flexible(
                                        child: Text("Saisir l'adresse", style: TextStyle(color: AppTheme.redL, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("LIVRAISON À", style: TextStyle(color: AppTheme.muted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                                  const SizedBox(height: 1),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Text("📍", style: TextStyle(color: AppTheme.redL, fontSize: 13)),
                                      const SizedBox(width: 4),
                                      Container(
                                        constraints: const BoxConstraints(maxWidth: 160),
                                        child: Text(
                                          loc.selectedAddress!.label, 
                                          style: const TextStyle(color: AppTheme.cream, fontSize: 15, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down, color: AppTheme.greenL, size: 16),
                                    ],
                                  ),
                                ],
                              );
                            }
                          ),
                        ),
                        // Logo long
                        Image.asset(
                          'assets/logo_long.jpg',
                          height: 70,
                          width: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Text(
                              "Logo", style: TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold)),
                        ),
                        // Actions (Seeder, Bell, Profile)
                        Row(
                          children: [
                            // ICÔNE BAG / PANIER
                            GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.surface,
                                  border: Border.all(color: AppTheme.border2),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.shopping_bag_outlined, color: AppTheme.cream, size: 18),
                                    Consumer<CartProvider>(
                                      builder: (context, cart, child) {
                                        if (cart.totalQuantity == 0) return const SizedBox.shrink();
                                        return Positioned(
                                          top: -4,
                                          right: -4,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.greenXl,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              "${cart.totalQuantity}",
                                              style: const TextStyle(
                                                color: AppTheme.bg,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [AppTheme.green, Color(0xFF145C26)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Text(initialLetter,
                                      style: AppTheme.titleStyle.copyWith(
                                          fontSize: 15, color: Colors.white)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- Search Bar ---
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppTheme.border2),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      child: Row(
                        children: [
                          const Text("🔍",
                              style: TextStyle(
                                  fontSize: 15, color: AppTheme.muted)),
                          const SizedBox(width: 9),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => SearchModal.show(context),
                              child: const Text(
                                "Plat, restaurant, cuisine...",
                                style: TextStyle(color: AppTheme.muted, fontSize: 14),
                              ),
                            ),
                          ),
                          /*
                          GestureDetector(
                            onTap: () => IAModal.show(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.green, Color(0xFF145C26)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                "🎲 Surprends-moi",
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          */
                        ],
                      ),
                    ),
                  ),

                  // --- Carousel ---
                  const HomeCarouselWidget(),
                  const SizedBox(height: 12),

                  

                  // --- Explorer Section ---
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Explorer",
                            style: AppTheme.titleStyle.copyWith(fontSize: 18)),
                        JuicyWrapper(
                          onTap: () => FilterModal.show(context),
                          child: const Text("Filtrer ▾",
                              style: TextStyle(
                                  color: AppTheme.greenXl,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 95,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        JuicyWrapper(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorerScreen(category: "Tout"))), child: const CategoryIcon(label: "Tout", icon: "🍽️", isSelected: true)),
                        JuicyWrapper(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorerScreen(category: "Grillades"))), child: const CategoryIcon(label: "Grillades", icon: "🥩")),
                        JuicyWrapper(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorerScreen(category: "Poisson"))), child: const CategoryIcon(label: "Poisson", icon: "🐟")),
                        JuicyWrapper(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorerScreen(category: "Pasta"))), child: const CategoryIcon(label: "Pasta", icon: "🍝")),
                        JuicyWrapper(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorerScreen(category: "Pizza"))), child: const CategoryIcon(label: "Pizza", icon: "🍕")),
                        JuicyWrapper(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorerScreen(category: "Burger"))), child: const CategoryIcon(label: "Burger", icon: "🍔")),
                        JuicyWrapper(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorerScreen(category: "Boissons"))), child: const CategoryIcon(label: "Boissons", icon: "🧃")),
                      ].animate(interval: 50.ms).fade(duration: 300.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Chips / SubFilters
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildFilterChip("Tout", _restaurantFilter == "Tout", () => setState(() => _restaurantFilter = "Tout")),
                        _buildFilterChip("Rapide", _restaurantFilter == "Rapide", () => setState(() => _restaurantFilter = "Rapide")),
                        _buildFilterChip("Créole", _restaurantFilter == "Créole", () => setState(() => _restaurantFilter = "Créole")),
                        _buildFilterChip("Asiatique", _restaurantFilter == "Asiatique", () => setState(() => _restaurantFilter = "Asiatique")),
                        _buildFilterChip("Fusion", _restaurantFilter == "Fusion", () => setState(() => _restaurantFilter = "Fusion")),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Vous allez aimer Section ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Vous allez aimer 👌",
                            style: AppTheme.titleStyle.copyWith(fontSize: 18)),
                        JuicyWrapper(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorerScreen(category: "Tout"))),
                          child: const Text("Voir plus →",
                              style: TextStyle(
                                  color: AppTheme.greenXl,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('products').limit(5).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                           return const Center(child: CircularProgressIndicator(color: AppTheme.greenXl));
                        }
                        
                        return ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          physics: const BouncingScrollPhysics(),
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            data['id'] = doc.id;
                            final product = ProductModel.fromJson(data);
                            
                            return JuicyWrapper(
                              onTap: product.isAvailable ? () => PersoModal.show(context, product: product, emoji: "🔥") : () {},
                              child: DishCard(
                                title: product.name,
                                restaurant: product.restaurantName ?? product.restaurantId,
                                price: product.priceHT * (1 + product.vatRate / 100),
                                emoji: "🔥",
                                badgeText: product.badgeText.isNotEmpty ? product.badgeText : "NOUVEAU",
                                isAvailable: product.isAvailable,
                                imageGradient: const [Color(0xFF080D14), Color(0xFF141E30)],
                                imageUrl: product.image,
                                onAdd: product.isAvailable ? () => PersoModal.show(context, product: product, emoji: "??") : null,
                              ),
                            ).animate().fade(duration: 400.ms, delay: (doc.reference.id.hashCode % 5 * 100).ms).slideX(begin: 0.1, curve: Curves.easeOutQuad);
                          }).toList(),
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 26),

                  // --- Restaurants ---
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Restaurants",
                            style: AppTheme.titleStyle.copyWith(fontSize: 18)),
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: DatabaseService().getRestaurants(),
                          builder: (context, snapshot) {
                            int count = 0;
                            if (snapshot.hasData) {
                              var list = snapshot.data!;
                              if (_restaurantFilter != "Tout") {
                                list = list.where((r) => r['type'] == _restaurantFilter).toList();
                              }
                              count = list.length;
                            }
                            return Text(
                              snapshot.connectionState == ConnectionState.waiting
                                  ? "..."
                                  : "$count ouvert${count > 1 ? 's' : ''} près de toi",
                              style: const TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: DatabaseService().getRestaurants(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(child: CircularProgressIndicator(color: AppTheme.greenXl)),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(
                              child: Text(
                                "Erreur de chargement",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.redL, fontSize: 14),
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(
                              child: Text(
                                "Recherche de restaurants dans le Nord Caraïbe...",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.muted, fontSize: 14, height: 1.5),
                              ),
                            ),
                          );
                        }

                        var restaurants = snapshot.data!;
                        
                        // Filtrage par type
                        if (_restaurantFilter != "Tout") {
                          restaurants = restaurants.where((r) => r['type'] == _restaurantFilter).toList();
                        }
                        
                        final loc = Provider.of<LocationProvider>(context, listen: false);
                        
                        return Column(
                          children: restaurants.map((restoData) {
                            double distanceKm = 0.0;
                            double deliveryFeeNum = 2.50; // default
                            
                            if (loc.selectedAddress != null && restoData['lat'] != null && restoData['lng'] != null) {
                              const distance = Distance();
                              distanceKm = distance.as(
                                LengthUnit.Kilometer,
                                LatLng(loc.selectedAddress!.latitude, loc.selectedAddress!.longitude),
                                LatLng((restoData['lat'] as num).toDouble(), (restoData['lng'] as num).toDouble())
                              ).toDouble();
                              
                              if (distanceKm > 14.0) {
                                deliveryFeeNum = -1.0; // Trop loin
                              } else if (distanceKm <= 2.0) {
                                deliveryFeeNum = 2.50;
                              } else {
                                double remaining = distanceKm - 2.0;
                                double tier = remaining > 3.0 ? 3.0 : remaining;
                                deliveryFeeNum = 2.50 + (tier * 0.80);
                                remaining -= tier;
                                if (remaining > 0) {
                                  deliveryFeeNum += remaining * 1.20;
                                }
                              }
                            }
                            
                            bool isAvailable = deliveryFeeNum >= 0.0;
                            String deliveryStr = isAvailable ? "${deliveryFeeNum.toStringAsFixed(2).replaceAll('.', ',')}€" : "Indisponible";
                            String distStr = distanceKm > 0 ? "${distanceKm.toStringAsFixed(1)} km" : (restoData['zone'] ?? "À proximité");

                            Widget card = RestaurantCard(
                              name: restoData['name'] ?? 'Restaurant inconnu',
                              emoji: "🍽️",
                              status: isAvailable ? "Ouvert" : "Trop loin",
                              rating: restoData['rating']?.toString() ?? "N/A",
                              reviews: "Nouveau",
                              tags: restoData['zone'] != null ? [restoData['zone']] : ["Gourmet"],
                              deliveryFee: deliveryStr,
                              deliveryTime: isAvailable ? "30 min" : "-",
                              distance: distStr,
                              priceInfo: "Plats dès 10€",
                              imageUrl: restoData['imageUrl'],
                              imageGradient: const [Color(0xFF071408), Color(0xFF0F2A16), Color(0xFF1A5030)],
                            );
                            
                            if (!isAvailable) {
                              card = Opacity(opacity: 0.5, child: card);
                            }

                            return JuicyWrapper(
                              onTap: isAvailable ? () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => RestoScreen(restaurantName: restoData['name'] ?? 'Restaurant inconnu')));
                              } : () {},
                              child: card,
                            ).animate().fade().slideY(begin: 0.1);
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return JuicyWrapper(
      onTap: () {
        AnalyticsService.logFilter(label);
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E8B3A).withValues(alpha: 0.15)
              : AppTheme.surface,
          border:
              Border.all(color: isSelected ? AppTheme.green : AppTheme.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.greenXl : AppTheme.muted2,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class JuicyWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const JuicyWrapper({super.key, required this.child, required this.onTap});
  @override
  State<JuicyWrapper> createState() => _JuicyWrapperState();
}

class _JuicyWrapperState extends State<JuicyWrapper> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: widget.child.animate(target: _isPressed ? 1 : 0).scaleXY(end: 0.95, duration: 100.ms, curve: Curves.easeOutQuad),
    );
  }
}
