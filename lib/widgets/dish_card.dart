import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';
import '../utils/string_extensions.dart';

class DishCard extends StatefulWidget {
  final String title;
  final String restaurant;
  final double price;
  final String emoji;
  final String badgeText;
  final String peopleOrdered;
  final bool isSponsored;
  final bool isFavorite;
  final bool tonFavori;
  final bool isAvailable;
  final List<Color>? imageGradient;
  final String? imageUrl;
  final VoidCallback? onAdd;

  const DishCard({
    super.key,
    required this.title,
    required this.restaurant,
    required this.price,
    required this.emoji,
    this.badgeText = '',
    this.peopleOrdered = '',
    this.isSponsored = false,
    this.isFavorite = false,
    this.tonFavori = false,
    this.isAvailable = true,
    this.imageGradient,
    this.imageUrl,
    this.onAdd,
  });

  @override
  State<DishCard> createState() => _DishCardState();
}

class _DishCardState extends State<DishCard> {
  bool isPressed = false;
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _isFav = widget.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      width: 152,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Image
          Container(
            height: 90,
            decoration: BoxDecoration(
              gradient: widget.imageGradient != null ? LinearGradient(
                colors: widget.imageGradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) : null,
              color: widget.imageGradient == null ? AppTheme.surface2 : null,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Stack(
              children: [
                if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: AppTheme.greenXl, strokeWidth: 1.5),
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Text(widget.emoji, style: const TextStyle(fontSize: 46)),
                        ),
                      ),
                    ),
                  )
                else
                  Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 46))),
                if (widget.isSponsored)
                  Positioned(
                    top: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF080D09).withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("★", style: TextStyle(color: AppTheme.gold, fontSize: 8)),
                          SizedBox(width: 3),
                          Text("Sponsorisé", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                if (widget.badgeText.isNotEmpty)
                  Positioned(
                    bottom: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.badgeText.contains("NOUVEAU") ? AppTheme.green : AppTheme.redL.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        widget.badgeText,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                      ),
                    ),
                  ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: GestureDetector(
                    onTap: () => setState(() => _isFav = !_isFav),
                    child: Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: const Color(0xFF080D09).withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(_isFav ? "❤️" : "🤍", style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.tonFavori)
                  RichText(
                    text: const TextSpan(
                       style: TextStyle(fontSize: 10, color: AppTheme.muted),
                       children: [
                         TextSpan(text: "Ton favori", style: TextStyle(color: AppTheme.greenXl, fontWeight: FontWeight.bold)),
                         TextSpan(text: " ⭐"),
                       ]
                    )
                  )
                else if (widget.peopleOrdered.isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 10, color: AppTheme.muted),
                      children: [
                        TextSpan(text: widget.peopleOrdered, style: const TextStyle(color: AppTheme.greenXl, fontWeight: FontWeight.bold)),
                        const TextSpan(text: " ont commandé"),
                      ],
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  widget.title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.restaurant.formattedRestaurantName,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    widget.isAvailable
                    ? Text(
                        "${widget.price.toStringAsFixed(2).replaceAll('.', ',')} €",
                        style: const TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 18, color: AppTheme.cream, fontWeight: FontWeight.w800),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.surface3, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppTheme.border)),
                        child: const Text("🛑 Rupture", style: TextStyle(color: AppTheme.redL, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    GestureDetector(
                      onTap: () {
                        if (!widget.isAvailable) return;
                        if (widget.onAdd != null) {
                          widget.onAdd!();
                        }
                      },
                      child: Container(
                        width: 27,
                        height: 27,
                        decoration: BoxDecoration(
                          color: widget.isAvailable ? AppTheme.green : AppTheme.surface3,
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Text("+", style: TextStyle(color: widget.isAvailable ? Colors.white : AppTheme.muted, fontSize: 18, fontWeight: FontWeight.w300))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!widget.isAvailable) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0,    0,    0,    1, 0,
        ]),
        child: Opacity(
          opacity: 0.6,
          child: Transform.scale(
            scale: 0.98,
            child: cardContent,
          ),
        ),
      );
    }

    return cardContent;
  }
}
