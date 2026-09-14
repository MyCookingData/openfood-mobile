import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../main_wrapper.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {

  Timer? _timer;
  int _secondsLeft = 120; // 2 minutes

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  // Icône de succès
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.check_circle_rounded, color: AppTheme.greenXl, size: 80),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Titre
                  const Text(
                    "Commande Validée !",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Bricolage Grotesque',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.cream,
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 16),
                  
                  // Countdown
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "En attente de confirmation...",
                          style: TextStyle(color: AppTheme.muted, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer_outlined, color: AppTheme.greenXl, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              "${(_secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(_secondsLeft % 60).toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                fontFamily: 'Bricolage Grotesque',
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.greenXl,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _secondsLeft > 0 
                            ? "Le restaurateur a 2 minutes pour accepter." 
                            : "Temps écoulé, nous contactons le restaurateur.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: _secondsLeft > 0 ? AppTheme.muted2 : AppTheme.gold,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                  const Spacer(),
                  // Bouton Suivi
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainWrapper(initialIndex: 3)),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.greenXl,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    child: const Text(
                      "Suivre ma commande",
                      style: TextStyle(color: AppTheme.bg, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bouton Accueil
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainWrapper(initialIndex: 0)),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Retour à l'accueil",
                      style: TextStyle(color: AppTheme.muted, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
