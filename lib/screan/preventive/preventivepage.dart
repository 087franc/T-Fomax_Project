import 'dart:convert';
import 'package:T_Fomax/screan/corrective/corective.dart';
import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../../services/api_service.dart';
// import 'package:geolocator/geolocator.dart';
// import 'preventivelist.dart';
import 'patrol_map_page.dart';
import 'patrol_history_page.dart';

class PreventivePage extends StatefulWidget {
  const PreventivePage({super.key});

  @override
  State<PreventivePage> createState() => _PreventivePageState();
}

class _PreventivePageState extends State<PreventivePage> {
  final TextEditingController _reportController = TextEditingController();

  List<dynamic> _municipalities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMunicipalities();
  }

  Future<void> _fetchMunicipalities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService().get("/api/v1/municipalities");
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _municipalities = decoded['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load municipalities: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error fetching municipalities: $e";
        _isLoading = false;
      });
    }
  }

  // --- 1. FUNSAUN HODI RAI DADUS BA SQLITE ---
  Future<void> _savePatroliToDB(String cableID, String munisipio) async {
    if (_reportController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Favor prense kondisaun kabel!")),
      );
      return;
    }

    await DatabaseHelper.instance.insertPatroli({
      'munisipio': "$munisipio ($cableID)",
      'kondisaun': _reportController.text,
      'timestamp': DateTime.now().toString(),
      'is_synced': 0, // Seidauk haruka ba server
    });

    _reportController.clear();
    Navigator.pop(context); // Taka formuláriu

    // Hatudu Dialog Susesu
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 15),
            Text(
              "Relatóriu Rai Ona!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "Dadus rai seguru iha Database SQLite.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // --- 2. FORMULÁRIU PATROLI (INPUT) ---
  void _openPatrolForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PatrolMapPage()),
    );
  }

  // --- 3. DETAIL KABEL ---
  void _showCableDetail(Map<String, dynamic> kabel, String munisipio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          kabel['segment_name'] ?? 'Segmentu',
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow(
                "Kódigu Segmentu",
                kabel['segment_code']?.toString() ?? '-',
              ),
              _buildInfoRow("Oríjen", kabel['origin_point']?.toString() ?? '-'),
              _buildInfoRow(
                "Destinu",
                kabel['destination_point']?.toString() ?? '-',
              ),
              _buildInfoRow("Distánsia", "${kabel['distance_km'] ?? 0} KM"),
              _buildInfoRow("Total Core", "${kabel['total_core'] ?? 0}"),
              _buildInfoRow("Used Core", "${kabel['used_core'] ?? 0}"),
              _buildInfoRow(
                "Available Core",
                "${kabel['available_core'] ?? 0}",
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context); // Taka Detail
              _openPatrolForm(); // LOKE FORMULÁRIU PATROLI
            },
            child: const Text(
              "HAHU PATROLI",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- 4. TAMPILAN LISTA MUNISIPIU ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.redAccent,
        title: const Text(
          "Formulario Preventivu",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchMunicipalities,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'list') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CorrectivePage()),
                );
              } else if (value == 'history') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PatrolHistoryPage()),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'list',
                child: Text("Hare Lista Ticket"),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Text("Histórika Patroli"),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: _fetchMunicipalities,
                    child: const Text(
                      "Tenta Fali",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : _municipalities.isEmpty
          ? const Center(child: Text("La iha munisípiu."))
          : RefreshIndicator(
              onRefresh: _fetchMunicipalities,
              child: ListView.builder(
                itemCount: _municipalities.length,
                itemBuilder: (context, index) {
                  final mun = _municipalities[index];
                  final name = mun['name'] ?? '-';
                  final code = mun['code'] ?? '';
                  return ListTile(
                    leading: const Icon(
                      Icons.location_city,
                      color: Color(0xFFED1C24),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: code.isNotEmpty ? Text("Kódigu: $code") : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showCableList(mun),
                  );
                },
              ),
            ),
    );
  }

  void _showCableList(Map<String, dynamic> mun) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return _CableSegmentsList(
              municipalityId: mun['id'],
              municipalityName: mun['name'] ?? '-',
              scrollController: scrollController,
              onCableTap: (kabel) {
                Navigator.pop(context); // Close bottom sheet
                _showCableDetail(kabel, mun['name'] ?? '-');
              },
            );
          },
        );
      },
    );
  }
}

class _CableSegmentsList extends StatefulWidget {
  final int municipalityId;
  final String municipalityName;
  final ScrollController scrollController;
  final Function(Map<String, dynamic>) onCableTap;

  const _CableSegmentsList({
    required this.municipalityId,
    required this.municipalityName,
    required this.scrollController,
    required this.onCableTap,
  });

  @override
  State<_CableSegmentsList> createState() => _CableSegmentsListState();
}

class _CableSegmentsListState extends State<_CableSegmentsList> {
  List<dynamic> _segments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSegments();
  }

  Future<void> _fetchSegments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService().get(
        "/api/v1/cable-segments/municipality/${widget.municipalityId}",
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _segments = decoded['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load segments: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          height: 4,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Segmentu ba ${widget.municipalityName}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.redAccent),
                )
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        onPressed: _fetchSegments,
                        child: const Text(
                          "Tenta Fali",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : _segments.isEmpty
              ? const Center(child: Text("La iha segmentu ba munisípiu ne'e."))
              : ListView.builder(
                  controller: widget.scrollController,
                  itemCount: _segments.length,
                  itemBuilder: (context, i) {
                    final kabel = _segments[i];
                    return ListTile(
                      leading: const Icon(Icons.cable, color: Colors.blue),
                      title: Text(kabel['segment_name'] ?? 'Segmentu'),
                      subtitle: Text(
                        "Kódigu: ${kabel['segment_code'] ?? '-'} | Distánsia: ${kabel['distance_km'] ?? 0} KM",
                      ),
                      onTap: () => widget.onCableTap(kabel),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
