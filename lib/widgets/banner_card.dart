import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';

class BannerCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String tagText;
  final String chipText;
  final List<Color> gradientColors;
  final String ctaText;
  final bool isSponsored;
  final String? imageUrl;
  final String? logoUrl;

  const BannerCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.tagText,
    required this.chipText,
    required this.gradientColors,
    required this.ctaText,
    this.isSponsored = false,
    this.imageUrl,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final bool hasLogo = logoUrl != null && logoUrl!.trim().isNotEmpty;

    return Container(
      width: 310,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: gradientColors.isNotEmpty ? gradientColors : [const Color(0xFF061209), const Color(0xFF1B6035)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (gradientColors.isNotEmpty ? gradientColors.first : AppTheme.green).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Background Image if available
            if (hasImage)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),

            // Dark gradient overlay for optimal text contrast and readability
            if (hasImage)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.65),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

            // White Glow effect behind when no background image
            if (!hasImage)
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (chipText.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF080D09).withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppTheme.greenXl.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.greenXl, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(
                            chipText,
                            style: const TextStyle(color: AppTheme.greenXl, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (isSponsored)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF080D09).withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("★", style: TextStyle(color: AppTheme.gold, fontSize: 8)),
                            SizedBox(width: 3),
                            Text("Sponsorisé", style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),

                  if (tagText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tagText,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.7),
                      ),
                    ),
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: AppTheme.titleStyle.copyWith(
                        fontSize: 16,
                        height: 1.2,
                        shadows: hasImage
                            ? const [Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 2))]
                            : null,
                      ),
                    ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        shadows: hasImage
                            ? const [Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 1))]
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (ctaText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(ctaText, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Top-Right Logo or Emoji graphic
            if (hasLogo)
              Positioned(
                right: 14,
                top: 14,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: logoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              )
            else if (!hasImage && emoji.isNotEmpty)
              Positioned(
                right: -8,
                top: 6,
                child: Text(
                  emoji,
                  style: const TextStyle(
                    fontSize: 70,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8))],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
