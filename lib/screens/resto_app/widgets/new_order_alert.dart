import 'dart:async';
import 'package:flutter/material.dart';

class NewOrderAlert extends StatefulWidget {
  final String orderNum;
  final String amount;
  final VoidCallback onDismiss;

  const NewOrderAlert({
    super.key,
    required this.orderNum,
    required this.amount,
    required this.onDismiss,
  });

  static void show(BuildContext context, {required String orderNum, required String amount}) {
    late OverlayEntry entry;
    
    void remove() {
      if (entry.mounted) entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          type: MaterialType.transparency,
          child: NewOrderAlert(
            orderNum: orderNum,
            amount: amount,
            onDismiss: remove,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry);
  }

  @override
  State<NewOrderAlert> createState() => _NewOrderAlertState();
}

class _NewOrderAlertState extends State<NewOrderAlert> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<double>(begin: -1.0, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();

    _timer = Timer(const Duration(seconds: 4), () {
      _dismiss();
    });
  }

  void _dismiss() {
    _timer.cancel();
    _ctrl.reverse().then((value) => widget.onDismiss());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return FractionalTranslation(
          translation: Offset(0.0, _slideAnim.value),
          child: child,
        );
      },
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF5820A), Color(0xFFD4680A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF5820A).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              const Text("🔔", style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Nouvelle commande !", style: TextStyle(fontFamily: 'Bricolage Grotesque', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    Text("Commande ${widget.orderNum} — ${widget.amount}", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _dismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text("Voir →", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
