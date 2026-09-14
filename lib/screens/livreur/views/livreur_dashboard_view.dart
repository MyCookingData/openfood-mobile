import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../utils/string_extensions.dart';
import 'package:openfood_models/openfood_models.dart';
import '../../../services/order_service.dart';
import '../../../widgets/order_card.dart';
import '../../../services/auth_service.dart';
import '../../../utils/maps_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;

class LivreurDashboardView extends StatefulWidget {
  const LivreurDashboardView({super.key});

  @override
  State<LivreurDashboardView> createState() => _LivreurDashboardViewState();
}

class _LivreurDashboardViewState extends State<LivreurDashboardView> {
  bool _isOnline = false;
  Position? _currentPosition;
  final Map<String, Map<String, dynamic>> _restaurantsCache = {};
  
  int _lastAvailableCount = 0;
  String? _lastActiveOrderId;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('restaurants').get();
      if (mounted) {
        setState(() {
          for (var doc in snap.docs) {
            _restaurantsCache[doc.data()['name'] ?? ''] = doc.data();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleOnline() async {
    if (_isOnline) {
      setState(() => _isOnline = false);
      return;
    }
    
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Les services de localisation sont désactivés.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission de localisation refusée.')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission de localisation refusée de façon permanente.')));
      return;
    }

    try {
      Position? position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      setState(() {
        _currentPosition = position;
        _isOnline = true;
      });
    } catch (e) {
      // Fallback
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _isOnline = true;
        });
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'obtenir la position GPS.')));
      }
    }
  }

  double _calculateDistance(OrderModel order) {
    if (_currentPosition == null) return double.infinity;
    final rData = _restaurantsCache[order.restaurantName];
    if (rData == null || rData['lat'] == null || rData['lng'] == null) return double.infinity;
    
    final double rLat = (rData['lat'] as num).toDouble();
    final double rLng = (rData['lng'] as num).toDouble();
    
    const double p = 0.017453292519943295;
    final a = 0.5 - math.cos((rLat - _currentPosition!.latitude) * p)/2 + 
              math.cos(_currentPosition!.latitude * p) * math.cos(rLat * p) * 
              (1 - math.cos((rLng - _currentPosition!.longitude) * p))/2;
    return 12742 * math.asin(math.sqrt(a));
  }

  void _checkAlerts(List<OrderModel> availableOrders) {
    if (availableOrders.length > _lastAvailableCount) {
      //_audioPlayer.play(AssetSource('sounds/notification.mp3'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("🔔 Nouvelle commande disponible à proximité !"),
          backgroundColor: AppTheme.greenXl,
          duration: const Duration(seconds: 3),
        ));
      }
    }
    _lastAvailableCount = availableOrders.length;
  }

  void _checkActiveOrderAlert(OrderModel? activeOrder) {
    if (activeOrder != null && _lastActiveOrderId != activeOrder.id) {
      _lastActiveOrderId = activeOrder.id;
      //_audioPlayer.play(AssetSource('sounds/notification.mp3'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("🚨 Une commande vous a été assignée !"),
          backgroundColor: Color(0xFFA855F7),
          duration: Duration(seconds: 5),
        ));
      }
    } else if (activeOrder == null) {
      _lastActiveOrderId = null;
    }
  }

  void _acceptOrder(String orderId) {
    final driverId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_driver';
    OrderService.assignDriver(orderId, driverId);
  }

  void _finishOrder(String orderId) {
    OrderService.updateOrderStatus(orderId, 4); // 4 = Livrée
  }

  Future<void> _navigateToRestaurant(String restaurantName) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('name', isEqualTo: restaurantName)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        if (data.containsKey('lat') && data.containsKey('lng')) {
          await MapsLauncher.openMaps(lat: (data['lat'] as num).toDouble(), lng: (data['lng'] as num).toDouble());
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coordonnées du restaurant introuvables.")));
      }
    } catch (e) {
      debugPrint("Err Nav: $e");
    }
  }

  void _navigateToClient(OrderModel order) {
    if (order.customerLat != null && order.customerLng != null) {
      MapsLauncher.openMaps(lat: order.customerLat!, lng: order.customerLng!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le client n'a pas fourni de position GPS exacte.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_driver';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        title: const Text(
          "OpenFood Hub",
          style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.cream),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.muted),
            onPressed: () => AuthService().signOut(),
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            
            if (!_isOnline)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    "Passez en ligne pour recevoir\ndes propositions de livraison.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.muted, fontSize: 14, height: 1.5),
                  ),
                ),
              )
            else
              StreamBuilder<List<OrderModel>>(
                stream: OrderService.getMyDeliveriesStream(driverId),
                builder: (context, activeSnap) {
                  if (activeSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.greenXl));
                  }

                  if (activeSnap.hasData) {
                    final activeOrders = activeSnap.data!.where((o) => o.status == 2 || o.status == 3).toList();
                    if (activeOrders.isNotEmpty) {
                      final activeOrder = activeOrders.first;
                      WidgetsBinding.instance.addPostFrameCallback((_) => _checkActiveOrderAlert(activeOrder));
                      return _buildActiveDeliveryUI(activeOrder);
                    } else {
                      WidgetsBinding.instance.addPostFrameCallback((_) => _checkActiveOrderAlert(null));
                    }
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _checkActiveOrderAlert(null));
                  }

                  return StreamBuilder<List<OrderModel>>(
                    stream: OrderService.getAvailableDeliveriesStream(),
                    builder: (context, availSnap) {
                      if (availSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.greenXl));
                      }
                      
                      final availableOrders = List<OrderModel>.from(availSnap.data ?? []);
                      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAlerts(availableOrders));

                      // Tri par distance (les plus proches d'abord)
                      availableOrders.sort((a, b) => _calculateDistance(a).compareTo(_calculateDistance(b)));

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Nouvelles opportunités", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.cream)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(99)),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.wifi_tethering, color: Color(0xFF0EA5E9), size: 14),
                                        SizedBox(width: 6),
                                        Text("Recherche...", style: TextStyle(color: Color(0xFF0EA5E9), fontSize: 11, fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                  ).animate().shimmer(duration: 2000.ms),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (availableOrders.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text("Aucune livraison disponible.\nLes cuisines préparent !", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.muted2)),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: availableOrders.map((o) => _buildOfferCard(o)).toList(),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.border2, width: 1.5),
        boxShadow: _isOnline
            ? [BoxShadow(color: const Color(0xFF0EA5E9).withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 0, offset: const Offset(0, 10))]
            : [],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Votre Service", style: TextStyle(color: AppTheme.muted2, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              if (_isOnline)
                 Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF0EA5E9), shape: BoxShape.circle)).animate(onPlay: (c) => c.repeat()).fade(duration: 800.ms, curve: Curves.easeInOut),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _toggleOnline,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.fastOutSlowIn,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: _isOnline
                    ? const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)]) // Bleu dynamique
                    : const LinearGradient(colors: [AppTheme.surface3, AppTheme.surface2]), // Gris mat
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _isOnline ? Colors.transparent : AppTheme.border),
                boxShadow: _isOnline
                    ? [const BoxShadow(color: Color(0xFF0EA5E9), blurRadius: 20, offset: Offset(0, 8), spreadRadius: -5)]
                    : [],
              ),
              child: Center(
                child: Text(
                  _isOnline ? "EN LIGNE - PRÊT À LIVRER" : "PASSER EN LIGNE",
                  style: TextStyle(fontFamily: 'Bricolage Grotesque', color: _isOnline ? Colors.white : AppTheme.muted, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.1, duration: 400.ms, curve: Curves.easeOutCubic).fade();
  }

  Widget _buildOfferCard(OrderModel order) {
    double revenLivreur = 2.50 + (order.totalAmount * 0.10); 
    double dist = _calculateDistance(order);
    String distStr = dist == double.infinity ? "GPS Requis" : "${dist.toStringAsFixed(1)} km";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.green.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.green.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Course N°${order.id.substring(0, 5)}", style: const TextStyle(color: AppTheme.muted2, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text("+ ${revenLivreur.toStringAsFixed(2).replaceAll('.', ',')} €", style: const TextStyle(fontFamily: 'Bricolage Grotesque', color: AppTheme.greenXl, fontSize: 22, fontWeight: FontWeight.w800)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Text("⏱", style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text("$distStr • Prête", style: const TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  children: [
                    Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppTheme.greenXl, shape: BoxShape.circle)),
                    Container(width: 2, height: 30, color: AppTheme.border2),
                    Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFF5820A), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Récupération", style: TextStyle(color: AppTheme.muted2, fontSize: 10, fontWeight: FontWeight.w700)),
                      Text(order.restaurantName.formattedRestaurantName, style: const TextStyle(color: AppTheme.cream, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 18),
                      const Text("Livraison client", style: TextStyle(color: AppTheme.muted2, fontSize: 10, fontWeight: FontWeight.w700)),
                      Text(order.deliveryAddress ?? "Pas d'adresse", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.cream, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () => _acceptOrder(order.id),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)]), borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.bolt, color: Colors.white, size: 20),
                     SizedBox(width: 8),
                     Text("Accepter la course", style: TextStyle(fontFamily: 'Bricolage Grotesque', color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    ).animate().fade().scale(begin: const Offset(0.95, 0.95), duration: 300.ms, curve: Curves.easeOutCirc);
  }

  Widget _buildActiveDeliveryUI(OrderModel order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(color: const Color(0xFFA855F7).withValues(alpha: 0.15), blurRadius: 40, spreadRadius: -5)
          ]
        ),
        child: Column(
          children: [
             Padding(
               padding: const EdgeInsets.all(24.0),
               child: Column(
                 children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                     decoration: BoxDecoration(color: const Color(0xFFA855F7).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)),
                     child: const Text("🚨 COURSE EN COURS 🚨", style: TextStyle(color: Color(0xFFD8B4FE), fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                   ).animate().shimmer(duration: 1500.ms, color: Colors.white),
                   const SizedBox(height: 28),
                   
                   _buildStageRow("1. RÉCUPÉRATION", order.restaurantName.formattedRestaurantName, Icons.storefront, const Color(0xFF0EA5E9), () => _navigateToRestaurant(order.restaurantName)),
                   
                   Padding(
                     padding: const EdgeInsets.only(left: 28),
                     child: Container(
                       height: 30,
                       width: 2,
                       color: AppTheme.border2,
                     ),
                   ),
                   
                   _buildStageRow("2. LIVRAISON", order.deliveryAddress ?? "GPS Requis", Icons.person_pin_circle, const Color(0xFFA855F7), () => _navigateToClient(order)),

                   if (order.customerPhone != null || order.customerName != null)
                     Padding(
                       padding: const EdgeInsets.only(top: 16),
                       child: Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(color: AppTheme.surface3, borderRadius: BorderRadius.circular(12)),
                         child: Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             if (order.customerPhone != null) ...[
                               const Icon(Icons.phone, color: AppTheme.muted2, size: 16),
                               const SizedBox(width: 8),
                               Text(order.customerPhone!, style: const TextStyle(color: AppTheme.cream, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                             ],
                             if (order.customerPhone != null && order.customerName != null)
                               const Text(" - ", style: TextStyle(color: AppTheme.muted2, fontSize: 16)),
                             if (order.customerName != null)
                               Expanded(
                                 child: Text(
                                   order.customerName!, 
                                   style: const TextStyle(color: AppTheme.cream, fontSize: 16, fontWeight: FontWeight.w600),
                                   overflow: TextOverflow.ellipsis,
                                 ),
                               ),
                           ],
                         )
                       ),
                     ),
                 ],
               ),
             ),
             
             GestureDetector(
                onTap: () {
                  if (order.status == 2) {
                    OrderService.updateOrderStatus(order.id, 3);
                  } else {
                    _finishOrder(order.id);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: order.status == 2 
                        ? const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF2E8FE8)])
                        : const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFA855F7)]),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(26), bottomRight: Radius.circular(26)),
                  ),
                  child: Center(
                    child: Text(
                      order.status == 2 ? "J'AI RÉCUPÉRÉ LA COMMANDE" : "VALIDER LA LIVRAISON", 
                      style: const TextStyle(fontFamily: 'Bricolage Grotesque', color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.1, duration: 300.ms).fade();
  }

  Widget _buildStageRow(String overline, String title, IconData icon, Color accent, VoidCallback onNav) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(overline, style: const TextStyle(color: AppTheme.muted2, fontSize: 11, fontWeight: FontWeight.w700)),
              Text(title, style: const TextStyle(color: AppTheme.cream, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.navigation, color: Colors.white),
          style: IconButton.styleFrom(backgroundColor: accent),
          onPressed: onNav,
        ),
      ],
    );
  }
}
