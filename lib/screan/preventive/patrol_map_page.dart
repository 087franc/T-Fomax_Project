import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/background_service.dart';
import 'form_aumenta_laporan.dart';

class PatrolMapPage extends StatefulWidget {
  const PatrolMapPage({super.key});

  @override
  State<PatrolMapPage> createState() => _PatrolMapPageState();
}

class _PatrolMapPageState extends State<PatrolMapPage>
    with WidgetsBindingObserver {
  late MapController _mapController;
  bool _isPatrolling = false;
  GeoPoint? _currentPosition;

  DateTime? _startTime;
  StreamSubscription<Position>? _positionSubscription;
  final List<GeoPoint> _patrolPath = [];

  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  bool _needRouteUpdate = false;
  bool _isSatellite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _mapController = MapController.withUserPosition(
      trackUserLocation: const UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ),
    );

    // Listen to background service updates
    FlutterBackgroundService().on('updateLocation').listen((event) {
      if (event != null && mounted) {
        final double lat = event['latitude'];
        final double lng = event['longitude'];
        final geoPoint = GeoPoint(latitude: lat, longitude: lng);
        setState(() {
          _currentPosition = geoPoint;
        });

        if (_isPatrolling) {
          setState(() {
            if (_patrolPath.isEmpty ||
                _patrolPath.last.latitude != geoPoint.latitude ||
                _patrolPath.last.longitude != geoPoint.longitude) {
              _patrolPath.add(geoPoint);
              _addArrowMarker(geoPoint);
            }
          });
          _updateRouteOnMap();
        }
      }
    });

    _checkPermissions().then((_) {
      _getCurrentLocation();
      _startLocationUpdates();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _lifecycleState = state;
    });
    if (state == AppLifecycleState.resumed) {
      if (_needRouteUpdate) {
        _needRouteUpdate = false;
        _updateRouteOnMap();
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = GeoPoint(
            latitude: position.latitude,
            longitude: position.longitude,
          );
        });
      }
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  Future<void> _addArrowMarker(GeoPoint point) async {
    if (_lifecycleState != AppLifecycleState.resumed) return;
    try {
      await _mapController.addMarker(
        point,
        markerIcon: const MarkerIcon(
          icon: Icon(Icons.arrow_upward, color: Colors.orangeAccent, size: 36),
        ),
      );
    } catch (e) {
      debugPrint("Error adding arrow marker: $e");
    }
  }

  void _startLocationUpdates() {
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Changed to 10 meters!
          ),
        ).listen((Position position) async {
          if (!mounted) return;

          final geoPoint = GeoPoint(
            latitude: position.latitude,
            longitude: position.longitude,
          );

          setState(() {
            _currentPosition = geoPoint;
          });

          if (_isPatrolling) {
            final prefs = await SharedPreferences.getInstance();
            final double? lastLat = prefs.getDouble('last_latitude');
            final double? lastLng = prefs.getDouble('last_longitude');

            bool shouldUpdate = false;
            if (lastLat == null || lastLng == null) {
              shouldUpdate = true;
            } else {
              double distance = Geolocator.distanceBetween(
                lastLat,
                lastLng,
                position.latitude,
                position.longitude,
              );
              if (distance >= 10.0) {
                shouldUpdate = true;
              }
            }

            if (shouldUpdate) {
              final String timestamp = DateTime.now().toIso8601String();
              await prefs.setDouble('last_latitude', position.latitude);
              await prefs.setDouble('last_longitude', position.longitude);
              await prefs.setString('last_timestamp', timestamp);

              // Automatically send longitude, latitude, and timestamps to backend every 10 meters
              final String? sessionId = prefs.getString('session_id');
              if (sessionId != null) {
                try {
                  await ApiService().post("/api/v1/patrol/track", {
                    "session_id": sessionId,
                    "latitude": position.latitude,
                    "longitude": position.longitude,
                    "timestamp": timestamp,
                  });
                  debugPrint(
                    "Sent 10m update from foreground: lat=${position.latitude}, lng=${position.longitude}",
                  );
                } catch (e) {
                  debugPrint("Error sending foreground 10m update: $e");
                }
              }

              setState(() {
                if (_patrolPath.isEmpty ||
                    _patrolPath.last.latitude != geoPoint.latitude ||
                    _patrolPath.last.longitude != geoPoint.longitude) {
                  _patrolPath.add(geoPoint);
                  _addArrowMarker(geoPoint);
                }
              });
              _updateRouteOnMap();
            }
          }
        });
  }

  Future<void> _updateRouteOnMap() async {
    if (_patrolPath.length < 2) return;
    if (_lifecycleState != AppLifecycleState.resumed) {
      _needRouteUpdate = true;
      return;
    }
    try {
      await _mapController.clearAllRoads();
      await _mapController.drawRoadManually(
        _patrolPath,
        const RoadOption(
          roadColor: Colors.blueAccent,
          roadWidth: 15.0,
          zoomInto: false,
        ),
      );
    } catch (e) {
      debugPrint("Error drawing manual road: $e");
    }
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _togglePatrol() async {
    final service = FlutterBackgroundService();

    if (_isPatrolling) {
      // STOP PATROL - Confirmation Dialog First
      final bool? confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFED1C24),
                  size: 28,
                ),
                SizedBox(width: 10),
                Text(
                  "Finalize Patroli?",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              "Ita hakarak termina duni patroli ne'e?\n(Do you really want to finalize the patrol?)",
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Lae / No",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFED1C24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Sim / Yes",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      // Stop service
      service.invoke("stopService");
      setState(() {
        _isPatrolling = false;
      });

      // Show instruction to fill out the form
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Favor prense formuláriu ne'e kompletu! / Please fill out/press this form!",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blueAccent,
          duration: Duration(seconds: 5),
        ),
      );

      _navigateToForm();
    } else {
      // START PATROL
      try {
        await initializeService();
      } catch (e) {
        debugPrint("Failed to initialize background service: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal mulai patroli background: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      service.startService();
      setState(() {
        _isPatrolling = true;
        _startTime = DateTime.now();
        _patrolPath.clear();
      });
      if (_currentPosition != null) {
        setState(() {
          _patrolPath.add(_currentPosition!);
        });
      }
      try {
        await _mapController.clearAllRoads();
      } catch (e) {
        debugPrint("Error clearing roads: $e");
      }

      // Show informational toast/snackbar that Patrol started
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Patroli Hahu Ona! / Patrol Started!",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToForm() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const StartPatroliPage()),
    );
  }

  void _toggleMapType() async {
    setState(() {
      _isSatellite = !_isSatellite;
    });
    try {
      if (_isSatellite) {
        await _mapController.changeTileLayer(
          tileLayer: CustomTile(
            sourceName: "world_imagery",
            tileExtension: ".jpg",
            minZoomLevel: 2,
            maxZoomLevel: 19,
            urlsServers: [
              TileURLs(
                url:
                    "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/",
                subdomains: [],
              ),
            ],
            tileSize: 256,
          ),
        );
      } else {
        await _mapController.changeTileLayer(
          tileLayer: CustomTile(
            sourceName: "openstreetmap",
            tileExtension: ".png",
            minZoomLevel: 2,
            maxZoomLevel: 19,
            urlsServers: [
              TileURLs(url: "https://tile.openstreetmap.org/", subdomains: []),
            ],
            tileSize: 256,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error switching map tile layer: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Patroli Map (OSM)",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isSatellite ? Icons.map : Icons.satellite_alt,
              color: Colors.white,
            ),
            tooltip: _isSatellite
                ? "Muda ba Standard Map"
                : "Muda ba Satellite Map",
            onPressed: _toggleMapType,
          ),
        ],
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
                    color: Color(0xFFED1C24),
                    size: 72,
                  ),
                ),
                directionArrowMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.navigation,
                    color: Colors.blueAccent,
                    size: 72,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFED1C24), size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Muda ba oin hodi halo patroli. Map sei hatudu ita nia dalan.",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
