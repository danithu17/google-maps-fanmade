import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  runApp(const SpatialNavApp());
}

class SpatialNavApp extends StatelessWidget {
  const SpatialNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spatial Navigation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  double _timeSliderValue = 0.5;
  bool _poiExpanded = false;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194), // SF
    zoom: 16.5,
    tilt: 60.0, // For 3D look
    bearing: 45.0,
  );

  final String _mapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#0d1117"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#4f5b66"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#000000"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#06080c"}]},
    {"featureType": "landscape.man_made", "elementType": "geometry.fill", "stylers": [{"color": "#0a0d12"}]},
    {"featureType": "landscape.man_made", "elementType": "geometry.stroke", "stylers": [{"color": "#2c3e50"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1a212d"}]},
    {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#233345"}]}
  ]
  ''';

  final Set<Polyline> _polylines = {
    Polyline(
      polylineId: const PolylineId('light_ribbon'),
      points: const [
        LatLng(37.7749, -122.4194),
        LatLng(37.7755, -122.4180),
        LatLng(37.7760, -122.4170),
        LatLng(37.7765, -122.4160),
      ],
      color: const Color(0xFF00E5FF),
      width: 8,
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    ),
  };

  final Set<Marker> _markers = {
    Marker(
      markerId: const MarkerId('poi_1'),
      position: const LatLng(37.7760, -122.4170),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      infoWindow: const InfoWindow(title: 'Cyber Hub'),
    ),
  };

  @override
  Widget build(BuildContext context) {
    // Time travel color overlay interpolation
    Color overlayColor = Color.lerp(
      const Color(0xFF0D1117).withOpacity(0.0), // Cyber Neon / Night
      const Color(0xFFE0F7FA).withOpacity(0.3), // Soft Pastel / Day
      _timeSliderValue,
    )!;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Layer
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            buildingsEnabled: true, // Show 3D wireframe-like buildings
            trafficEnabled: false,
            polylines: _polylines,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              controller.setMapStyle(_mapStyle);
              _controller.complete(controller);
            },
            onTap: (_) {
              if (_poiExpanded) setState(() => _poiExpanded = false);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
          ),

          // Time overlay effect
          IgnorePointer(
            child: Container(
              color: overlayColor,
            ),
          ),

          // Weather effect UI (Snow frosting on edge)
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF00E5FF).withOpacity(0.05),
                    const Color(0xFF0D1117).withOpacity(0.4),
                  ],
                  radius: 1.2,
                ),
              ),
            ),
          ),

          // 2. Search & Top Bar (Google Maps Style)
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildCategories(),
              ],
            ),
          ),

          // Map Controls (Right Side)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.22,
            child: _buildMapControls(),
          ),

          // 3. Time-Travel Slider (Vertical)
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height * 0.3,
            bottom: MediaQuery.of(context).size.height * 0.25,
            child: RotatedBox(
              quarterTurns: 3,
              child: _buildGlassContainer(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00E5FF),
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: const Color(0xFF00E5FF).withOpacity(0.2),
                    trackHeight: 4.0,
                  ),
                  child: Slider(
                    value: _timeSliderValue,
                    min: 0,
                    max: 1,
                    onChanged: (val) {
                      setState(() {
                        _timeSliderValue = val;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),

          // 4. Holographic POI Bubble (If expanded)
          if (_poiExpanded)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              left: 40,
              right: 80,
              child: _buildHolographicCard(),
            ),

          // Invisible trigger for POI (for demo)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.5,
            left: MediaQuery.of(context).size.width * 0.4,
            child: GestureDetector(
              onTap: () {
                setState(() => _poiExpanded = !_poiExpanded);
              },
              child: Container(
                width: 50,
                height: 50,
                color: Colors.transparent,
              ),
            ),
          ),

          // 5. Smart Dock
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: _buildSmartDock(),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(16.0), double borderRadius = 20.0}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2633).withOpacity(0.4),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: _buildGlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        borderRadius: 30,
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00E5FF), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolographicCard() {
    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nexus Tower',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Icon(LucideIcons.x, color: Colors.white54, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Distance: 1.2km • 5 min',
            style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          const Text(
            'High activity zone. Holographic overlay indicates active commercial levels.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartDock() {
    return _buildGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      borderRadius: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDockItem(LucideIcons.navigation, 'Nav', true),
          _buildDockItem(LucideIcons.zap, 'Charge', false),
          _buildDockItem(LucideIcons.coffee, 'Food', false),
          _buildDockItem(LucideIcons.search, 'Search', false),
          _buildDockItem(LucideIcons.settings, 'Settings', false),
        ],
      ),
    );
  }

  Widget _buildDockItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? const Color(0xFF00E5FF) : Colors.white54,
          size: 24,
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF00E5FF),
              shape: BoxShape.circle,
            ),
          )
      ],
    );
  }

  Widget _buildSearchBar() {
    return _buildGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 30,
      child: Row(
        children: [
          Icon(LucideIcons.search, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Search here',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          Icon(LucideIcons.mic, color: Colors.white70, size: 20),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2),
            child: Icon(LucideIcons.user, color: const Color(0xFF00E5FF), size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      showsHorizontalScrollIndicator: false,
      child: Row(
        children: [
          _buildCategoryChip(LucideIcons.home, 'Home'),
          const SizedBox(width: 8),
          _buildCategoryChip(LucideIcons.coffee, 'Coffee'),
          const SizedBox(width: 8),
          _buildCategoryChip(LucideIcons.fuel, 'Gas'),
          const SizedBox(width: 8),
          _buildCategoryChip(LucideIcons.shoppingCart, 'Groceries'),
          const SizedBox(width: 8),
          _buildCategoryChip(LucideIcons.utensils, 'Restaurants'),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(IconData icon, String label) {
    return _buildGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 20,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Column(
      children: [
        _buildGlassIconButton(LucideIcons.layers),
        const SizedBox(height: 12),
        _buildGlassIconButton(LucideIcons.navigation),
        const SizedBox(height: 12),
        _buildGlassIconButton(LucideIcons.compass),
      ],
    );
  }

  Widget _buildGlassIconButton(IconData icon) {
    return _buildGlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: 30, // Circular
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
