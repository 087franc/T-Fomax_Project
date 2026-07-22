import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class PatrolHistoryPage extends StatefulWidget {
  const PatrolHistoryPage({super.key});

  @override
  State<PatrolHistoryPage> createState() => _PatrolHistoryPageState();
}

class _PatrolHistoryPageState extends State<PatrolHistoryPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _patrols = [];
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    _fetchPatrols();
  }

  Future<void> _fetchPatrols() async {
    setState(() {
      _isLoading = true;
      _errorMsg = "";
    });

    try {
      final response = await ApiService().get("/api/v1/patrols");
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        setState(() {
          _patrols = decoded.map((e) => e as Map<String, dynamic>).toList();
        });
      } else {
        // Fallback to mock data if API returns an error or is not implemented yet
        _loadMockData();
      }
    } catch (e) {
      debugPrint("Error fetching patrols, loading mock fallback: $e");
      _loadMockData();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadMockData() {
    _patrols = [
      {
        "id": 25,
        "vehicle": "car",
        "started_at": DateTime.now()
            .subtract(const Duration(hours: 3))
            .toIso8601String(),
        "stopped_at": DateTime.now()
            .subtract(const Duration(hours: 2, minutes: 30))
            .toIso8601String(),
        "distance_km": 4.8,
        "municipality": "Dili",
      },
      {
        "id": 24,
        "vehicle": "motorcycle",
        "started_at": DateTime.now()
            .subtract(const Duration(days: 1, hours: 2))
            .toIso8601String(),
        "stopped_at": DateTime.now()
            .subtract(const Duration(days: 1, hours: 1))
            .toIso8601String(),
        "distance_km": 12.4,
        "municipality": "Ermera",
      },
      {
        "id": 23,
        "vehicle": "foot",
        "started_at": DateTime.now()
            .subtract(const Duration(days: 2, hours: 4))
            .toIso8601String(),
        "stopped_at": DateTime.now()
            .subtract(const Duration(days: 2, hours: 3))
            .toIso8601String(),
        "distance_km": 2.1,
        "municipality": "Liquica",
      },
    ];
  }

  IconData _getVehicleIcon(String vehicle) {
    switch (vehicle.toLowerCase()) {
      case 'car':
        return Icons.directions_car_rounded;
      case 'motorcycle':
        return Icons.motorcycle_rounded;
      default:
        return Icons.directions_walk_rounded;
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return "-";
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  String _getDuration(String? start, String? end) {
    if (start == null || end == null) return "-";
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      final diff = e.difference(s);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (hours > 0) {
        return "$hours h $minutes m";
      }
      return "$minutes m";
    } catch (_) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFFED1C24),
        title: const Text(
          "Histórika Patroli / Patrol History",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPatrols),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFED1C24)),
            )
          : _patrols.isEmpty
          ? const Center(
              child: Text(
                "Seidauk iha dadus patroli.\nNo patrol data available.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _patrols.length,
              itemBuilder: (context, index) {
                final patrol = _patrols[index];
                final String vehicle = patrol['vehicle'] ?? 'car';
                final int id = patrol['id'] ?? 0;
                final double distance = (patrol['distance_km'] is num)
                    ? (patrol['distance_km'] as num).toDouble()
                    : 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PatrolHistoryMapPage(patrol: patrol),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFED1C24).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getVehicleIcon(vehicle),
                              color: const Color(0xFFED1C24),
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Patroli ID: #$id",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "${distance.toStringAsFixed(2)} KM",
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Munisipio: ${patrol['municipality'] ?? 'Dili'}",
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Hahu: ${_formatDateTime(patrol['started_at'])}",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "Termina: ${_formatDateTime(patrol['stopped_at'])}",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getDuration(
                                        patrol['started_at'],
                                        patrol['stopped_at'],
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class PatrolHistoryMapPage extends StatefulWidget {
  final Map<String, dynamic> patrol;
  const PatrolHistoryMapPage({super.key, required this.patrol});

  @override
  State<PatrolHistoryMapPage> createState() => _PatrolHistoryMapPageState();
}

class _PatrolHistoryMapPageState extends State<PatrolHistoryMapPage> {
  late MapController _mapController;
  List<GeoPoint> _allPoints = [];
  List<GeoPoint> _fiveMinPoints = [];
  bool _isLoading = true;
  double _calculatedDistance = 0.0;
  bool _mapReady = false;

  // Simulation states
  Timer? _simTimer;
  bool _isSimulating = false;
  int _simIndex = 0;
  GeoPoint? _simulatedPoint;

  @override
  void initState() {
    super.initState();
    _mapController = MapController.customLayer(
      initMapWithUserPosition: const UserTrackingOption(
        enableTracking: false,
        unFollowUser: true,
      ),
      customTile: CustomTile(
        sourceName: "openstreetmap",
        tileExtension: ".png",
        minZoomLevel: 2,
        maxZoomLevel: 19,
        urlsServers: [
          TileURLs(
            url: "https://basemaps.cartocdn.com/rastertiles/voyager/",
            subdomains: ["a", "b", "c", "d"],
          ),
        ],
        tileSize: 256,
      ),
    );

    _loadLocations();
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    final int patrolId = widget.patrol['id'] ?? 0;
    try {
      final response = await ApiService().get("/api/v1/patrols/$patrolId");
      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        
        List<dynamic> locs = [];
        if (decoded['locations'] != null) {
          locs = decoded['locations'];
        } else if (decoded['patrol_locations'] != null) {
          locs = decoded['patrol_locations'];
        } else if (decoded['data'] != null && decoded['data']['locations'] != null) {
          locs = decoded['data']['locations'];
        } else if (decoded['data'] != null && decoded['data']['patrol_locations'] != null) {
          locs = decoded['data']['patrol_locations'];
        }
        
        if (locs.isNotEmpty) {
          _processLocations(locs.map((e) => e as Map<String, dynamic>).toList());
          return;
        }
      }
      _loadMockRoute();
    } catch (e) {
      debugPrint("Error loading patrol locations: $e");
      _loadMockRoute();
    }
  }

  void _processLocations(List<Map<String, dynamic>> rawLocations) {
    if (rawLocations.isEmpty) return;

    List<GeoPoint> points = [];
    for (final loc in rawLocations) {
      final lat = (loc['latitude'] as num).toDouble();
      final lng = (loc['longitude'] as num).toDouble();
      points.add(GeoPoint(latitude: lat, longitude: lng));
    }

    // Sort locations by time if available
    rawLocations.sort((a, b) {
      final tA = DateTime.tryParse(a['recorded_at'] ?? '') ?? DateTime.now();
      final tB = DateTime.tryParse(b['recorded_at'] ?? '') ?? DateTime.now();
      return tA.compareTo(tB);
    });

    // Sample every 5 minutes
    List<GeoPoint> sampled = [];
    if (rawLocations.isNotEmpty) {
      final firstLoc = rawLocations.first;
      sampled.add(GeoPoint(
        latitude: (firstLoc['latitude'] as num).toDouble(),
        longitude: (firstLoc['longitude'] as num).toDouble(),
      ));

      DateTime lastTime = DateTime.tryParse(firstLoc['recorded_at'] ?? '') ?? DateTime.now();

      for (int i = 1; i < rawLocations.length; i++) {
        final loc = rawLocations[i];
        final currTime = DateTime.tryParse(loc['recorded_at'] ?? '') ?? DateTime.now();
        if (currTime.difference(lastTime).inMinutes >= 5) {
          sampled.add(GeoPoint(
            latitude: (loc['latitude'] as num).toDouble(),
            longitude: (loc['longitude'] as num).toDouble(),
          ));
          lastTime = currTime;
        }
      }

      // Add last location if not already in sampled
      final lastLoc = rawLocations.last;
      final lastGeo = GeoPoint(
        latitude: (lastLoc['latitude'] as num).toDouble(),
        longitude: (lastLoc['longitude'] as num).toDouble(),
      );
      if (sampled.isNotEmpty &&
          (sampled.last.latitude != lastGeo.latitude ||
              sampled.last.longitude != lastGeo.longitude)) {
        sampled.add(lastGeo);
      }
    }

    double dist = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      dist += Geolocator.distanceBetween(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }

    setState(() {
      _allPoints = points;
      _fiveMinPoints = sampled;
      _calculatedDistance = dist / 1000.0; // In km
      _isLoading = false;
    });

    if (_mapReady) {
      _drawRoute();
    }
  }

  void _loadMockRoute() {
    // Generate mock route points around Dili, Timor-Leste
    final double startLat = -8.5587;
    final double startLng = 125.5510;

    List<Map<String, dynamic>> mockLocs = [];
    final startTime = DateTime.parse(widget.patrol['started_at'] ?? DateTime.now().toIso8601String());

    // Generate 15 points, spaced by 2 minutes each (spanning 30 minutes total)
    for (int i = 0; i < 16; i++) {
      mockLocs.add({
        "latitude": startLat + (i * 0.0006),
        "longitude": startLng + (i * 0.0012) + (i % 2 == 0 ? 0.0002 : -0.0002),
        "recorded_at": startTime.add(Duration(minutes: i * 2)).toIso8601String(),
      });
    }

    _processLocations(mockLocs);
  }

  Future<void> _drawRoute() async {
    if (_allPoints.isEmpty) return;

    try {
      // Draw path road in solid RED
      await _mapController.drawRoadManually(
        _allPoints,
        const RoadOption(
          roadColor: Colors.red,
          roadWidth: 10.0,
          zoomInto: true,
        ),
      );

      // Add End Marker (Red Circle)
      await _mapController.addMarker(
        _allPoints.last,
        markerIcon: const MarkerIcon(
          icon: Icon(Icons.circle, color: Color(0xFF8B0000), size: 28),
        ),
      );

      // Add Vehicle Icon corresponding to vehicle type
      final String vehicle = (widget.patrol['vehicle'] ?? 'car').toString().toLowerCase();
      IconData vehicleIcon = Icons.directions_car_rounded;
      if (vehicle == 'motorcycle') {
        vehicleIcon = Icons.motorcycle_rounded;
      } else if (vehicle == 'foot') {
        vehicleIcon = Icons.directions_walk_rounded;
      }

      // Show vehicle icon at the start point or latest point
      await _mapController.addMarker(
        _allPoints.first,
        markerIcon: MarkerIcon(
          icon: Icon(vehicleIcon, color: const Color(0xFFED1C24), size: 36),
        ),
      );
    } catch (e) {
      debugPrint("Error drawing path/markers on map: $e");
    }
  }

  void _toggleSimulation() async {
    if (_allPoints.isEmpty) return;

    if (_isSimulating) {
      _simTimer?.cancel();
      setState(() {
        _isSimulating = false;
      });
    } else {
      setState(() {
        _isSimulating = true;
      });

      if (_simIndex == 0) {
        try {
          await _mapController.removeMarker(_allPoints.first);
          await _mapController.removeMarker(_allPoints.last);
        } catch (_) {}
      }

      _simTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) async {
        if (_simIndex >= _allPoints.length) {
          timer.cancel();
          setState(() {
            _isSimulating = false;
            _simIndex = 0;
          });
          _drawRoute();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Simulasaun remata! / Simulation completed!"),
                backgroundColor: Colors.green,
              ),
            );
          }
          return;
        }

        final nextPoint = _allPoints[_simIndex];

        try {
          if (_simulatedPoint != null) {
            await _mapController.removeMarker(_simulatedPoint!);
          }

          _simulatedPoint = nextPoint;
          final String vehicle = (widget.patrol['vehicle'] ?? 'car').toString().toLowerCase();
          IconData vehicleIcon = Icons.directions_car_rounded;
          if (vehicle == 'motorcycle') {
            vehicleIcon = Icons.motorcycle_rounded;
          } else if (vehicle == 'foot') {
            vehicleIcon = Icons.directions_walk_rounded;
          }

          await _mapController.addMarker(
            nextPoint,
            markerIcon: MarkerIcon(
              icon: Icon(vehicleIcon, color: const Color(0xFFED1C24), size: 36),
            ),
          );

          await _mapController.goToLocation(nextPoint);
        } catch (e) {
          debugPrint("Simulation step error: $e");
        }

        setState(() {
          _simIndex++;
        });
      });
    }
  }

  void _resetSimulation() async {
    _simTimer?.cancel();
    if (_simulatedPoint != null) {
      try {
        await _mapController.removeMarker(_simulatedPoint!);
      } catch (_) {}
    }
    setState(() {
      _isSimulating = false;
      _simIndex = 0;
      _simulatedPoint = null;
    });
    _drawRoute();
    if (_allPoints.isNotEmpty) {
      await _mapController.goToLocation(_allPoints.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String vehicle = (widget.patrol['vehicle'] ?? 'car').toString().toLowerCase();
    IconData vehicleIcon = Icons.directions_car_rounded;
    if (vehicle == 'motorcycle') {
      vehicleIcon = Icons.motorcycle_rounded;
    } else if (vehicle == 'foot') {
      vehicleIcon = Icons.directions_walk_rounded;
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFFED1C24),
        title: Text(
          "Detail Rota Patroli #${widget.patrol['id']}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFED1C24)))
              : OSMFlutter(
                  controller: _mapController,
                  onMapIsReady: (isReady) {
                    if (isReady) {
                      _mapReady = true;
                      if (_allPoints.isNotEmpty) {
                        _drawRoute();
                      }
                    }
                  },
                  osmOption: const OSMOption(
                    userTrackingOption: UserTrackingOption(
                      enableTracking: false,
                      unFollowUser: true,
                    ),
                    zoomOption: ZoomOption(
                      initZoom: 15,
                      minZoomLevel: 3,
                      maxZoomLevel: 19,
                      stepZoom: 1.0,
                    ),
                    staticPoints: [],
                  ),
                ),
          if (!_isLoading) ...[
            // Simulation Video Controller Overlay Buttons (floating above bottom card)
            Positioned(
              bottom: 180,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_simIndex > 0) ...[
                    FloatingActionButton.small(
                      heroTag: "resetSim",
                      backgroundColor: Colors.white,
                      onPressed: _resetSimulation,
                      child: const Icon(Icons.replay_rounded, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                  ],
                  FloatingActionButton(
                    heroTag: "playSim",
                    backgroundColor: _isSimulating ? const Color(0xFFED1C24) : Colors.green,
                    onPressed: _toggleSimulation,
                    child: Icon(
                      _isSimulating ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            // Statistics overlay card at the bottom
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFED1C24,
                                  ).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  vehicleIcon,
                                  color: const Color(0xFFED1C24),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicle.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Text(
                                    "Patrol Method",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.flag_rounded,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${_fiveMinPoints.length} Checkpoints",
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            Icons.route_rounded,
                            "${_calculatedDistance.toStringAsFixed(2)} KM",
                            "Total Distánsia",
                          ),
                          _buildStatColumn(
                            Icons.timer_outlined,
                            _getDuration(
                              widget.patrol['started_at'],
                              widget.patrol['stopped_at'],
                            ),
                            "Total Durasun",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey[700], size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ],
    );
  }

  String _getDuration(String? start, String? end) {
    if (start == null || end == null) return "-";
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      final diff = e.difference(s);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (hours > 0) {
        return "$hours h $minutes m";
      }
      return "$minutes m";
    } catch (_) {
      return "-";
    }
  }
}
