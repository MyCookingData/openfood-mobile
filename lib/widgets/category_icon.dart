import 'package:flutter/material.dart';
import '../core/theme.dart';

class CategoryIcon extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;

  const CategoryIcon({
    super.key,
    required this.label,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 9),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [AppTheme.green, AppTheme.greenL],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.transparent : AppTheme.border,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.green.withValues(alpha: 0.40),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 23),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.greenXl : AppTheme.muted2,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

