import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
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
  final MapController _mapController = MapController();
  double _timeSliderValue = 0.5;
  bool _poiExpanded = false;
  int _activeDockIndex = 0;
  bool _isDrivingMode = false;
  LatLng _currentPosition = const LatLng(37.7749, -122.4194); // SF Default

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_currentPosition, 16.5);
  }

  static const LatLng _initialPosition = LatLng(37.7749, -122.4194); // SF

  final List<LatLng> _polylinePoints = const [
    LatLng(37.7749, -122.4194),
    LatLng(37.7755, -122.4180),
    LatLng(37.7760, -122.4170),
    LatLng(37.7765, -122.4160),
  ];

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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 16.5,
              onTap: (_, __) {
                if (_poiExpanded) setState(() => _poiExpanded = false);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.spatial_nav_app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _polylinePoints,
                    color: const Color(0xFF00E5FF),
                    strokeWidth: 8,
                    strokeJoin: StrokeJoin.round,
                    strokeCap: StrokeCap.round,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: const LatLng(37.7760, -122.4170),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFF00E5FF),
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Time overlay effect
          IgnorePointer(
            child: Container(
              color: overlayColor,
            ),
          ),

          // Removed Weather Effect per request

          // 2. Search & Top Bar (Google Maps Style)
          if (!_isDrivingMode)
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
          if (!_isDrivingMode)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height * 0.22,
              child: _buildMapControls(),
            ),

          // 3. Time-Travel Slider (Vertical)
          if (!_isDrivingMode)
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

          // 5. Smart Dock or Driving Dashboard
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: _isDrivingMode ? _buildDrivingDashboard() : _buildSmartDock(),
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
          _buildDockItem(LucideIcons.compass, 'Explore', 0),
          _buildDockItem(LucideIcons.navigation, 'Go', 1),
          _buildDockItem(LucideIcons.bookmark, 'Saved', 2),
          _buildDockItem(LucideIcons.plusCircle, 'Contribute', 3),
          _buildDockItem(LucideIcons.messageSquare, 'Updates', 4),
        ],
      ),
    );
  }

  Widget _buildDockItem(IconData icon, String label, int index) {
    bool isActive = _activeDockIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeDockIndex = index;
        });
      },
      child: Column(
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
      ),
    );
  }

  Widget _buildDrivingDashboard() {
    return _buildGlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nexus Tower', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('15 min (5.2 km)', style: TextStyle(fontSize: 16, color: Color(0xFF00E5FF), fontWeight: FontWeight.w600)),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.xCircle, color: Colors.white54, size: 28),
                onPressed: () {
                  setState(() {
                    _isDrivingMode = false;
                  });
                },
              )
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Action for Start Driving
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.navigation),
                SizedBox(width: 8),
                Text('Start Driving', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isDrivingMode = true;
          _poiExpanded = false;
        });
      },
      child: _buildGlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 30,
        child: Row(
          children: [
            const Icon(LucideIcons.search, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Search destination...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const Icon(LucideIcons.mic, color: Colors.white70, size: 20),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2),
              child: const Icon(LucideIcons.user, color: Color(0xFF00E5FF), size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
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
