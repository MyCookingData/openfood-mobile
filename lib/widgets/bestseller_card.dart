import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';

class BestsellerCard extends StatefulWidget {
  final String title;
  final String description;
  final double price;
  final String emoji;
  final String? imageUrl;
  final String ordersCount;
  final List<Color> imageGradient;
  final String? badgeText;
  final String? stockWarn;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  const BestsellerCard({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    this.emoji = '',
    this.imageUrl,
    required this.ordersCount,
    required this.imageGradient,
    this.badgeText,
    this.stockWarn,
    required this.onAdd,
    required this.onTap,
  });

  @override
  State<BestsellerCard> createState() => _BestsellerCardState();
}

class _BestsellerCardState extends State<BestsellerCard> {
  bool _isFav = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Area
            Container(
              height: 138,
              decoration: BoxDecoration(
                gradient: widget.imageUrl == null || widget.imageUrl!.isEmpty
                    ? LinearGradient(
                        colors: widget.imageGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: AppTheme.surface2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                    Positioned.fill(
                      child: widget.imageUrl!.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: widget.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppTheme.surface3,
                                child: const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: AppTheme.greenXl, strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppTheme.surface3,
                                child: const Center(
                                  child: Icon(Icons.restaurant, color: AppTheme.muted2, size: 40),
                                ),
                              ),
                            )
                          : Image.asset(
                              widget.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppTheme.surface3,
                                child: const Center(
                                  child: Icon(Icons.restaurant, color: AppTheme.muted2, size: 40),
                                ),
                              ),
                            ),
                    )
                  else
                    const Center(child: Icon(Icons.restaurant, color: AppTheme.muted2, size: 40)),
                  if (widget.badgeText != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF080D09).withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.badgeText!,
                          style: const TextStyle(color: AppTheme.gold, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  if (widget.stockWarn != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.redL.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.stockWarn!,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3, textBaseline: TextBaseline.alphabetic),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isFav = !_isFav);
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF080D09).withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            _isFav ? Icons.favorite : Icons.favorite_border,
                            color: _isFav ? AppTheme.redL : Colors.white70,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body Area
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 14, right: 14, bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   RichText(
                     text: TextSpan(
                       style: const TextStyle(fontSize: 10, color: AppTheme.muted),
                       children: [
                         TextSpan(text: widget.ordersCount, style: const TextStyle(color: AppTheme.greenXl, fontWeight: FontWeight.bold)),
                         const TextSpan(text: " aujourd'hui"),
                       ],
                     ),
                   ),
                   const SizedBox(height: 3),
                   Text(
                     widget.title,
                     style: AppTheme.titleStyle.copyWith(fontSize: 16),
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                   ),
                   const SizedBox(height: 3),
                   Text(
                     widget.description,
                     style: const TextStyle(color: AppTheme.muted, fontSize: 11, height: 1.4),
                     maxLines: 2,
                     overflow: TextOverflow.ellipsis,
                   ),
                   const SizedBox(height: 10),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(
                         "${widget.price.toStringAsFixed(2).replaceAll('.', ',')}€",
                         style: const TextStyle(color: AppTheme.greenXl, fontSize: 16, fontWeight: FontWeight.w800),
                       ),
                       GestureDetector(
                         onTap: widget.onAdd,
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                           decoration: BoxDecoration(
                             color: AppTheme.green,
                             borderRadius: BorderRadius.circular(999),
                           ),
                           child: const Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Text("+ Ajouter", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                             ],
                           ),
                         ),
                       ),
                     ],
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
