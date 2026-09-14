import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/location_provider.dart';
import '../screens/address_picker_screen.dart';

class AddressSelectorModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Poignée
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: AppTheme.border2, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const Text(
                "Vos adresses de livraison",
                style: TextStyle(color: AppTheme.cream, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              Consumer<LocationProvider>(
                builder: (context, loc, _) {
                  if (loc.addresses.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text("Aucune adresse enregistrée.", style: TextStyle(color: AppTheme.muted), textAlign: TextAlign.center),
                    );
                  }
                  
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: loc.addresses.length,
                    separatorBuilder: (_, __) => const Divider(color: AppTheme.surface3, height: 1),
                    itemBuilder: (context, index) {
                      final item = loc.addresses[index];
                      final isSelected = loc.selectedAddress?.id == item.id;
                      
                      return ListTile(
                        onTap: () {
                          loc.selectAddress(item.id);
                          Navigator.pop(context);
                        },
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? AppTheme.green.withValues(alpha: 0.15) : AppTheme.surface3,
                          child: Icon(Icons.location_on, color: isSelected ? AppTheme.greenXl : AppTheme.muted, size: 20),
                        ),
                        title: Text(item.label, style: const TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold)),
                        subtitle: Text(item.addressName, style: const TextStyle(color: AppTheme.muted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.greenXl) : null,
                      );
                    },
                  );
                }
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.cream,
                    side: BorderSide(color: AppTheme.border2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add, color: AppTheme.greenL),
                  label: const Text("Ajouter une nouvelle adresse"),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressPickerScreen()));
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
