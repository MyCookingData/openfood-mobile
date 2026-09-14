import 'dart:math';
import 'package:flutter/material.dart';
import 'package:openfood_models/openfood_models.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/bestseller_card.dart';
import '../../widgets/product_tile.dart';
import '../../widgets/perso_modal.dart';
import '../../widgets/banner_card.dart';
import '../../services/carousel_service.dart';
import '../cart_screen.dart';
import 'widgets/hero_slider.dart';

class RestoScreen extends StatefulWidget {
  final String restaurantName;
  const RestoScreen({super.key, this.restaurantName = 'Open Food'});

  @override
  State<RestoScreen> createState() => _RestoScreenState();
}

class _RestoScreenState extends State<RestoScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  int _activeCategory = 0;
  final List<int> _categoryListIndices = [];
  List<String> _navCategories = [];
  late Future<QuerySnapshot> _restaurantFuture;

  @override
  void initState() {
    super.initState();
    _restaurantFuture = FirebaseFirestore.instance
        .collection('restaurants')
        .where('name', isEqualTo: widget.restaurantName)
        .limit(1)
        .get();
    _itemPositionsListener.itemPositions.addListener(_onPositionsChanged);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);
    super.dispose();
  }

  void _onPositionsChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || _categoryListIndices.isEmpty) return;
    
    var visiblePositions = positions.where((p) => p.itemTrailingEdge > 0.05);
    
    if (visiblePositions.isEmpty) {
      visiblePositions = positions;
    }
    
    int minIndex = visiblePositions.map((p) => p.index).reduce(min);
    
    int activeCat = 0;
    for (int i = 0; i < _categoryListIndices.length; i++) {
      if (_categoryListIndices[i] <= minIndex) {
        activeCat = i;
      } else {
        break;
      }
    }

    if (_activeCategory != activeCat) {
      if (mounted) setState(() => _activeCategory = activeCat);
    }
  }

  void _scrollToCategory(int index) {
    HapticFeedback.lightImpact();
    setState(() => _activeCategory = index);
    if (_categoryListIndices.isNotEmpty && index < _categoryListIndices.length) {
      if (_itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: _categoryListIndices[index],
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Widget _buildInfoPill(String text, {Color color = AppTheme.muted2, bool showDot = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.greenXl, shape: BoxShape.circle)),
              const SizedBox(width: 4),
            ],
            Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBar(CartProvider cart) {
    if (cart.totalQuantity == 0) return const SizedBox.shrink();
    return Positioned(
      bottom: 34,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.green, Color(0xFF145C26)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E8B3A).withValues(alpha: 0.40),
                blurRadius: 28,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${cart.totalQuantity} article${cart.totalQuantity > 1 ? 's' : ''}", style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text("${cart.subtotalAmount.toStringAsFixed(2).replaceAll('.', ',')}€", style: AppTheme.titleStyle.copyWith(fontSize: 17)),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text("Voir le panier →", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    if (_navCategories.isEmpty) return const SizedBox.shrink();
    return Container(
      color: AppTheme.bg,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border)),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _navCategories.length,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemBuilder: (context, index) {
            bool isSel = _activeCategory == index;
            return GestureDetector(
              onTap: () => _scrollToCategory(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: isSel ? const Border(bottom: BorderSide(color: AppTheme.greenXl, width: 2)) : null,
                ),
                child: Text(
                  _navCategories[index],
                  style: TextStyle(
                    color: isSel ? AppTheme.greenXl : AppTheme.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          FutureBuilder<QuerySnapshot>(
            future: _restaurantFuture,
            builder: (context, restoSnap) {
              if (restoSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.greenXl));
              }
              if (restoSnap.hasError) {
                return Center(child: Text("Erreur : ${restoSnap.error}", style: const TextStyle(color: AppTheme.redL)));
              }

              String restaurantId = widget.restaurantName;
              if (restoSnap.hasData && restoSnap.data!.docs.isNotEmpty) {
                restaurantId = restoSnap.data!.docs.first.id;
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('restaurantId', isEqualTo: restaurantId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.greenXl));
                  }

              if (snapshot.hasError) {
                return Center(child: Text("Erreur : ${snapshot.error}", style: const TextStyle(color: AppTheme.redL)));
              }

              final docs = snapshot.data?.docs ?? [];

              Map<String, List<QueryDocumentSnapshot>> byCategory = {};
              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                String cat = data['category'] ?? 'Autre';
                byCategory.putIfAbsent(cat, () => []).add(doc);
              }

              List<String> rawCategories = byCategory.keys.toList()..sort();
              List<QueryDocumentSnapshot> bestsellers = docs.take(min(3, docs.length)).toList();

              _navCategories = [];
              if (bestsellers.isNotEmpty) _navCategories.add("⭐ Bestsellers");
              for (var c in rawCategories) {
                _navCategories.add("🍽️ $c");
              }

              List<Widget> listItems = [];
              _categoryListIndices.clear();

              if (docs.isEmpty) {
                listItems.add(
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text("Aucun plat disponible.", style: TextStyle(color: AppTheme.muted))),
                  ),
                );
              }


              if (bestsellers.isNotEmpty) {
                _categoryListIndices.add(listItems.length);
                listItems.add(
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("⭐ Bestsellers", style: AppTheme.titleStyle.copyWith(fontSize: 17)),
                        const Text("Les plus commandés", style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                );
                listItems.add(const SizedBox(height: 13));
                listItems.add(
                  SizedBox(
                    height: 290,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: bestsellers.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        data['id'] = doc.id;
                          final product = ProductModel.fromJson(data);
                        
                        return BestsellerCard(
                          title: data['name'] ?? 'Inconnu',
                          description: data['description'] ?? '',
                          price: product.priceHT * (1 + product.vatRate / 100),
                          emoji: "🔥",
                          ordersCount: "${(10 + Random().nextInt(50))} commandes",
                          imageGradient: const [Color(0xFF071408), Color(0xFF1A4020)],
                          onTap: () {
                            HapticFeedback.lightImpact();
                            PersoModal.show(context, product: product, emoji: "🔥");
                          },
                          onAdd: () {
                            HapticFeedback.lightImpact();
                            PersoModal.show(context, product: product, emoji: "🔥");
                          },
                        );
                      }).toList(),
                    ),
                  ),
                );
              }

              for (var category in rawCategories) {
                _categoryListIndices.add(listItems.length);
                final items = byCategory[category]!;
                
                listItems.add(const SizedBox(height: 24));
                listItems.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(category, style: AppTheme.titleStyle.copyWith(fontSize: 17)),
                  ),
                );
                
                listItems.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: items.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        data['id'] = doc.id;
                          final product = ProductModel.fromJson(data);
                        
                        
                        return ProductTile(
                          title: data['name'] ?? 'Inconnu',
                          description: data['description'] ?? '',
                          price: product.priceHT * (1 + product.vatRate / 100),
                          emoji: "🍽️",
                          isAvailable: product.isAvailable,
                          imageGradient: const [Color(0xFF0A1A0D), Color(0xFF1A3A20)],
                          imageUrl: product.image,
                          onTap: product.isAvailable ? () {
                            HapticFeedback.lightImpact();
                            PersoModal.show(context, product: product, emoji: "🍽️");
                          } : () {},
                          onAdd: product.isAvailable ? () {
                            HapticFeedback.lightImpact();
                            PersoModal.show(context, product: product, emoji: "🍽️");
                          } : () {},
                        );
                      }).toList(),
                    ),
                  ),
                );
              }

              listItems.add(const SizedBox(height: 180));

              return Column(
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 200,
                        child: FutureBuilder<List<CarouselModel>>(
                          future: CarouselService().getValidCarousels(
                            placement: CarouselPlacement.restaurant,
                            restaurantId: restaurantId,
                          ),
                          builder: (context, carouselSnap) {
                            if (!carouselSnap.hasData || carouselSnap.data!.isEmpty) {
                              return const HeroSlider();
                            }
                            return PageView(
                              controller: PageController(viewportFraction: 0.95),
                              children: carouselSnap.data!.map((c) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
                                  child: BannerCard(
                                    emoji: c.emoji,
                                    title: c.title,
                                    subtitle: c.subtitle,
                                    tagText: c.tagText,
                                    chipText: c.chipText,
                                    gradientColors: c.gradientColorsHex
                                        .map((hex) => Color(int.parse(hex.replaceAll('#', '0xFF'))))
                                        .toList(),
                                    ctaText: c.ctaText,
                                    isSponsored: c.isSponsored,
                                  ),
                                );
                              }).toList(),
                            );
                          }
                        )
                      ),
                      Positioned(
                        top: 40,
                        left: 10,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF080D09).withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white, size: 20)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border(bottom: BorderSide(color: AppTheme.border)),
                    ),
                    child: FutureBuilder<QuerySnapshot>(
                      future: _restaurantFuture,
                      builder: (context, restoSnap) {
                        String insta = "";
                        String fb = "";
                        String tiktok = "";
                        if (restoSnap.hasData && restoSnap.data!.docs.isNotEmpty) {
                          final rd = restoSnap.data!.docs.first.data() as Map<String, dynamic>;
                          insta = rd['instagram'] ?? "";
                          fb = rd['facebook'] ?? "";
                          tiktok = rd['tiktok'] ?? "";
                        }
                        
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildInfoPill("Ouvert · ferme à 22h", color: AppTheme.greenXl, showDot: true),
                            _buildInfoPill("★ 4.8 (142 avis)", color: AppTheme.gold),
                            _buildInfoPill("⏱ 25–35 min"),
                            _buildInfoPill("🛵 2,50€"),
                            if (insta.isNotEmpty) _buildInfoPill("📷 Insta", onTap: () => launchUrl(Uri.parse(insta))),
                            if (fb.isNotEmpty) _buildInfoPill("📘 FB", onTap: () => launchUrl(Uri.parse(fb))),
                            if (tiktok.isNotEmpty) _buildInfoPill("🎵 TikTok", onTap: () => launchUrl(Uri.parse(tiktok))),
                          ],
                        );
                      }
                    ),
                  ),
                  _buildCategoryTabs(),
                  Expanded(
                    child: ScrollablePositionedList.builder(
                      itemCount: listItems.length,
                      itemBuilder: (context, i) => listItems[i],
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
          
          _buildCartBar(cart),
        ],
      ),
    );
  }
}
