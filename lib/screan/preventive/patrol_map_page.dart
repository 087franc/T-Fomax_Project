import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'form_aumenta_laporan.dart';

class PatrolMapPage extends StatefulWidget {
  const PatrolMapPage({super.key});

  @override
  State<PatrolMapPage> createState() => _PatrolMapPageState();
}

class _PatrolMapPageState extends State<PatrolMapPage> {
  late MapController _mapController;
  bool _isPatrolling = false;
  GeoPoint? _currentPosition;
  
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    
    _mapController = MapController.withUserPosition(
        trackUserLocation: const UserTrackingOption(
      enableTracking: true,
      unFollowUser: false,
    ));

    // Listen to background service updates
    FlutterBackgroundService().on('updateLocation').listen((event) {
      if (event != null && mounted) {
        final double lat = event['latitude'];
        final double lng = event['longitude'];
        setState(() {
          _currentPosition = GeoPoint(latitude: lat, longitude: lng);
        });
      }
    });
    
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check Notification Permission (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // 2. Check Location Service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      _showLocationDialog("GPS Off", "Please enable GPS.");
      return;
    }

    // 3. Check Location Permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  void _showLocationDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  void _togglePatrol() async {
    final service = FlutterBackgroundService();

    if (_isPatrolling) {
      // STOP PATROL
      service.invoke("stopService");
      setState(() {
        _isPatrolling = false;
      });
      _navigateToForm();
    } else {
      // START PATROL
      service.startService();
      setState(() {
        _isPatrolling = true;
        _startTime = DateTime.now();
      });
    }
  }

  void _navigateToForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StartPatroliPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patroli Map (OSM)", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          OSMFlutter(
            controller: _mapController,
            osmOption: OSMOption(
              userTrackingOption: const UserTrackingOption(
                enableTracking: true,
                unFollowUser: false,
              ),
              userLocationMarker: UserLocationMaker(
                personMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.location_history_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                directionArrowMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.double_arrow,
                    size: 48,
                  ),
                ),
              ),
              showZoomController: true,
              zoomOption: const ZoomOption(
                initZoom: 15,
                minZoomLevel: 3,
                maxZoomLevel: 19,
                stepZoom: 1.0,
              ),
            ),
          ),
          PositionRectangle(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _togglePatrol,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isPatrolling ? Colors.orange : Colors.redAccent,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            _isPatrolling ? "STOP PATROL" : "START PATROL",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class PositionRectangle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Muda ba oin hodi halo patroli. Map sei hatudu ita nia dalan.",
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
