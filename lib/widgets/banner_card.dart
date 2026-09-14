import 'package:flutter/material.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // White Glow effect behind
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
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
                
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                margin: const EdgeInsets.only(bottom: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tagText,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.7),
                ),
              ),
              Text(
                title,
                style: AppTheme.titleStyle.copyWith(fontSize: 16, height: 1.2),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ctaText, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          // Emoji
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
    );
  }
}
