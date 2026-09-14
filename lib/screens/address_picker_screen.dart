import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../core/theme.dart';

class AddressPickerScreen extends StatefulWidget {
  const AddressPickerScreen({super.key});

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  late final MapController _mapController;
  LatLng _center = const LatLng(14.6415, -61.0242); // Centre par défaut sur Fort-de-France
  String _currentAddress = "Déplacez la carte pour choisir...";
  bool _isDragging = false;
  bool _isLoadingAddress = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Initialise le centre par rapport à la dernière position enregistrée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = Provider.of<LocationProvider>(context, listen: false);
      if (loc.selectedAddress != null) {
        _center = LatLng(loc.selectedAddress!.latitude, loc.selectedAddress!.longitude);
      }
      _mapController.move(_center, 15.0);
      _updateAddress(_center);
    });
  }

  Future<void> _updateAddress(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String street = place.street ?? '';
        String locality = place.locality ?? '';
        String newAd = '';
        if (street.isNotEmpty && street != "Unnamed Road") {
           newAd = "$street, $locality";
        } else {
           newAd = locality;
        }
        setState(() {
          _currentAddress = newAd.trim().isEmpty ? "Adresse inconnue" : newAd;
        });
      }
    } catch (e) {
      setState(() => _currentAddress = "📍 Position sélectionnée");
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    
    FocusScope.of(context).unfocus(); // Cacher le clavier
    setState(() => _isLoadingAddress = true);
    
    try {
      // 1. Chercher les coordonnées depuis le texte
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final newPosition = LatLng(loc.latitude, loc.longitude);
        
        // 2. Déplacer la carte
        _mapController.move(newPosition, 16.0);
        setState(() {
           _center = newPosition;
        });
        
        // 3. Mettre à jour le texte en bas
        await _updateAddress(newPosition);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Adresse introuvable, essayez d'être plus précis."), backgroundColor: AppTheme.redL),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  void _confirmLocation() {
    String label = "Domicile";
    showDialog(context: context, barrierDismissible: false, builder: (ctx) {
      return AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Nommer cette adresse", style: TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold)),
        content: TextField(
          style: const TextStyle(color: AppTheme.cream),
          decoration: InputDecoration(
            hintText: "Ex : Domicile, Bureau, Amis...",
            hintStyle: const TextStyle(color: AppTheme.muted),
            filled: true,
            fillColor: AppTheme.surface3,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
          onChanged: (v) => label = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler", style: TextStyle(color: AppTheme.muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green),
            onPressed: () {
              if (label.trim().isEmpty) label = "Autre";
              final loc = Provider.of<LocationProvider>(context, listen: false);
              loc.addAddress(label: label, addressName: _currentAddress, lat: _center.latitude, lng: _center.longitude);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label ajouté: $_currentAddress", style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.greenXl));
            },
            child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
          )
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text("Où livrer ?", style: TextStyle(color: AppTheme.cream, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.cream), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          // CARTE
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15.0,
              onPositionChanged: (MapCamera camera, bool hasGesture) {
                if (hasGesture) {
                  _center = camera.center;
                }
              },
              onPointerDown: (event, point) => setState(() => _isDragging = true),
              onPointerUp: (event, point) {
                setState(() => _isDragging = false);
                _updateAddress(_center);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kaydada.openfood',
              ),
            ],
          ),

          // ÉPINGLE CENTRALE ROUGE
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(bottom: _isDragging ? 40 : 20), // Saute quand on drag
              child: Icon(Icons.location_on, size: _isDragging ? 55 : 45, color: AppTheme.redL),
            ),
          ),

          // BARRE DE RECHERCHE FLOTTANTE EN HAUT
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
                ]
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.cream),
                textInputAction: TextInputAction.search,
                onSubmitted: _searchAddress,
                decoration: InputDecoration(
                  hintText: "Saisissez une adresse...",
                  hintStyle: const TextStyle(color: AppTheme.muted),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.muted),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.muted),
                    onPressed: () {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // CARTE FLOTTANTE EN BAS (Adresse + Bouton)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10)),
                ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: _isLoadingAddress 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppTheme.greenXl, strokeWidth: 2))
                          : const Icon(Icons.location_on, color: AppTheme.greenXl, size: 20),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Livrer à l'adresse suivante :", style: TextStyle(color: AppTheme.muted, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(_currentAddress, style: const TextStyle(color: AppTheme.cream, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isLoadingAddress ? null : _confirmLocation,
                      child: const Text("Confirmer ma position", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
