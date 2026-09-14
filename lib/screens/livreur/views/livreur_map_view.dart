import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme.dart';

class LivreurMapView extends StatefulWidget {
  const LivreurMapView({super.key});

  @override
  State<LivreurMapView> createState() => _LivreurMapViewState();
}

class _LivreurMapViewState extends State<LivreurMapView> {
  Position? _currentPosition;
  final MapController _mapController = MapController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosition();
  }

  Future<void> _fetchPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5)
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
      }
    } catch (e) {
      Position? position = await Geolocator.getLastKnownPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.greenXl))
          else if (_currentPosition == null)
            const Center(
              child: Text(
                "Impossible d'obtenir la position.\nVérifiez votre GPS.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted),
              ),
            )
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                initialZoom: 15.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png",
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.openfood.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0EA5E9),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Color(0xFF0EA5E9), blurRadius: 10, spreadRadius: 2),
                              ]
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          
          // Header Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border2),
              ),
              child: const Row(
                children: [
                  Icon(Icons.map_outlined, color: AppTheme.greenXl),
                  SizedBox(width: 12),
                  Text(
                    "Secteur d'Activité",
                    style: TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          
          // Bouton Recentrer
          Positioned(
            bottom: 120, // Au dessus de la Bottom Bar
            right: 20,
            child: FloatingActionButton(
              backgroundColor: AppTheme.surface2,
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController.move(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 
                    15.0
                  );
                }
              },
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
