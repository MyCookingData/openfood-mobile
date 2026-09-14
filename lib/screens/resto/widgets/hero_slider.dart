import 'dart:async';
import 'package:flutter/material.dart';

class HeroSlider extends StatefulWidget {
  const HeroSlider({super.key});

  @override
  State<HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<HeroSlider> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % 3;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView(
          controller: _pageController,
          onPageChanged: (idx) => setState(() => _currentPage = idx),
          children: [
            // Slide 1
            _buildSlide(
              gradient: const [Color(0xFF071408), Color(0xFF0F2A16), Color(0xFF1A5030)],
              child: const Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    bottom: 38,
                    left: 20,
                    child: Text(
                      "Open Food",
                      style: TextStyle(
                        fontFamily: 'Bricolage Grotesque',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 2))],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Slide 2
            _buildSlide(
              gradient: const [Color(0xFF2A0800), Color(0xFF6B1500), Color(0xFFC42800)],
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    bottom: 38, left: 20, right: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTag("🔥 Offre spéciale"),
                        const SizedBox(height: 7),
                        const Text("Menu complet\nà 16€ ce week-end", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                        const SizedBox(height: 3),
                        Text("Plat + boisson + dessert inclus", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                      ],
                    ),
                  ),
                  const Positioned(
                    bottom: 30, right: 16,
                    child: Text("🍱", style: TextStyle(fontSize: 56, shadows: [Shadow(color: Colors.black45, blurRadius: 14, offset: Offset(0, 6))])),
                  ),
                  Positioned(
                    top: 14, right: 58,
                    child: _buildPlanBadge("PRO"),
                  ),
                ],
              ),
            ),
            // Slide 3
            _buildSlide(
              gradient: const [Color(0xFF001830), Color(0xFF003060), Color(0xFF005AAA)],
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    bottom: 38, left: 20, right: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTag("✨ Nouveau"),
                        const SizedBox(height: 7),
                        const Text("Pasta Alfredo\nest arrivée !", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                        const SizedBox(height: 3),
                        Text("Poulet grillé · sauce crémeuse · champignons", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                      ],
                    ),
                  ),
                  const Positioned(
                    bottom: 30, right: 16,
                    child: Text("🍝", style: TextStyle(fontSize: 56, shadows: [Shadow(color: Colors.black45, blurRadius: 14, offset: Offset(0, 6))])),
                  ),
                  Positioned(
                    top: 14, right: 58,
                    child: _buildPlanBadge("ÉLITE"),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Overlay foncé pour améliorer la lisibilité globale
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF080D09).withValues(alpha: 0.1), const Color(0xFF080D09).withValues(alpha: 0.55)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Pagination Dots
        Positioned(
          bottom: 14,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              bool isSel = _currentPage == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: isSel ? 18 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSlide({required List<Color> gradient, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.transparent),
      ),
      child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.7)),
    );
  }

  Widget _buildPlanBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF080D09).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }
}
