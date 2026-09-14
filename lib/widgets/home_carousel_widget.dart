import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:openfood_models/openfood_models.dart';
import '../services/carousel_service.dart';
import '../core/theme.dart';
import '../widgets/banner_card.dart';
import '../home_screen.dart';
import '../screens/resto/resto_screen.dart';
import '../screens/explorer_screen.dart';

class HomeCarouselWidget extends StatefulWidget {
  final CarouselPlacement placement;
  final String? restaurantId;

  const HomeCarouselWidget({
    super.key,
    this.placement = CarouselPlacement.home,
    this.restaurantId,
  });

  @override
  State<HomeCarouselWidget> createState() => _HomeCarouselWidgetState();
}

class _HomeCarouselWidgetState extends State<HomeCarouselWidget> {
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentIndex = 0;
  List<CarouselModel>? _carousels;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCarousels();
  }

  Future<void> _loadCarousels() async {
    try {
      final carousels = await CarouselService().getValidCarousels(
        placement: widget.placement,
        restaurantId: widget.restaurantId,
      );
      if (mounted) {
        setState(() {
          _carousels = carousels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Color> _parseColors(List<String> hexList) {
    if (hexList.isEmpty) return [const Color(0xFF061209), const Color(0xFF1B6035)];
    return hexList.map((h) {
      final hexCode = h.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    }).toList();
  }

  void _handleAction(CarouselModel carousel) async {
    if (carousel.actionType == CarouselActionType.open_restaurant) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => 
          RestoScreen(restaurantName: carousel.actionPayload ?? 'Inconnu')));
    } else if (carousel.actionType == CarouselActionType.open_product) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => 
          ExplorerScreen(category: carousel.actionPayload ?? 'Tout')));
    } else if (carousel.actionType == CarouselActionType.open_url) {
      if (carousel.actionPayload != null) {
        final url = Uri.parse(carousel.actionPayload!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator(color: AppTheme.greenXl)),
      );
    }

    if (_carousels == null || _carousels!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: _carousels!.length,
            itemBuilder: (context, index) {
              final carousel = _carousels![index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: JuicyWrapper(
                  onTap: () => _handleAction(carousel),
                  child: BannerCard(
                    emoji: carousel.emoji,
                    title: carousel.title,
                    subtitle: carousel.subtitle,
                    tagText: carousel.tagText,
                    chipText: carousel.chipText,
                    gradientColors: _parseColors(carousel.gradientColorsHex),
                    ctaText: carousel.ctaText,
                    isSponsored: carousel.isSponsored,
                  ),
                ).animate().fade(duration: 400.ms, delay: (index * 100).ms).slideX(begin: 0.1, curve: Curves.easeOutQuad),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots
        if (_carousels!.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_carousels!.length, (index) {
              final isActive = _currentIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 20 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.greenL : AppTheme.surface2,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
