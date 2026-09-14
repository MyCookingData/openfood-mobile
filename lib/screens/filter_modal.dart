import 'package:flutter/material.dart';
import '../core/theme.dart';

class FilterModal extends StatefulWidget {
  const FilterModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterModal(),
    );
  }

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  double _distance = 5.0; // km
  RangeValues _priceRange = const RangeValues(10, 50);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 40),
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Filtres Avancés", style: AppTheme.titleStyle.copyWith(fontSize: 20)),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.muted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Distance
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Distance maximum", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                Text("${_distance.toInt()} km", style: const TextStyle(color: AppTheme.greenXl, fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.green,
              inactiveTrackColor: AppTheme.surface2,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: _distance,
              min: 1.0,
              max: 20.0,
              onChanged: (val) => setState(() => _distance = val),
            ),
          ),
          const SizedBox(height: 24),

          // Price range
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Fourchette de prix", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                Text("${_priceRange.start.toInt()}€ - ${_priceRange.end.toInt()}€", style: const TextStyle(color: AppTheme.greenXl, fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.green,
              inactiveTrackColor: AppTheme.surface2,
              thumbColor: Colors.white,
            ),
            child: RangeSlider(
              values: _priceRange,
              min: 5.0,
              max: 100.0,
              onChanged: (val) => setState(() => _priceRange = val),
            ),
          ),
          const SizedBox(height: 32),

          // Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Appliquer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
