import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';

class ProductTile extends StatelessWidget {
  final String title;
  final String description;
  final double price;
  final String emoji;
  final List<Color> imageGradient;
  final String? imageUrl;
  final String? tag;
  final String? stockWarn;
  final bool isAvailable;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const ProductTile({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.emoji,
    required this.imageGradient,
    this.imageUrl,
    this.tag,
    this.stockWarn,
    this.isAvailable = true,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = InkWell(
      onTap: isAvailable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Image
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: imageGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: AppTheme.greenXl, strokeWidth: 1.5),
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 36)),
                          ),
                        ),
                      ),
                    )
                  else
                    Center(child: Text(emoji, style: const TextStyle(fontSize: 36))),
                  if (stockWarn != null)
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        color: AppTheme.redL.withValues(alpha: 0.85),
                        child: Text(
                          stockWarn!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Right info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTheme.titleStyle.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(color: AppTheme.muted, fontSize: 11, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        "${price.toStringAsFixed(2).replaceAll('.', ',')}€",
                        style: const TextStyle(color: AppTheme.greenXl, fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surface2,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(tag!, style: const TextStyle(color: AppTheme.muted2, fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Add Button
            if (isAvailable)
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppTheme.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text("+", style: TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.surface3, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppTheme.border)),
                child: const Text("RUPTURE", style: TextStyle(color: AppTheme.redL, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
          ],
        ),
      ),
    );

    if (!isAvailable) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0,    0,    0,    1, 0,
        ]),
        child: Opacity(
          opacity: 0.6,
          child: content,
        ),
      );
    }

    return content;
  }
}
