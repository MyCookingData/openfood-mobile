import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class DashboardSidebar extends StatelessWidget {
  final String activePage;
  final ValueChanged<String> onPageChanged;
  final bool isCompact;

  const DashboardSidebar({
    super.key,
    required this.activePage,
    required this.onPageChanged,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCompact ? 60 : 230,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          // Logo Area
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 24,
              horizontal: isCompact ? 0 : 20,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: isCompact
                ? const Center(
                    child: Text("OF", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.greenL)),
                  )
                : const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        children: [
                          Text("Open", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.cream)),
                          Text("Food", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.greenL)),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text("Espace restaurateur", style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                    ],
                  ),
          ),
          
          // Nav Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 12, vertical: 14),
              children: [
                if (!isCompact) _buildSectionTitle("Principal"),
                _buildNavItem("dashboard", "📊", "Dashboard", badge: null),
                _buildNavItem("commandes", "📋", "Commandes", badge: "3"),
                
                const SizedBox(height: 10),
                if (!isCompact) _buildSectionTitle("Catalogue"),
                _buildNavItem("produits", "🛍️", "Produits", badge: null),
                _buildNavItem("categories", "🏷️", "Catégories", badge: null),
                
                const SizedBox(height: 10),
                if (!isCompact) _buildSectionTitle("Visibilité"),
                _buildNavItem("pub", "📣", "Régie pub", badge: null),
                
                const SizedBox(height: 10),
                if (!isCompact) _buildSectionTitle("Compte"),
                _buildNavItem("settings", "⚙️", "Paramètres", badge: null),
              ],
            ),
          ),
          
          // Bottom Resto info
          if (!isCompact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.green, Color(0xFF145C26)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text("OF", style: TextStyle(fontFamily: 'Bricolage Grotesque', fontSize: 14, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Open Food", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text("Plan PRO · Case-Pilote", style: TextStyle(color: AppTheme.greenXl, fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Text("›", style: TextStyle(color: AppTheme.muted, fontSize: 18)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 10, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: AppTheme.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildNavItem(String id, String icon, String label, {String? badge}) {
    bool isActive = activePage == id;
    
    return GestureDetector(
      onTap: () => onPageChanged(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 0 : 12, vertical: isCompact ? 12 : 9),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E8B3A).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Text(
                icon,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: isActive ? AppTheme.greenXl : AppTheme.muted2),
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppTheme.greenXl : AppTheme.muted2,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (badge != null) const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.redL,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
