import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';

class RestaurantCard extends StatelessWidget {
  final String name;
  final String emoji;
  final String status;
  final String statusColor;
  final String promos;
  final String promoColor;
  final String rating;
  final String reviews;
  final List<String> tags;
  final String deliveryFee;
  final String deliveryTime;
  final String distance;
  final String priceInfo;
  final String ordersBadge;
  final bool isFeatured;
  final List<Color>? imageGradient;
  final String? imageUrl;

  const RestaurantCard({
    super.key,
    required this.name,
    required this.emoji,
    required this.status,
    this.statusColor = 'green',
    this.promos = '',
    this.promoColor = 'red',
    required this.rating,
    required this.reviews,
    required this.tags,
    required this.deliveryFee,
    required this.deliveryTime,
    required this.distance,
    required this.priceInfo,
    this.ordersBadge = '',
    this.isFeatured = false,
    this.imageGradient,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Stack(
            children: [
              Container(
                height: 148,
                decoration: BoxDecoration(
                  gradient: imageGradient != null ? LinearGradient(
                    colors: imageGradient!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ) : null,
                  color: imageGradient == null ? AppTheme.surface2 : null,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                ),
              ),
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    height: 148,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: AppTheme.greenXl, strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.fastfood, color: AppTheme.muted2, size: 40),
                    ),
                  ),
                ),
              // Overlay sombre par-dessus l'image
              if (imageUrl != null)
                Container(
                  height: 148,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                ),
              // L'emoji parfaitement centré
              SizedBox(
                height: 148,
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 66)),
                ),
              ),
              if (ordersBadge.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF080D09).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      ordersBadge,
                      style: const TextStyle(color: AppTheme.greenXl, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E8B3A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF1E8B3A).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.greenXl, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(status, style: const TextStyle(color: AppTheme.greenXl, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              if (promos.isNotEmpty)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: promoColor == 'red' ? AppTheme.redL.withValues(alpha: 0.88) : AppTheme.green.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      promos,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                    ),
                  ),
                ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: AppTheme.titleStyle.copyWith(fontSize: 17),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface2,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const Text("★", style: TextStyle(color: AppTheme.gold, fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            "$rating ",
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
                          ),
                          Text(
                            "($reviews)",
                            style: const TextStyle(color: AppTheme.muted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.surface2,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(color: AppTheme.muted2, fontSize: 11),
                      ),
                    );
                  }).toList()..addAll([
                    if (isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.06),
                          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text("★ Mis en avant", style: TextStyle(color: AppTheme.gold, fontSize: 9)),
                      )
                  ]),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Text(deliveryFee, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                    const SizedBox(width: 12),
                    Text(deliveryTime, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                    const SizedBox(width: 12),
                    Text(distance, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border)),
              gradient: LinearGradient(
                colors: [AppTheme.green.withValues(alpha: 0.07), Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("À partir de", style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                Text(
                  priceInfo,
                  style: const TextStyle(color: AppTheme.greenXl, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

