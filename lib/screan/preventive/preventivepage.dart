import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
// import 'package:geolocator/geolocator.dart';
import 'preventive.dart';
import '../form_aumenta_laporan.dart';

class PreventivePage extends StatefulWidget {
  const PreventivePage({super.key});

  @override
  State<PreventivePage> createState() => _PreventivePageState();
}

class _PreventivePageState extends State<PreventivePage> {
  final TextEditingController _reportController = TextEditingController();

  // DADUS ASSET KABEL
  final Map<String, List<Map<String, dynamic>>> _municipioCables = {
    "Dili": [
      {
        "id": "FO-DILI-01",
        "name": "Segmentu Comoro - Tibar",
        "distansia": "12.5 KM",
        "tipo": "Underground",
        "status": "Stable",
      },
      {
        "id": "FO-DILI-02",
        "name": "Segmentu Lecidere - Metinaro",
        "distansia": "25.0 KM",
        "tipo": "Aerial",
        "status": "Need Maintenance",
      },
    ],
    "Baucau": [
      {
        "id": "FO-BAU-01",
        "name": "Baucau Villa - Vemasse",
        "distansia": "18.2 KM",
        "tipo": "Aerial",
        "status": "Stable",
      },
    ],
    "Ermera": [
      {
        "id": "FO-BAU-01",
        "name": "Ermera - Hatulia",
        "distansia": "18.2 KM",
        "tipo": "Aerial",
        "status": "Stable",
      },
    ],
    "Bobonaro": [
      {
        "id": "FO-BAU-01",
        "name": "Bobonaro - Maliana",
        "distansia": "18.2 KM",
        "tipo": "Aerial",
        "status": "Stable",
      },
    ],
  };

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
      MaterialPageRoute(builder: (context) => StartPatroliPage()),
    );
  }

  // --- 3. DETAIL KABEL ---
  void _showCableDetail(Map<String, dynamic> kabel, String munisipio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(kabel['name'], textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow("ID Asset", kabel['id']),
            _buildInfoRow("Distánsia", kabel['distansia']),
            _buildInfoRow("Tipu", kabel['tipo']),
            _buildInfoRow("Status", kabel['status']),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
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
        backgroundColor: Colors.redAccent, // Kór matak FIXOM
        title: const Text(
          "Form Preventive",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () {},
          ),
          // MENU TITIK TIGA HODI LOKE LISTA TICKET
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'list') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PreventiveListPage(),
                  ),
                );
              } else if (value == 'lista Patroli') {
                // Mensajen temporáriu ba menu seluk
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StartPatroliPage(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'list',
                child: Text("Hare Lista Ticket"),
              ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _municipioCables.keys.length,
        itemBuilder: (context, index) {
          String mun = _municipioCables.keys.elementAt(index);
          return ListTile(
            leading: const Icon(Icons.location_city, color: Color(0xFFED1C24)),
            title: Text(
              mun,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Total Asset: ${_municipioCables[mun]!.length}"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCableList(mun),
          );
        },
      ),
    );
  }

  void _showCableList(String mun) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: _municipioCables[mun]!.length,
        itemBuilder: (context, i) {
          var kabel = _municipioCables[mun]![i];
          return ListTile(
            leading: const Icon(Icons.cable, color: Colors.blue),
            title: Text(kabel['name']),
            onTap: () => _showCableDetail(kabel, mun),
          );
        },
      ),
    );
  }
}
